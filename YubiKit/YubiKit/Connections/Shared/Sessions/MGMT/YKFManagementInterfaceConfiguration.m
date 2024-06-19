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

#import "YKFManagementInterfaceConfiguration.h"
#import "YKFManagementDeviceInfo+Private.h"
#import "YKFManagementDeviceInfo.h"
#import "YKFAssert.h"
#import "YKFTLVRecord.h"
#import "NSArray+YKFTLVRecord.h"
#import "YKFNSDataAdditions+Private.h"

@interface YKFManagementInterfaceConfiguration()

@property (nonatomic, readwrite) BOOL isConfigurationLocked;
@property (nonatomic, readwrite) NSUInteger usbSupportedMask;
@property (nonatomic, readwrite) NSUInteger nfcSupportedMask;
@property (nonatomic, readwrite) BOOL usbMaskChanged;
@property (nonatomic, readwrite) BOOL nfcMaskChanged;

@end

@implementation YKFManagementInterfaceConfiguration

- (nullable instancetype)initWithTLVRecords:(nonnull NSMutableArray<YKFTLVRecord*> *)records {
    self = [super init];
    if (self) {
        self.isConfigurationLocked = [[records ykfTLVRecordWithTag:YKFManagementTagConfigLocked].value ykf_integerValue] == 1;
        self.usbSupportedMask = [[records ykfTLVRecordWithTag:YKFManagementTagUSBSupported].value ykf_integerValue];
        self.usbEnabledMask = [[records ykfTLVRecordWithTag:YKFManagementTagUSBEnabled].value ykf_integerValue];
        self.nfcSupportedMask = [[records ykfTLVRecordWithTag:YKFManagementTagNFCSupported].value ykf_integerValue];
        self.nfcEnabledMask = [[records ykfTLVRecordWithTag:YKFManagementTagNFCEnabled].value ykf_integerValue];
        
        NSData *autoEjectTimeoutData = [records ykfTLVRecordWithTag:YKFManagementTagAutoEjectTimeout].value;
        if (autoEjectTimeoutData) {
            self.autoEjectTimeout = [autoEjectTimeoutData ykf_integerValue];
        }
                                        
        NSData *challengeResponseTimeoutData = [records ykfTLVRecordWithTag:YKFManagementTagChallengeResponseTimeout].value;
        if (challengeResponseTimeoutData) {
            self.challengeResponseTimeout = [challengeResponseTimeoutData ykf_integerValue];
        }
        
        NSData *isNFCRestrictedData = [records ykfTLVRecordWithTag:YKFManagementTagNFCRestricted].value;
        if (isNFCRestrictedData) {
            self.isNFCRestricted = [isNFCRestrictedData ykf_integerValue] == 1;
        }
    }
    return self;
}

- (BOOL) isSupported: (YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport {
    switch (transport) {
        case YKFManagementTransportTypeNFC:
            return (self.nfcSupportedMask & application) == application;
        case YKFManagementTransportTypeUSB:
            return (self.usbSupportedMask & application) == application;
        default:
            YKFAssertReturnValue(true, @"Not supperted transport type", false);
            break;
    }
}

- (BOOL) isEnabled: (YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport {
    switch (transport) {
        case YKFManagementTransportTypeNFC:
            return (self.nfcEnabledMask & application) == application;
        case YKFManagementTransportTypeUSB:
            return (self.usbEnabledMask & application) == application;
        default:
            YKFAssertReturnValue(true, @"Not supperted transport type", false);
            break;
    }
}

- (void) setEnabled: (BOOL)newValue application:(YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport {
    NSUInteger oldEnabledMask = transport == YKFManagementTransportTypeUSB ? self.usbEnabledMask : self.nfcEnabledMask;
    NSUInteger newEnabledMask = newValue ? (oldEnabledMask | application) : (oldEnabledMask & ~application);

    if (oldEnabledMask == newEnabledMask) {
        // check if there is no changes needs to be applied
        return;
    }

    YKFAssertReturn(!self.isConfigurationLocked, @"Configuration is locked.")
    YKFAssertReturn([self isSupported: application overTransport:transport], @"This YubiKey interface is not supported.")

    switch (transport) {
        case YKFManagementTransportTypeNFC:
            self.nfcEnabledMask = newEnabledMask;
            self.nfcMaskChanged = true;
            break;
        case YKFManagementTransportTypeUSB:
            self.usbEnabledMask = newEnabledMask;
            self.usbMaskChanged = true;
            break;
        default:
            YKFAssertReturn(true, @"Not supperted transport type");
            break;
    }
}

+ (NSUInteger)translateFipsMask:(NSUInteger)fipsMask {
    NSUInteger capabilities = 0;
    if ((fipsMask & 0b00000001) != 0) {
        capabilities |= YKFManagementApplicationTypeOTP;
    }
    if ((fipsMask & 0b00000010) != 0) {
        capabilities |= YKFManagementApplicationTypePIV;
    }
    if ((fipsMask & 0b00000100) != 0) {
        capabilities |= YKFManagementApplicationTypeOPGP;
    }
    if ((fipsMask & 0b00001000) != 0) {
        capabilities |= YKFManagementApplicationTypeOATH;
    }
    if ((fipsMask & 0b00010000) != 0) {
        capabilities |= YKFManagementApplicationTypeHSMAUTH;
    }
    return capabilities;
}


@end
