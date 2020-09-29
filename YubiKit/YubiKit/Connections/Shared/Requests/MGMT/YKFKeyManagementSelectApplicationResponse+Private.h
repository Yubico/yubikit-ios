//
//  YKFKeyManagementSelectApplicationResponse+Private.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#ifndef YKFKeyManagementSelectApplicationResponse_Private_h
#define YKFKeyManagementSelectApplicationResponse_Private_h

#import "YKFKeyManagementSelectApplicationResponse.h"

@interface YKFKeyManagementSelectApplicationResponse()

- (nullable instancetype)initWithKeyResponseData:(nonnull NSData *)responseData NS_DESIGNATED_INITIALIZER;

@end

#endif /* YKFKeyManagementSelectApplicationResponse_Private_h */
