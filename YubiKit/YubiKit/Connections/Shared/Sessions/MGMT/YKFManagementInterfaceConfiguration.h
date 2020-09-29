//
//  YKFManagementConfiguration.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFManagementApplicationType.h"
#import "YKFManagementTransportType.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFManagementInterfaceConfiguration : NSObject

@property (nonatomic, readonly) BOOL isConfigurationLocked;

- (BOOL) isEnabled: (YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport;
- (BOOL) isSupported: (YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport;
- (void) setEnabled: (BOOL)newValue application:(YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
