//
//  YKFMGMTApplicationType.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/11/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFMGMTApplicationType_h
#define YKFMGMTApplicationType_h

typedef NS_ENUM(NSUInteger, YKFMGMTApplicationType) {
    YKFMGMTApplicationTypeOTP = 0x01,
    YKFMGMTApplicationTypeU2F = 0x02,
    YKFMGMTApplicationTypeOPGP = 0x08,
    YKFMGMTApplicationTypePIV = 0x10,
    YKFMGMTApplicationTypeOATH = 0x20,
    YKFMGMTApplicationTypeCTAP2 = 0x0200
};

#endif /* YKFMGMTApplicationType_h */
