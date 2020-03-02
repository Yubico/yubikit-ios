//
//  YKFMGMTInterfaceConfiguration+Private.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFMGMTInterfaceConfiguration_Private_h
#define YKFMGMTInterfaceConfiguration_Private_h

#import "YKFMGMTInterfaceConfiguration.h"
#import "YKFKeyMGMTReadConfigurationResponse.h"


@interface YKFMGMTInterfaceConfiguration()

@property (nonatomic, readonly) NSUInteger usbSupportedMask;
@property (nonatomic, readonly) NSUInteger nfcSupportedMask;

@property (nonatomic, readonly) NSUInteger usbEnabledMask;
@property (nonatomic, readonly) NSUInteger nfcEnabledMask;

@property (nonatomic, readonly) BOOL usbMaskChanged;
@property (nonatomic, readonly) BOOL nfcMaskChanged;

- (nullable instancetype)initWithResponse:(nonnull YKFKeyMGMTReadConfigurationResponse *)response NS_DESIGNATED_INITIALIZER;

@end

#endif /* YKFMGMTInterfaceConfiguration_Private_h */
