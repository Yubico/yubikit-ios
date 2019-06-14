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
#import "YKFKeySessionConfiguration.h"

#import "YKFNFCReaderSession+Private.h"
#import "YKFKeySession+Private.h"

@interface YubiKitManager()

@property (nonatomic, readwrite) id<YKFNFCReaderSessionProtocol> nfcReaderSession NS_AVAILABLE_IOS(11.0);
@property (nonatomic, readwrite) id<YKFQRReaderSessionProtocol> qrReaderSession;
@property (nonatomic, readwrite) id<YKFKeySessionProtocol> keySession;

@end

@implementation YubiKitManager

static id<YubiKitManagerProtocol> sharedInstance;

+ (id<YubiKitManagerProtocol>)shared {
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
            // Init with defaults
            self.nfcReaderSession = [[YKFNFCReaderSession alloc] initWithTokenParser:nil session:nil];
        }
        self.qrReaderSession = [[YKFQRReaderSession alloc] init];
        
        YKFKeySessionConfiguration *configuration = [[YKFKeySessionConfiguration alloc] init];
        EAAccessoryManager *accessoryManager = [EAAccessoryManager sharedAccessoryManager];
        
        self.keySession = [[YKFKeySession alloc] initWithAccessoryManager:accessoryManager configuration:configuration];
    }
    return self;
}

@end
