//
//  YKFManagementError.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFSessionError.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YKFManagementErrorCode) {
    /*! Key returned malformed response
     */
    YKFManagementErrorCodeUnexpectedResponse = 0x300,
};

@interface YKFManagementError : YKFSessionError

@end

NS_ASSUME_NONNULL_END
