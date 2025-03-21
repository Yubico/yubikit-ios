// Copyright 2018-2022 Yubico AB
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

#import <Foundation/Foundation.h>
#import "YKFSmartCardConnection+Private.h"
#import <CryptoTokenKit/CryptoTokenKit.h>
#import "YKFConnectionControllerProtocol.h"
#import "YKFSmartCardConnectionController.h"
#import "YKFOATHSession+Private.h"
#import "YKFManagementSession+Private.h"
#import "YKFFIDO2Session+Private.h"
#import "YKFPIVSession+Private.h"
#import "YKFU2FSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSCPSecurityDomainSession+Private.h"
#import "YKFChallengeResponseSession+Private.h"

NSString* const YKFSmartCardConnectionErrorDomain = @"com.yubico.smart-card-connection";

@interface YKFSmartCardConnection()

@property (nonatomic) YKFSmartCardConnectionController *connectionController;
@property (nonatomic) bool isActive;
@property (nonatomic, readwrite) id<YKFSessionProtocol> currentSession;

@end

@implementation YKFSmartCardConnection

- (nullable instancetype)initWithDelegate:(nonnull id<YKFSmartCardConnectionDelegate>)delegate {
    self = [super init];
    if (self) {
        self.isActive = NO;
        self.delegate = delegate;
    }
    return self;
}

- (YKFSmartCardConnectionState)state {
    return self.connectionController != nil ? YKFSmartCardConnectionStateOpen : YKFSmartCardConnectionStateClosed;
}

- (void)updateConnections API_AVAILABLE(ios(16.0)) {
    // creating the smart card has to be done on the main thread and after a slight delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        TKSmartCardSlotManager *manager = [TKSmartCardSlotManager defaultManager];
        NSString *slotName = manager.slotNames.firstObject; // iPads only have one usb-c port
        if (slotName != nil) {
            TKSmartCardSlot *slot = [manager slotNamed:slotName];
            TKSmartCard *smartCard = [slot makeSmartCard];
            if (smartCard == nil) {
                return;
            }
            [YKFSmartCardConnectionController smartCardControllerWithSmartCard:smartCard completion:^(YKFSmartCardConnectionController * controller, NSError * error) {
                if (controller != nil) {
                    self.connectionController = controller;
                    [self.delegate didConnectSmartCard:self];
                } else {
                    [self.delegate didFailConnectingSmartCard:error];
                }
            }];
        } else if (self.connectionController != nil) {
            self.connectionController = nil;
            [self.delegate didDisconnectSmartCard:self error:nil];
            [self.currentSession clearSessionState];
            self.currentSession = nil;
        }
    });
}

- (void)dealloc {
    if (@available(iOS 16.0, *)) {
        [self stop];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context API_AVAILABLE(ios(16.0)) {
    [self updateConnections];
}

- (void)start {
    if (self.isActive == YES) {
        return;
    }
    
    self.isActive = YES;
    [self updateConnections];
    [[TKSmartCardSlotManager defaultManager] addObserver:self forKeyPath:@"slotNames" options:0 context:nil];
}

- (void)stop {
    if (self.isActive == NO) {
        return;
    }
    
    self.isActive = NO;
    [[TKSmartCardSlotManager defaultManager] removeObserver:self forKeyPath:@"slotNames"];
    [self.connectionController endSession];
    self.connectionController = nil;
    [self.currentSession clearSessionState];
    self.currentSession = nil;
}

- (YKFSmartCardInterface *)smartCardInterface {
    if (!self.connectionController) {
        return nil;
    }
    return [[YKFSmartCardInterface alloc] initWithConnectionController:self.connectionController];
}

- (void)challengeResponseSession:(YKFChallengeResponseSessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    completion(nil, [[NSError alloc] initWithDomain:YKFSmartCardConnectionErrorDomain
                                               code:YKFSmartCardConnectionErrorCodeNotSupported
                                           userInfo:@{NSLocalizedDescriptionKey: @"Challenge response session not supported by YKFSmartCardConnection."}]);
}

- (void)fido2Session:(YKFFIDO2SessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    completion(nil, [[NSError alloc] initWithDomain:YKFSmartCardConnectionErrorDomain
                                               code:YKFSmartCardConnectionErrorCodeNotSupported
                                           userInfo:@{NSLocalizedDescriptionKey: @"FIDO2 session not supported by YKFSmartCardConnection."}]);
}

- (void)managementSession:(YKFManagementSessionCompletion _Nonnull)completion {
    [self.currentSession clearSessionState];
    [YKFManagementSession sessionWithConnectionController:self.connectionController
                                               completion:^(YKFManagementSession *_Nullable session, NSError * _Nullable error) {
        self.currentSession = session;
        completion(session, error);
    }];
}

- (void)oathSession:(YKFOATHSessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    [YKFOATHSession sessionWithConnectionController:self.connectionController
                                         completion:^(YKFOATHSession *_Nullable session, NSError * _Nullable error) {
        self.currentSession = session;
        completion(session, error);
    }];
}

- (void)oathSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFOATHSessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    [YKFOATHSession sessionWithConnectionController:self.connectionController
                                       scpKeyParams:scpKeyParams
                                         completion:^(YKFOATHSession *_Nullable session, NSError * _Nullable error) {
        self.currentSession = session;
        completion(session, error);
    }];
}

- (void)pivSession:(YKFPIVSessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    [YKFPIVSession sessionWithConnectionController:self.connectionController
                                        completion:^(YKFPIVSession *_Nullable session, NSError * _Nullable error) {
        self.currentSession = session;
        completion(session, error);
    }];
}

- (void)u2fSession:(YKFU2FSessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    completion(nil, [[NSError alloc] initWithDomain:YKFSmartCardConnectionErrorDomain
                                               code:YKFSmartCardConnectionErrorCodeNotSupported
                                           userInfo:@{NSLocalizedDescriptionKey: @"U2F session not supported by YKFSmartCardConnection."}]);
}

- (void)securityDomainSession:(YKFSecurityDomainSessionCompletion _Nonnull)completion {
    [self.currentSession clearSessionState];
    [YKFSecurityDomainSession sessionWithConnectionController:self.connectionController
                                        completion:^(YKFSecurityDomainSession *_Nullable session, NSError * _Nullable error) {
        self.currentSession = session;
        completion(session, error);
    }];
}

- (void)executeRawCommand:(NSData *)data completion:(YKFRawComandCompletion)completion {
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithData:data];
    [self.connectionController execute:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error, NSTimeInterval executionTime) {
        completion(data, error);
    }];
}

- (void)executeRawCommand:(NSData *)data timeout:(NSTimeInterval)timeout completion:(YKFRawComandCompletion)completion {
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithData:data];
    [self.connectionController execute:apdu
                               timeout:timeout
                            completion:^(NSData * _Nullable response, NSError * _Nullable  error, NSTimeInterval executionTime) {
        completion(response, error);
    }];
}

@end
