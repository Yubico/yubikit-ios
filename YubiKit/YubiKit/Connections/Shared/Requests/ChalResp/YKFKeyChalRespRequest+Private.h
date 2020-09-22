//
//  YKFKeyChalRespRequest+Private.h
//  YubiKit
//
//  Created by Irina Makhalova on 12/26/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#ifndef YKFKeyChalRespRequest_Private_h
#define YKFKeyChalRespRequest_Private_h

#import <Foundation/Foundation.h>
#import "YKFKeyChalRespRequest.h"
#import "YKFAPDU.h"
NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyChalRespRequest()

@property (nonatomic) YKFAPDU *apdu;

@end

NS_ASSUME_NONNULL_END

#endif /* YKFKeyChalRespRequest_Private_h */
