//
//  YKFManagementReadConfigurationResponse.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFVersion.h"
#import "YKFManagementInterfaceConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YKFManagementReadConfigurationTags) {
    YKFManagementReadConfigurationTagsNone = 0x00,
    YKFManagementReadConfigurationTagsUsbSupported = 0x01,
    YKFManagementReadConfigurationTagsSerialNumber = 0x02,
    YKFManagementReadConfigurationTagsUsbEnabled = 0x03,
    YKFManagementReadConfigurationTagsFormFactor = 0x04,
    YKFManagementReadConfigurationTagsFirmwareVersion = 0x05,
    YKFManagementReadConfigurationTagsConfigLocked = 0x0a,
    YKFManagementReadConfigurationTagsNfcSupported = 0x0d,
    YKFManagementReadConfigurationTagsNfcEnabled = 0x0e
};

@interface YKFManagementReadConfigurationResponse : NSObject

@property (nonatomic, readonly, nullable) YKFManagementInterfaceConfiguration* configuration;
@property (nonatomic, readonly, nonnull) YKFVersion* version;

@property (nonatomic, readonly) NSUInteger serialNumber;
@property (nonatomic, readonly) NSUInteger formFactor;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
