//
//  YKFKeyMGMTReadConfigurationResponse.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTReadConfigurationResponse.h"

@interface YKFKeyMGMTReadConfigurationResponse()

@property (nonatomic, readonly) NSUInteger usbSupportedMask;
@property (nonatomic, readonly) NSUInteger nfcSupportedMask;

@property (nonatomic, readonly) NSUInteger usbEnabledMask;
@property (nonatomic, readonly) NSUInteger nfcEnabledMask;

@property (nonatomic, nullable, readwrite) NSData *configurationLocked;

- (nullable instancetype)initWithKeyResponseData:(nonnull NSData *)responseData version:(YKFKeyVersion *_Nonnull)version NS_DESIGNATED_INITIALIZER;

@end


