//
//  YKFKeyChallengeResponseService.h
//  YubiKit
//
//  Created by Irina Makhalova on 12/18/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YKFKeyRawCommandService.h"
#import "YKFKeyService.h"
#import "YKFSlot.h"

/**
 * ---------------------------------------------------------------------------------------------------------------------
 * @name Raw Command Service Response Blocks
 * ---------------------------------------------------------------------------------------------------------------------
 */

/*!
 @abstract
    Response block for [executeCommand:completion:] which provides the result for the execution
    of the raw request.
 
 @param response
    The response of the request when it was successful. In case of error this parameter is nil.
 
 @param error
    In case of a failed request this parameter contains the error. If the request was successful
    this parameter is nil.
 */
typedef void (^YKFKeyChallengeResponseServiceResponseBlock)
    (NSData* _Nullable response, NSError* _Nullable error);

/**
 * ---------------------------------------------------------------------------------------------------------------------
 * @name Raw Command Service Protocol
 * ---------------------------------------------------------------------------------------------------------------------
 */

NS_ASSUME_NONNULL_BEGIN


@protocol YKFKeyChallengeResponseServiceProtocol<NSObject>

- (void)sendChallenge:(NSData *)challenge slot:(YKFSlot) slot completion:(YKFKeyChallengeResponseServiceResponseBlock)completion;

@end

NS_ASSUME_NONNULL_END

/**
 * ---------------------------------------------------------------------------------------------------------------------
 * @name Raw Command Service
 * ---------------------------------------------------------------------------------------------------------------------
 */

NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyChallengeResponseService: YKFKeyService<YKFKeyChallengeResponseServiceProtocol>

- (nullable instancetype)initWithService:(nonnull id<YKFKeyRawCommandServiceProtocol>)rawCommandService NS_DESIGNATED_INITIALIZER;

/*
 Not available: use initWithService
 */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
