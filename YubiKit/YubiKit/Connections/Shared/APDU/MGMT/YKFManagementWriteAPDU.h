//
//  YKFManagementWriteAPDU.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFAPDU.h"
#import "YKFKeyManagementWriteConfigurationRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFManagementWriteAPDU : YKFAPDU

- (nullable instancetype)initWithRequest:(YKFKeyManagementWriteConfigurationRequest *)request  NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
