//
//  YKFMGMTReadConfigurationTags.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFMGMTReadConfigurationTags_h
#define YKFMGMTReadConfigurationTags_h

typedef NS_ENUM(NSUInteger, YKFMGMTReadConfigurationTags) {
    YKFMGMTReadConfigurationTagsNone = 0x00,
    YKFMGMTReadConfigurationTagsUsbSupported = 0x01,
    YKFMGMTReadConfigurationTagsSerialNumber = 0x02,
    YKFMGMTReadConfigurationTagsUsbEnabled = 0x03,
    YKFMGMTReadConfigurationTagsFormFactor = 0x04,
    YKFMGMTReadConfigurationTagsFirmwareVersion = 0x05,
    YKFMGMTReadConfigurationTagsConfigLocked = 0x0a,
    YKFMGMTReadConfigurationTagsNfcSupported = 0x0d,
    YKFMGMTReadConfigurationTagsNfcEnabled = 0x0e
};

#endif /* YKFMGMTReadConfigurationTags_h */
