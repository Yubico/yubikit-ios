// Copyright 2018-2021 Yubico AB
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
#import "YKFPIVSession.h"
#import "YKFPIVSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"
#import "YKFVersion.h"
#import "YKFFeature.h"
#import "YKFPIVSessionFeatures.h"
#import "YKFSessionError.h"

@interface YKFPIVSession()

@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readwrite) YKFVersion * _Nonnull version;
@property (nonatomic, readwrite) YKFPIVSessionFeatures * _Nonnull features;

@end


@implementation YKFPIVSession

int currentPinAttempts = 3;
int maxPinAttempts = 3;

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                             completion:(YKFPIVSessionCompletion _Nonnull)completion {
    YKFPIVSession *session = [YKFPIVSession new];
    session.features = [YKFPIVSessionFeatures new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNamePIV];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            YKFAPDU *versionAPDU = [[YKFAPDU alloc] initWithCla:0 ins:0xfd p1:0 p2:0 data:[NSData data] type:YKFAPDUTypeShort];
            [session.smartCardInterface executeCommand:versionAPDU completion:^(NSData * _Nullable data, NSError * _Nullable error) {
                if (error) {
                    completion(nil, error);
                } else {
                    UInt8 *versionBytes = (UInt8 *)data.bytes;
                    session.version = [[YKFVersion alloc] initWithBytes:versionBytes[0] minor:versionBytes[1] micro:versionBytes[2]];
                    completion(session, nil);
                }
            }];
        }
    }];
}

- (void)clearSessionState {
    // Do nothing for now
}

- (void)resetWithCompletion:(YKFPIVSessionCompletionBlock)completion {
    [self blockPin:0 completion:^(NSError * _Nullable error) {
        if (error != nil) {
            completion(error);
            return;
        }
        [self blockPuk:0 completion:^(NSError * _Nullable error) {
            if (error != nil) {
                completion(error);
                return;
            }
            YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0xfb p1:0 p2:0 data:[NSData data] type:YKFAPDUTypeShort];
            [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
                completion(error);
            }];
        }];
    }];
}


- (void)getSerialNumberWithCompletion:(YKFPIVSessionSerialNumberCompletionBlock)completion {
    if (![self.features.serial isSupportedBySession:self]) {
        completion(-1, [[NSError alloc] initWithDomain:@"com.yubico.piv" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Read serial number not supported by this YubiKey."}]);
        return;
    }
    
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0xf8 p1:0 p2:0 data:[NSData data] type:YKFAPDUTypeShort];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (data != nil) {
            UInt32 serialNumber = CFSwapInt32BigToHost(*(UInt32*)([data bytes]));
            completion(serialNumber, nil);
        } else {
            completion(-1, error);
        }
    }];
}

- (void)verifyPin:(nonnull NSString *)pin completion:(nonnull YKFPIVSessionVerifyPinCompletionBlock)completion {
    NSData *data = [self paddedDataWithPin:pin];
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0x20 p1:0 p2:0x80 data:data type:YKFAPDUTypeShort];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error == nil) {
            currentPinAttempts = maxPinAttempts;
            completion(currentPinAttempts, nil);
            return;
        } else {
            YKFSessionError *sessionError = (YKFSessionError *)error;
            if ([sessionError isKindOfClass:[YKFSessionError class]]) {
                int retries = [self getRetriesFromStatusCode:(int)sessionError.code];
                if (retries >= 0) {
                    currentPinAttempts = retries;
                    completion(currentPinAttempts, error);
                    return;
                }
            }
            completion(-1, error);
        }
    }];
}

- (int)getRetriesFromStatusCode:(int)statusCode {
    if (statusCode == 0x6983) {
        return 0;
    }
    if ([self.version compare:[[YKFVersion alloc] initWithString:@"1.0.4"]] == NSOrderedAscending) {
        if (statusCode >= 0x6300 && statusCode <= 0x63ff) {
            return statusCode & 0xff;
        }
    } else {
        if (statusCode >= 0x63c0 && statusCode <= 0x63cf) {
            return statusCode & 0xf;
        }
    }
    return -1;
}

- (void)blockPin:(int)counter completion:(YKFPIVSessionCompletionBlock)completion {
    [self verifyPin:@"" completion:^(int retries, NSError * _Nullable error) {
        if (retries == -1 && error != nil) {
            completion(error);
            return;
        }
        if (retries <= 0 || counter > 15) {
            completion(nil);
        } else {
            [self blockPin:(counter + 1) completion:completion];
        }
    }];
}

- (void)blockPuk:(int)counter completion:(YKFPIVSessionCompletionBlock)completion {
    [self changeReference:0x2c p2:0x80 valueOne:@"" valueTwo:@"" completion:^(int retries, NSError * _Nullable error) {
        if (retries == -1 && error != nil) {
            completion(error);
            return;
        }
        if (retries <= 0 || counter > 15) {
            completion(nil);
        } else {
            [self blockPuk:(counter + 1) completion:completion];
        }
    }];
}

- (void)changeReference:(UInt8)ins p2:(UInt8)p2 valueOne:(NSString *)valueOne valueTwo:(NSString *)valueTwo completion:(nonnull YKFPIVSessionVerifyPinCompletionBlock)completion {
    NSMutableData *data = [self paddedDataWithPin:valueOne].mutableCopy;
    [data appendData:[self paddedDataWithPin:valueTwo]];
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:ins p1:0 p2:p2 data:data type:YKFAPDUTypeShort];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error != nil) {
            int retries = [self getRetriesFromStatusCode:(int)error.code];
            if (retries >= 0) {
                if (p2 == 0x80) {
                    currentPinAttempts = retries;
                }
                completion(retries, error);
            }
        } else {
            completion(currentPinAttempts, nil);
        }
    }];
}

- (nonnull NSData *)paddedDataWithPin:(nonnull NSString *)pin {
    NSMutableData *mutableData = [[pin dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    UInt8 padding = 0xff;
    int paddingSize = 8 - (int)mutableData.length;
    for (int i = 0; i < paddingSize; i++) {
        [mutableData appendBytes:&padding length:1];
        NSLog(@"%@", mutableData);
    }
    return mutableData;
}


@end
