//
//  YKFManagementInterfaceConfiguration+Private.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFManagementInterfaceConfiguration_Private_h
#define YKFManagementInterfaceConfiguration_Private_h

#import "YKFManagementInterfaceConfiguration.h"
#import "YKFManagementReadConfigurationResponse.h"


@interface YKFManagementInterfaceConfiguration()

@property (nonatomic, readonly) NSUInteger usbSupportedMask;
@property (nonatomic, readonly) NSUInteger nfcSupportedMask;

@property (nonatomic, readonly) NSUInteger usbEnabledMask;
@property (nonatomic, readonly) NSUInteger nfcEnabledMask;

@property (nonatomic, readonly) BOOL usbMaskChanged;
@property (nonatomic, readonly) BOOL nfcMaskChanged;

- (nullable instancetype)initWithResponse:(nonnull YKFManagementReadConfigurationResponse *)response NS_DESIGNATED_INITIALIZER;

@end

#endif /* YKFManagementInterfaceConfiguration_Private_h */
