//
//  YKFKeyManagementError.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFKeySessionError.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YKFKeyManagementErrorCode) {
    /*! Key returned malformed response
     */
    YKFKeyManagementErrorCodeUnexpectedResponse = 0x300,
};

@interface YKFKeyManagementError : YKFKeySessionError

@end

NS_ASSUME_NONNULL_END
