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
#import "YKFChallengeResponseSession+Private.h"

@interface YKFSmartCardConnection()

@property (nonatomic, readwrite) TKSmartCard *smartCard;
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
    // creating the smart card has to be done on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        TKSmartCardSlotManager *manager = [TKSmartCardSlotManager defaultManager];
        NSString *slotName = manager.slotNames.firstObject;
        if (slotName != nil) {
            TKSmartCardSlot *slot = [manager slotNamed:slotName];
            NSLog(@"slot.maxInputLength: %li", (long)slot.maxInputLength);
            NSLog(@"slot.maxOutputLength: %li", (long)slot.maxOutputLength);

            self.smartCard = [slot makeSmartCard];
            [YKFSmartCardConnectionController smartCardControllerWithSmartCard:self.smartCard completion:^(YKFSmartCardConnectionController * controller, NSError * error) {
                if (controller != nil) {
                    self.connectionController = controller;
                    [self.delegate didConnectSmartCard:self];
                    NSLog(@"SmartCard connected %@ and session started", self.smartCard);
                }
            }];
        } else {
            NSLog(@"Smart card disconnected");
            [self.delegate didDisconnectSmartCard:self error:nil];
            self.connectionController = nil;
            self.smartCard = nil;
        }
    });
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
    self.isActive = NO;
    [[TKSmartCardSlotManager defaultManager] removeObserver:self forKeyPath:@"slotNames"];
    [self.connectionController endSession];
    self.connectionController = nil;
    [self.currentSession clearSessionState];
    self.currentSession = nil;
    NSLog(@"SmartCard session ended");

}

- (YKFSmartCardInterface *)smartCardInterface {
    if (!self.connectionController) {
        return nil;
    }
    return [[YKFSmartCardInterface alloc] initWithConnectionController:self.connectionController];
}

- (void)challengeResponseSession:(YKFChallengeResponseSessionCompletionBlock _Nonnull)completion { 
    [YKFChallengeResponseSession sessionWithConnectionController:self.connectionController
                                                      completion:^(YKFChallengeResponseSession *_Nullable session, NSError * _Nullable error) {
        completion(session, error);
    }];
}

- (void)fido2Session:(YKFFIDO2SessionCompletionBlock _Nonnull)completion {
    [self.currentSession clearSessionState];
    [YKFFIDO2Session sessionWithConnectionController:self.connectionController
                                          completion:^(YKFFIDO2Session *_Nullable session, NSError * _Nullable error) {
        self.currentSession = session;
        completion(session, error);
    }];
}

- (void)managementSession:(YKFManagementSessionCompletion _Nonnull)completion { 
    [YKFManagementSession sessionWithConnectionController:self.connectionController
                                               completion:^(YKFManagementSession *_Nullable session, NSError * _Nullable error) {
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

- (void)pivSession:(YKFPIVSessionCompletionBlock _Nonnull)completion { 
    [YKFPIVSession sessionWithConnectionController:self.connectionController
                                        completion:^(YKFPIVSession *_Nullable session, NSError * _Nullable error) {
        completion(session, error);
    }];
}

- (void)u2fSession:(YKFU2FSessionCompletionBlock _Nonnull)completion { 
    [YKFU2FSession sessionWithConnectionController:self.connectionController
                                        completion:^(YKFU2FSession *_Nullable session, NSError * _Nullable error) {
        completion(session, error);
    }];
}

@end
