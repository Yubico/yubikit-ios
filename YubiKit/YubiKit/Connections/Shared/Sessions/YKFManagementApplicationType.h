//
//  YKFManagementApplicationType.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/11/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFManagementApplicationType_h
#define YKFManagementApplicationType_h

typedef NS_ENUM(NSUInteger, YKFManagementApplicationType) {
    YKFManagementApplicationTypeOTP = 0x01,
    YKFManagementApplicationTypeU2F = 0x02,
    YKFManagementApplicationTypeOPGP = 0x08,
    YKFManagementApplicationTypePIV = 0x10,
    YKFManagementApplicationTypeOATH = 0x20,
    YKFManagementApplicationTypeCTAP2 = 0x0200
};

#endif /* YKFManagementApplicationType_h */
