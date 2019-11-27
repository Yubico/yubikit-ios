// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <CoreNFC/CoreNFC.h>

#import "YubiKitDeviceCapabilities.h"
#import "YubiKitExternalLocalization.h"

#import "YKFNFCConnectionController.h"
#import "YKFNFCSession.h"
#import "YKFBlockMacros.h"
#import "YKFLogger.h"
#import "YKFAssert.h"

#import "YKFNFCOTPService+Private.h"
#import "YKFKeyU2FService+Private.h"
#import "YKFKeyFIDO2Service+Private.h"
#import "YKFKeyOATHService+Private.h"
#import "YKFKeyRawCommandService+Private.h"
#import "YKFNFCTagDescription+Private.h"

@interface YKFNFCSession()<NFCTagReaderSessionDelegate>

@property (nonatomic, readwrite) YKFNFCISO7816SessionState iso7816SessionState;
@property (nonatomic, readwrite) NSError *iso7816SessionError;

@property (nonatomic, readwrite) YKFNFCTagDescription *tagDescription API_AVAILABLE(ios(13.0));
@property (nonatomic, readwrite) YKFNFCOTPService *otpService API_AVAILABLE(ios(11.0));
@property (nonatomic, readwrite) YKFKeyU2FService *u2fService API_AVAILABLE(ios(13.0));
@property (nonatomic, readwrite) YKFKeyFIDO2Service *fido2Service API_AVAILABLE(ios(13.0));
@property (nonatomic, readwrite) YKFKeyOATHService *oathService API_AVAILABLE(ios(13.0));
@property (nonatomic, readwrite) YKFKeyRawCommandService *rawCommandService API_AVAILABLE(ios(13.0));

@property (nonatomic) id<YKFKeyConnectionControllerProtocol> connectionController;

@property (nonatomic) NSOperationQueue *communicationQueue;
@property (nonatomic) dispatch_queue_t sharedDispatchQueue;

@property (nonatomic) NFCTagReaderSession *nfcTagReaderSession API_AVAILABLE(ios(13.0));

@property (nonatomic) NSTimer *iso7816NfcTagAvailabilityTimer;

@end

@implementation YKFNFCSession

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 11, *)) {
            // Init with defaults
            self.otpService = [[YKFNFCOTPService alloc] initWithTokenParser:nil session:nil];
        }
        [self setupCommunicationQueue];
    }
    return self;
}

- (void)dealloc {
    if (@available(iOS 13.0, *)) {
        [self unobserveIso7816TagAvailability];
    }
}

#pragma mark - Session lifecycle

- (void)startIso7816Session API_AVAILABLE(ios(13.0)) {
    YKFAssertReturn(YubiKitDeviceCapabilities.supportsISO7816NFCTags, @"Cannot start the NFC session on an unsupported device.");
    
    if (self.nfcTagReaderSession && self.nfcTagReaderSession.isReady) {
        YKFLogInfo(@"NFC session already started. Ignoring start request.");
        return;
    }
    
    NFCTagReaderSession *nfcTagReaderSession = [[NFCTagReaderSession alloc] initWithPollingOption:NFCPollingISO14443 delegate:self queue:nil];
    nfcTagReaderSession.alertMessage = YubiKitExternalLocalization.nfcScanAlertMessage;
    [nfcTagReaderSession beginSession];
}

- (void)stopIso7816Session API_AVAILABLE(ios(13.0)) {
    if (!self.nfcTagReaderSession) {
        YKFLogInfo(@"NFC session already stopped. Ignoring stop request.");
        return;
    }
    
    [self setAlertMessage:YubiKitExternalLocalization.nfcScanSuccessAlertMessage];
    [self updateServicesForSession:self.nfcTagReaderSession tag:nil state:YKFNFCISO7816SessionStateClosed];
}

- (void)cancelCommands API_AVAILABLE(ios(13.0)) {
    [self.connectionController cancelAllCommands];
}

#pragma mark - Alert customization

- (void)setAlertMessage:(NSString*) alertMessage API_AVAILABLE(ios(13.0))  {
    if (!self.nfcTagReaderSession) {
        YKFLogInfo(@"NFC session is not started.");
        return;
    }

    self.nfcTagReaderSession.alertMessage = alertMessage;
}


#pragma mark - Shared communication queue

- (void)setupCommunicationQueue {
    // Create a sequential queue because the YubiKey accepts sequential commands.
    self.communicationQueue = [[NSOperationQueue alloc] init];
    self.communicationQueue.maxConcurrentOperationCount = 1;
    
    dispatch_queue_attr_t dispatchQueueAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1);
    self.sharedDispatchQueue = dispatch_queue_create("com.yubico.YKCOMNFC", dispatchQueueAttributes);
    
    self.communicationQueue.underlyingQueue = self.sharedDispatchQueue;
}

#pragma mark - NFCTagReaderSessionDelegate

- (void)tagReaderSession:(NFCTagReaderSession *)session didInvalidateWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
    YKFLogNSError(error);
    [self updateServicesForSession:session error: error];
}

- (void)tagReaderSessionDidBecomeActive:(NFCTagReaderSession *)session API_AVAILABLE(ios(13.0)) {
    YKFLogInfo(@"NFC session did become active.");
    self.nfcTagReaderSession = session;
    [self updateServicesForSession:session tag:nil state:YKFNFCISO7816SessionStatePooling];
}

