//
//  YKFMGMTConfiguration.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFMGMTApplicationType.h"
#import "YKFMGMTTransportType.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFMGMTInterfaceConfiguration : NSObject

@property (nonatomic, readonly) BOOL isConfigurationLocked;

- (BOOL) isEnabled: (YKFMGMTApplicationType)application overTransport:(YKFMGMTTransportType)transport;
- (BOOL) isSupported: (YKFMGMTApplicationType)application overTransport:(YKFMGMTTransportType)transport;
- (void) setEnabled: (BOOL)newValue application:(YKFMGMTApplicationType)application overTransport:(YKFMGMTTransportType)transport;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
