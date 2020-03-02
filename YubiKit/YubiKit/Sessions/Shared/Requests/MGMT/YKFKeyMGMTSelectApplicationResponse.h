//
//  YKFKeyMGMTSelectApplicationResponse.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFKeyVersion.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyMGMTSelectApplicationResponse : NSObject

@property (nonatomic, readonly, nonnull) YKFKeyVersion* version;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
