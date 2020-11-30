//
//  YKFManagementConfiguration.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YKFManagementApplicationType) {
    YKFManagementApplicationTypeOTP = 0x01,
    YKFManagementApplicationTypeU2F = 0x02,
    YKFManagementApplicationTypeOPGP = 0x08,
    YKFManagementApplicationTypePIV = 0x10,
    YKFManagementApplicationTypeOATH = 0x20,
    YKFManagementApplicationTypeCTAP2 = 0x0200
};

typedef NS_ENUM(NSUInteger, YKFManagementTransportType) {
    YKFManagementTransportTypeNFC = 1,
    YKFManagementTransportTypeUSB = 2
};

@interface YKFManagementInterfaceConfiguration : NSObject

@property (nonatomic, readonly) BOOL isConfigurationLocked;

- (BOOL)isEnabled:(YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport;
- (BOOL)isSupported:(YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport;
- (void)setEnabled:(BOOL)newValue application:(YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
