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

#ifndef YKFDeviceInfo_h
#define YKFDeviceInfo_h


@class YKFVersion, YKFManagementInterfaceConfiguration;

typedef NS_ENUM(NSUInteger, YKFFormFactor) {
    /// Used when information about the YubiKey's form factor isn't available.
    YKFFormFactorUnknown = 0x00,
    /// A keychain-sized YubiKey with a USB-A connector.
    YKFFormFactorUSBAKeychain = 0x01,
    /// A nano-sized YubiKey with a USB-A connector.
    YKFFormFactorUSBANano = 0x02,
    /// A keychain-sized YubiKey with a USB-C connector.
    YKFFormFactorUSBCKeychain = 0x03,
    /// A nano-sized YubiKey with a USB-C connector.
    YKFFormFactorUSBCNano = 0x04,
    /// A keychain-sized YubiKey with both USB-C and Lightning connectors.
    YKFFormFactorUSBCLightning = 0x05,
    /// A keychain-sized YubiKey with fingerprint sensor and USB-A connector.
    YKFFormFactorUSBABio = 0x06,
    /// A keychain-sized YubiKey with fingerprint sensor and USB-C connector.
    YKFFormFactorUSBCBio = 0x07,
};

NS_ASSUME_NONNULL_BEGIN

@interface YKFManagementDeviceInfo : NSObject

@property (nonatomic, readonly, nullable) YKFManagementInterfaceConfiguration* configuration;

@property (nonatomic, readonly) NSUInteger serialNumber;
@property (nonatomic, readonly) YKFVersion *version;
@property (nonatomic, readonly) YKFFormFactor formFactor;
@property (nonatomic, readonly, nullable) NSString* partNumber;
@property (nonatomic, readonly) NSUInteger isFIPSCapable;
@property (nonatomic, readonly) NSUInteger isFIPSApproved;
@property (nonatomic, readonly, nullable) YKFVersion *fpsVersion;
@property (nonatomic, readonly, nullable) YKFVersion *stmVersion;
@property (nonatomic, readonly) bool isConfigurationLocked;
@property (nonatomic, readonly) bool isFips;
@property (nonatomic, readonly) bool isSky;
@property (nonatomic, readonly) bool pinComplexity;
@property (nonatomic, readonly) NSUInteger isResetBlocked;

@end

NS_ASSUME_NONNULL_END

#endif /* YKFDeviceInfo_h */
