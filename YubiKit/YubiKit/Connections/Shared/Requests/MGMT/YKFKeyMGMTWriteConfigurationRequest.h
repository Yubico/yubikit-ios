//
//  YKFKeyMGMTWriteConfigurationRequest.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFKeyMGMTRequest.h"
#import "YKFMGMTInterfaceConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

/*!
@class YKFKeyMGMTWriteConfigurationRequest

@abstract
   Request for setting up interfaces on YubiKey.
*/
@interface YKFKeyMGMTWriteConfigurationRequest : YKFKeyMGMTRequest


/*!
 The configuration for the request. The configuration contains list of interfaces that needs to be on and off
 */
@property (nonatomic, readonly, nonnull) YKFMGMTInterfaceConfiguration *configuration;

/*!
 Whether require reboot after updating of configurations
 */
@property (nonatomic, readonly) BOOL reboot;

/*!
 @method initWithConfiguration:
 
 @abstract
    The designated initializer for this type of request. The configuration parameter is required.
 
 @param configuration
    The configuration for the request. The configuration contains list of interfaces that needs to be on and off.
    This configuration has already valid set of iterface changes that ineed to be applied.
 
 @param reboot
    The device reboots after setting configuration.
 */
- (nullable instancetype)initWithConfiguration:(nonnull YKFMGMTInterfaceConfiguration*) configuration reboot: (BOOL) reboot;

@end

NS_ASSUME_NONNULL_END