- (void)tagReaderSession:(NFCTagReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags API_AVAILABLE(ios(13.0)) {
    YKFLogInfo(@"NFC session did detect tags.");
    
    if (!tags.count) {
        YKFLogInfo(@"No tags found");
        [self.nfcTagReaderSession restartPolling];
        return;
    }
    id<NFCISO7816Tag> activeTag = nil;
    for (id<NFCTag> tag in tags) {
        if (tag.type == NFCTagTypeISO7816Compatible) {
            activeTag = [tag asNFCISO7816Tag];
            break;
        }
    }
    if (!activeTag) {
        YKFLogInfo(@"No ISO-7816 compatible tags found");
        [self.nfcTagReaderSession restartPolling];
        return;
    }
    
    ykf_weak_self();
    [self.nfcTagReaderSession connectToTag:activeTag completionHandler:^(NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            // don't close session if tag was invalid or connection to tag had an error
            // this session can be reused for another tag
            YKFLogNSError(error);
            [self.nfcTagReaderSession restartPolling];
            return;
        }
        
        YKFLogInfo(@"NFC session did connect to tag.");
        [strongSelf updateServicesForSession:session tag:activeTag state:YKFNFCISO7816SessionStateOpen];
    }];
}

#pragma mark - Helpers
- (void)updateServicesForSession:(NFCTagReaderSession *)session error:(NSError *)error API_AVAILABLE(ios(13.0)) {
    // if the session was already closed ignore the error
    if (self.iso7816SessionState == YKFNFCISO7816SessionStateClosed) {
        return;
    }
    
    // if error was received for another session that is not currently active we can ignore it
    if (self.nfcTagReaderSession != session) {
        return;
    }

    self.iso7816SessionError = error;
    [self.nfcTagReaderSession invalidateSessionWithErrorMessage:error.localizedDescription];
    [self updateServicesForSession:session tag:nil state:YKFNFCISO7816SessionStateClosed];
}

- (void)updateServicesForSession:(NFCTagReaderSession *)session tag:(id<NFCISO7816Tag>)tag state:(YKFNFCISO7816SessionState)state API_AVAILABLE(ios(13.0)) {
    if (self.iso7816SessionState == state) {
        return;
    }
    if (self.nfcTagReaderSession != session) {
        return;
    }
    
    switch (state) {
        case YKFNFCISO7816SessionStateClosed:
            self.u2fService = nil;
            self.fido2Service = nil;
            self.rawCommandService = nil;
            self.oathService = nil;
            self.connectionController = nil;
            self.tagDescription = nil;

            [self unobserveIso7816TagAvailability];

            // invalidating session closes nfc reading sheet
            [self.nfcTagReaderSession invalidateSession];
            self.nfcTagReaderSession = nil;
            break;
        
        case YKFNFCISO7816SessionStatePooling:
            self.iso7816SessionError = nil;

            self.u2fService = nil;
            self.fido2Service = nil;
            self.rawCommandService = nil;
            self.oathService = nil;
            self.connectionController = nil;
            self.tagDescription = nil;
            [self unobserveIso7816TagAvailability];
            
            [self.nfcTagReaderSession restartPolling];
            break;
            
        case YKFNFCISO7816SessionStateOpen:
            [self observeIso7816TagAvailability];
            
            self.connectionController = [[YKFNFCConnectionController alloc] initWithNFCTag:tag operationQueue:self.communicationQueue];
            self.u2fService = [[YKFKeyU2FService alloc] initWithConnectionController:self.connectionController];
            self.fido2Service = [[YKFKeyFIDO2Service alloc] initWithConnectionController:self.connectionController];
            self.oathService = [[YKFKeyOATHService alloc] initWithConnectionController:self.connectionController];
            self.rawCommandService = [[YKFKeyRawCommandService alloc] initWithConnectionController:self.connectionController];
            self.tagDescription = [[YKFNFCTagDescription alloc] initWithTag: tag];
            break;
    }
    
    self.iso7816SessionState = state;
}

#pragma mark - Tag availability observation

- (void)observeIso7816TagAvailability API_AVAILABLE(ios(13.0)) {
    // Note: A timer is used because the "available" property is not KVO observable and the tag has no delegate.
    // This solution is suboptimal but in line with some examples from Apple using a dispatch queue.
    ykf_weak_self();
    self.iso7816NfcTagAvailabilityTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:0.5 repeats:YES block:^(NSTimer *timer) {
        ykf_safe_strong_self();
        BOOL available = strongSelf.nfcTagReaderSession.connectedTag.available;
        if (available) {
            YKFLogVerbose(@"NFC tag is available.");
        } else {
            YKFLogInfo(@"NFC tag is no longer available.");
            // moving from state of open back to polling/waiting for new tag
            [strongSelf updateServicesForSession:strongSelf.nfcTagReaderSession tag:nil state:YKFNFCISO7816SessionStatePooling];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.iso7816NfcTagAvailabilityTimer forMode:NSDefaultRunLoopMode];
}

- (void)unobserveIso7816TagAvailability API_AVAILABLE(ios(13.0)) {
    // Note: A timer is used because the "available" property is not KVO observable and the tag has no delegate.
    // This solution is suboptimal but in line with some examples from Apple using a dispatch queue.
    [self.iso7816NfcTagAvailabilityTimer invalidate];
    self.iso7816NfcTagAvailabilityTimer = nil;
}

@end
