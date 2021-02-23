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
#import <CryptoTokenKit/TKTLVRecord.h>
#import "YKFPIVSession.h"
#import "YKFPIVSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"
#import "YKFVersion.h"
#import "YKFFeature.h"
#import "YKFPIVSessionFeatures.h"
#import "YKFSessionError.h"
#import "YKFNSDataAdditions+Private.h"
#import "NSArray+TKTLVRecord.h"

// Instructions
static const NSUInteger YKFPIVInsVerify = 0x20;
static const NSUInteger YKFPIVInsReset = 0xfb;
static const NSUInteger YKFPIVInsGetVersion = 0xfd;
static const NSUInteger YKFPIVInsGetSerial = 0xf8;
static const NSUInteger YKFPIVInsGetMetadata = 0xf7;
static const NSUInteger YKFPIVInsChangeReference = 0x24;
static const NSUInteger YKFPIVInsResetRetry = 0x2c;


// Tags for parsing responses
static const NSUInteger YKFPIVTagMetadataIsDefault = 0x05;
static const NSUInteger YKFPIVTagMetadataRetries = 0x06;

// P2
static const NSUInteger YKFPIVP2Pin = 0x80;
static const NSUInteger YKFPIVP2Puk = 0x81;

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
            YKFAPDU *versionAPDU = [[YKFAPDU alloc] initWithCla:0 ins:YKFPIVInsGetVersion p1:0 p2:0 data:[NSData data] type:YKFAPDUTypeShort];
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
            YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:YKFPIVInsReset p1:0 p2:0 data:[NSData data] type:YKFAPDUTypeShort];
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
    
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:YKFPIVInsGetSerial p1:0 p2:0 data:[NSData data] type:YKFAPDUTypeShort];
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
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:YKFPIVInsVerify p1:0 p2:0x80 data:data type:YKFAPDUTypeShort];
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

- (void)setPin:(nonnull NSString *)pin oldPin:(nonnull NSString *)oldPin completion:(nonnull YKFPIVSessionCompletionBlock)completion {
    [self changeReference:YKFPIVInsChangeReference p2:YKFPIVP2Pin valueOne:oldPin valueTwo:pin completion:^(int retries, NSError * _Nullable error) {
        completion(error);
    }];
}

- (void)setPuk:(nonnull NSString *)puk oldPuk:(nonnull NSString *)oldPuk completion:(nonnull YKFPIVSessionCompletionBlock)completion {
    [self changeReference:YKFPIVInsChangeReference p2:YKFPIVP2Puk valueOne:oldPuk valueTwo:puk completion:^(int retries, NSError * _Nullable error) {
        completion(error);
    }];
}

- (void)unblockPin:(nonnull NSString *)puk newPin:(nonnull NSString *)newPin completion:(nonnull YKFPIVSessionCompletionBlock)completion {
    [self changeReference:YKFPIVInsResetRetry p2:YKFPIVP2Pin valueOne:puk valueTwo:newPin completion:^(int retries, NSError * _Nullable error) {
        completion(error);
    }];
}

- (void)getPinPukMetadata:(UInt8)p2 completion:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion {
        YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:YKFPIVInsGetMetadata p1:0 p2:p2 data:[NSData data] type:YKFAPDUTypeShort];
    if (![self.features.metadata isSupportedBySession:self]) {
        completion(0, 0, 0, [[NSError alloc] initWithDomain:@"com.yubico.piv" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Read metadata not supported by this YubiKey."}]);
        return;
    }
    
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error != nil) {
            completion(0, 0, 0, error);
        }
        NSArray<TKTLVRecord*> *records = [TKBERTLVRecord sequenceOfRecordsFromData:data];
        UInt8 isDefault = ((UInt8 *)[records ykfTLVRecordWithTag:YKFPIVTagMetadataIsDefault].value.bytes)[0];
        UInt8 retriesTotal = ((UInt8 *)[records ykfTLVRecordWithTag:YKFPIVTagMetadataRetries].value.bytes)[0];
        UInt8 retriesRemaining = ((UInt8 *)[records ykfTLVRecordWithTag:YKFPIVTagMetadataRetries].value.bytes)[1];
        completion(isDefault, retriesTotal, retriesRemaining, nil);
    }];
}

- (void)getPinMetadata:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion {
    [self getPinPukMetadata:YKFPIVP2Pin completion:completion];
}


- (void)getPukMetadata:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion {
    [self getPinPukMetadata:YKFPIVP2Puk completion:completion];
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
