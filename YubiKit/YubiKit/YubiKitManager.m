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

#import <ExternalAccessory/ExternalAccessory.h>

#import "YubiKitManager.h"
#import "YKFAccessoryConnectionConfiguration.h"

#import "YKFNFCOTPSession+Private.h"
#import "YKFAccessoryConnection+Private.h"
#import "YKFNFCConnection+Private.h"

@interface YubiKitManager()<YKFAccessoryConnectionDelegate, YKFNFCConnectionDelegate>

@property (nonatomic, readwrite) YKFNFCConnection *nfcSession NS_AVAILABLE_IOS(11.0);
@property (nonatomic, readwrite) YKFAccessoryConnection *accessorySession;
@property (nonatomic, readwrite) YKFNFCOTPSession *otpSession NS_AVAILABLE_IOS(11.0);

@end

@implementation YubiKitManager

@synthesize delegate;

static YubiKitManager *sharedInstance;

+ (YubiKitManager *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[YubiKitManager alloc] initOnce];
    });
    return sharedInstance;
}

- (instancetype)initOnce {
    self = [super init];
    if (self) {
        if (@available(iOS 11, *)) {
            YKFNFCConnection *nfcConnection = [[YKFNFCConnection alloc] init];
            nfcConnection.delegate = self;
            self.nfcSession = nfcConnection;
        }
       
        YKFAccessoryConnectionConfiguration *configuration = [[YKFAccessoryConnectionConfiguration alloc] init];
        EAAccessoryManager *accessoryManager = [EAAccessoryManager sharedAccessoryManager];
        YKFAccessoryConnection *accessoryConnection = [[YKFAccessoryConnection alloc] initWithAccessoryManager:accessoryManager configuration:configuration];
        accessoryConnection.delegate = self;
        self.accessorySession = accessoryConnection;
        
        if (@available(iOS 11.0, *)) {
            self.otpSession = [[YKFNFCOTPSession alloc] initWithTokenParser:nil session:nil];
        }
    }
    return self;
}

- (void)startAccessoryConnection {
    [self.accessorySession start];
}

- (void)stopAccessoryConnection {
    [self.accessorySession stop];
}

- (void)startNFCConnection API_AVAILABLE(ios(13.0)) {
    [self.nfcSession start];
}

- (void)stopNFCConnection API_AVAILABLE(ios(13.0)) {
    [self.nfcSession stop];
}

- (void)didConnectAccessory:(YKFAccessoryConnection *_Nonnull)connection {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didConnectAccessory:connection];
    });
}

- (void)didDisconnectAccessory:(YKFAccessoryConnection *_Nonnull)connection error:(NSError * _Nullable)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didDisconnectAccessory:connection error:error];
    });
}


- (void)didConnectNFC:(YKFNFCConnection *_Nonnull)connection {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didConnectNFC:connection];
    });
}

- (void)didDisconnectNFC:(YKFNFCConnection *_Nonnull)connection error:(NSError * _Nullable)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didDisconnectNFC:connection error:error];
    });
}

@end
