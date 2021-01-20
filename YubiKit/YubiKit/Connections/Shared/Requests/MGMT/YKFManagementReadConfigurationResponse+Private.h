//
//  YKFManagementReadConfigurationResponse.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementReadConfigurationResponse.h"

@interface YKFManagementReadConfigurationResponse()

@property (nonatomic, readwrite) NSUInteger usbSupportedMask;
@property (nonatomic, readwrite) NSUInteger nfcSupportedMask;

@property (nonatomic, readwrite) NSUInteger usbEnabledMask;
@property (nonatomic, readwrite) NSUInteger nfcEnabledMask;

@property (nonatomic, nullable, readwrite) NSData *configurationLocked;

- (nullable instancetype)initWithKeyResponseData:(nonnull NSData *)responseData version:(YKFVersion *_Nonnull)version NS_DESIGNATED_INITIALIZER;

@end


