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

#import <Foundation/Foundation.h>
#import "YKFManagementDeviceInfo+Private.h"
#import "YKFAssert.h"
#import "YKFTLVRecord.h"
#import "NSArray+YKFTLVRecord.h"
#import "YKFNSDataAdditions+Private.h"
#import "YKFVersion.h"
#import "YKFManagementInterfaceConfiguration+Private.h"



@interface YKFManagementDeviceInfo()

@property (nonatomic, readwrite) NSUInteger serialNumber;
@property (nonatomic, readwrite) YKFVersion *version;
@property (nonatomic, readwrite) YKFFormFactor formFactor;
@property (nonatomic, readwrite, nullable) NSString* partNumber;
@property (nonatomic, readwrite) NSUInteger isFIPSCapable;
@property (nonatomic, readwrite) NSUInteger isFIPSApproved;
@property (nonatomic, readwrite, nullable) YKFVersion *fpsVersion;
@property (nonatomic, readwrite, nullable) YKFVersion *stmVersion;
@property (nonatomic, readwrite) bool isConfigurationLocked;
@property (nonatomic, readwrite) bool isFips;
@property (nonatomic, readwrite) bool isSky;
@property (nonatomic, readwrite) bool pinComplexity;
@property (nonatomic, readwrite) NSUInteger isResetBlocked;
@property (nonatomic, readwrite) YKFManagementInterfaceConfiguration *configuration;

@end

@implementation YKFManagementDeviceInfo

- (nullable instancetype)initWithResponseData:(nonnull NSMutableArray<YKFTLVRecord*> *)records defaultVersion:(nonnull YKFVersion *)defaultVersion {
    YKFAssertAbortInit(records.count > 0);
    YKFAssertAbortInit(defaultVersion)
    self = [super init];
    if (self) {       
        self.isConfigurationLocked = [[records ykfTLVRecordWithTag:YKFManagementTagConfigLocked].value ykf_integerValue] == 1;
        
        self.serialNumber = [[records ykfTLVRecordWithTag:YKFManagementTagSerialNumber].value ykf_integerValue];
        
        NSUInteger reportedFormFactor = [[records ykfTLVRecordWithTag:YKFManagementTagFormfactor].value ykf_integerValue];
        self.isFips = (reportedFormFactor & 0x80) != 0;
        self.isSky = (reportedFormFactor & 0x40) != 0;
        
        switch (reportedFormFactor & 0x0f) {
            case YKFFormFactorUSBAKeychain:
                self.formFactor = YKFFormFactorUSBAKeychain;
                break;
            case YKFFormFactorUSBANano:
                self.formFactor = YKFFormFactorUSBANano;
                break;
            case YKFFormFactorUSBCKeychain:
                self.formFactor = YKFFormFactorUSBCKeychain;
                break;
            case YKFFormFactorUSBCNano:
                self.formFactor = YKFFormFactorUSBCNano;
                break;
            case YKFFormFactorUSBCLightning:
                self.formFactor = YKFFormFactorUSBCLightning;
                break;
            case YKFFormFactorUSBABio:
                self.formFactor = YKFFormFactorUSBABio;
                break;
            case YKFFormFactorUSBCBio:
                self.formFactor = YKFFormFactorUSBCBio;
                break;
            default:
                self.formFactor = YKFFormFactorUnknown;
        }
        
        self.isFIPSCapable = [YKFManagementInterfaceConfiguration translateFipsMask:[[records ykfTLVRecordWithTag:YKFManagementTagFIPSCapable].value ykf_integerValue]];
        self.isFIPSApproved = [YKFManagementInterfaceConfiguration translateFipsMask:[[records ykfTLVRecordWithTag:YKFManagementTagFIPSApproved].value ykf_integerValue]];
        
        self.pinComplexity = [[records ykfTLVRecordWithTag:YKFManagementTagPINComplexity].value ykf_integerValue] == 1;
        self.isResetBlocked = [[records ykfTLVRecordWithTag:YKFManagementTagResetBlocked].value ykf_integerValue];

        NSData *versionData = [records ykfTLVRecordWithTag:YKFManagementTagFirmwareVersion].value;
        if (versionData != nil) {
            self.version = [[YKFVersion alloc] initWithData:versionData];
        } else {
            self.version = defaultVersion;
        }
        
        NSData *fpsVersionData = [records ykfTLVRecordWithTag:YKFManagementTagFPSVersion].value;
        if (fpsVersionData) {
            YKFVersion *version = [[YKFVersion alloc] initWithData:fpsVersionData];
            if (version && version != [[YKFVersion alloc] initWithString:@"0.0.0"]) {
                self.fpsVersion = version;
            }
        }
        NSData *stmVersionData = [records ykfTLVRecordWithTag:YKFManagementTagSTMVersion].value;
        if (stmVersionData) {
            YKFVersion *version = [[YKFVersion alloc] initWithData:stmVersionData];
            if (version && version != [[YKFVersion alloc] initWithString:@"0.0.0"]) {
                self.stmVersion = version;
            }
        }
        self.partNumber = [[NSString alloc] initWithData:[records ykfTLVRecordWithTag:YKFManagementTagSTMVersion].value encoding:NSUTF8StringEncoding];
        if (self.partNumber.length == 0) {
            self.partNumber = nil;
        }
        
        self.usbSupportedMask = [[records ykfTLVRecordWithTag:YKFManagementTagUSBSupported].value ykf_integerValue];
        self.usbEnabledMask = [[records ykfTLVRecordWithTag:YKFManagementTagUSBEnabled].value ykf_integerValue];
        self.nfcSupportedMask = [[records ykfTLVRecordWithTag:YKFManagementTagNFCSupported].value ykf_integerValue];
        self.nfcEnabledMask = [[records ykfTLVRecordWithTag:YKFManagementTagNFCEnabled].value ykf_integerValue];
        
        self.configuration = [[YKFManagementInterfaceConfiguration alloc] initWithDeviceInfo:self];
    }
    return self;
}

@end
