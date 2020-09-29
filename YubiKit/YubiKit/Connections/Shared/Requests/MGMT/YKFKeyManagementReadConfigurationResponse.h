//
//  YKFKeyManagementReadConfigurationResponse.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFKeyVersion.h"
#import "YKFManagementInterfaceConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyManagementReadConfigurationResponse : NSObject

@property (nonatomic, readonly, nullable) YKFManagementInterfaceConfiguration* configuration;
@property (nonatomic, readonly, nonnull) YKFKeyVersion* version;

@property (nonatomic, readonly) NSUInteger serialNumber;
@property (nonatomic, readonly) NSUInteger formFactor;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
