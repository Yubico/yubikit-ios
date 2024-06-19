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

#import "YKFManagementSession+Private.h"
#import "YKFManagementSessionFeatures.h"
#import "YKFManagementWriteAPDU.h"
#import "YKFManagementDeviceInfo+Private.h"
#import "YKFSession+Private.h"
#import "YKFAssert.h"
#import "YKFAPDUError.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"
#import "YKFFeature.h"
#import "NSArray+YKFTLVRecord.h"
#import "YKFTLVRecord.h"

NSString* const YKFManagementErrorDomain = @"com.yubico.management";

@interface YKFManagementSession()

@property (nonatomic, readwrite) YKFVersion *version;
@property (nonatomic, readwrite) YKFManagementSessionFeatures * _Nonnull features;

- (YKFVersion *)versionFromResponse:(nonnull NSData *)data;

@end

@implementation YKFManagementSession

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                               completion:(YKFManagementSessionCompletion _Nonnull)completion {
    
    YKFManagementSession *session = [YKFManagementSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    session.features = [YKFManagementSessionFeatures new];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameManagement];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            session.version = [session versionFromResponse:data];
            completion(session, nil);
        }
    }];
}

- (void)getDeviceInfoWithCompletion:(YKFManagementSessionGetDeviceInfoBlock)completion {
    YKFParameterAssertReturn(completion);
    if (![self.features.deviceInfo isSupportedBySession:self]) {
        completion(nil, [[NSError alloc] initWithDomain:YKFManagementErrorDomain code:YKFManagementErrorCodeUnsupportedOperation userInfo:@{NSLocalizedDescriptionKey: @"Device info not supported by this YubiKey."}]);
        return;
    }
    [self readPagedDeviceInfoWithCompletion:^(NSMutableArray<YKFTLVRecord *> *result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFManagementDeviceInfo *deviceInfo = [[YKFManagementDeviceInfo alloc] initWithTLVRecords:result defaultVersion:self.version];
        completion(deviceInfo, error);
        return;
    } result: [NSMutableArray<YKFTLVRecord *> new] page: 0];
}

typedef void (^YKFManagementSessionReadPagedDeviceInfoBlock)
    (NSMutableArray<YKFTLVRecord *>* result, NSError* _Nullable error);

- (void)readPagedDeviceInfoWithCompletion:(YKFManagementSessionReadPagedDeviceInfoBlock)completion result:(NSMutableArray<YKFTLVRecord *>* _Nonnull)result page:(UInt8)page {
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x1D p1:page p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        const char* bytes = (const char*)[data bytes];
        int length = bytes[0] & 0xff;
        if (length != data.length - 1) {
            completion(result, nil);
            return;
        }
        NSArray<YKFTLVRecord*> *records = [YKFTLVRecord sequenceOfRecordsFromData:[data subdataWithRange:NSMakeRange(1, data.length -  1)]];
        [result addObjectsFromArray:records];
        if ([records ykfTLVRecordWithTag:0x10] != nil) {
            [self readPagedDeviceInfoWithCompletion:completion result:result page:page + 1];
            return;
        } else {
            completion(result, nil);
            return;
        }
    }];
}

- (void)writeConfiguration:(YKFManagementInterfaceConfiguration*)configuration reboot:(BOOL)reboot lockCode:(nullable NSData *)lockCode newLockCode:(nullable NSData *)newLockCode completion:(nonnull YKFManagementSessionWriteCompletionBlock)completion {
    YKFParameterAssertReturn(configuration);
    if (![self.features.deviceConfig isSupportedBySession:self]) {
        completion([[NSError alloc] initWithDomain:YKFManagementErrorDomain code:YKFManagementErrorCodeUnsupportedOperation userInfo:@{NSLocalizedDescriptionKey: @"Writing device configuration not supported by this YubiKey."}]);
        return;
    }
    YKFManagementWriteAPDU *apdu = [[YKFManagementWriteAPDU alloc]initWithConfiguration:configuration reboot:reboot lockCode:lockCode newLockCode:newLockCode];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        completion(error);
    }];
}

- (void)writeConfiguration:(YKFManagementInterfaceConfiguration*)configuration reboot:(BOOL)reboot lockCode:(nullable NSData *)lockCode completion:(nonnull YKFManagementSessionWriteCompletionBlock)completion {
    [self writeConfiguration:configuration reboot:reboot lockCode:lockCode newLockCode:nil completion:completion];
}

- (void)writeConfiguration:(YKFManagementInterfaceConfiguration*)configuration reboot:(BOOL)reboot completion:(nonnull YKFManagementSessionWriteCompletionBlock)completion {
    [self writeConfiguration:configuration reboot:reboot lockCode:nil newLockCode:nil completion:completion];
}

// No application side state that needs clearing but this will be called when another
// session is replacing the YKFManagementSession.
- (void)clearSessionState {
    ;
}

#pragma mark - Helpers

- (YKFVersion *)versionFromResponse:(nonnull NSData *)data {
    NSString *responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSASCIIStringEncoding];
    NSArray *responseArray = [responseString componentsSeparatedByString:@" "];

    NSAssert(responseArray.count > 0, @"No version number in select management application response");
    NSString *versionString = responseArray.lastObject;

    NSArray *versionArray = [versionString componentsSeparatedByString:@"."];
    NSAssert(versionArray.count == 3, @"Malformed version number: '%@'", versionString);
    
    NSUInteger major = [versionArray[0] intValue];
    NSUInteger minor = [versionArray[1] intValue];
    NSUInteger micro = [versionArray[2] intValue];

    return [[YKFVersion alloc] initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro];
}

@end
