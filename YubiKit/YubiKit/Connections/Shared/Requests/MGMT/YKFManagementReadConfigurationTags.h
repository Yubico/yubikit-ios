//
//  YKFManagementReadConfigurationTags.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFManagementReadConfigurationTags_h
#define YKFManagementReadConfigurationTags_h

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

#endif /* YKFManagementReadConfigurationTags_h */
