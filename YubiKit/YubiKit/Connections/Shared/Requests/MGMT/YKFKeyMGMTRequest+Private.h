//
//  YKFKeyMGMTRequest.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFAPDU.h"
#import "YKFKeyMGMTRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyMGMTRequest()

@property (nonatomic) YKFAPDU *apdu;

@end

NS_ASSUME_NONNULL_END
