//
//  YKFKeyMGMTReadConfigurationResponse.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFKeyVersion.h"
#import "YKFMGMTInterfaceConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyMGMTReadConfigurationResponse : NSObject

@property (nonatomic, readonly, nullable) YKFMGMTInterfaceConfiguration* configuration;
@property (nonatomic, readonly, nonnull) YKFKeyVersion* version;

@property (nonatomic, readonly) NSUInteger serialNumber;
@property (nonatomic, readonly) NSUInteger formFactor;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
