//
//  YKFKeyChallengeResponseError.h
//  YubiKit
//
//  Created by Irina Makhalova on 12/30/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFKeySessionError.h"

typedef NS_ENUM(NSUInteger, YKFKeyChallengeResponseErrorCode) {
    
    /*! The host application does not have any active connection with YubiKey
     */
    YKFKeyChallengeResponseErrorCodeNoConnection = YKFKeySessionErrorNoConnection,
    
    /*! Key does not have programmed secret on slot
     */
    YKFKeyChallengeResponseErrorCodeEmptyResponse = 0x000201,
};

NS_ASSUME_NONNULL_BEGIN

/*!
@class
   YKFKeyChallengeResponseError
@abstract
   Error type returned by the YKFKeyChallengeResponseService.
*/
@interface YKFKeyChallengeResponseError : YKFKeySessionError

@end

NS_ASSUME_NONNULL_END
