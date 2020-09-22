//
//  YKFYubiKeySendChallengeAPDU.h
//  YubiKit
//
//  Created by Irina Makhalova on 12/20/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFAPDU.h"
#import "YKFKeyChalRespSendRequest.h"
NS_ASSUME_NONNULL_BEGIN

@interface YKFHMAC1ChallengeResponseAPDU : YKFAPDU

- (nullable instancetype)initWithRequest:(YKFKeyChalRespSendRequest *)request NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
