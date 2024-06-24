//
//  YKFInvalidPinError.m
//  YubiKit
//
//  Created by Jens Utbult on 2024-06-19.
//  Copyright © 2024 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKFInvalidPinError.h"

NSString* const YKFInvalidPinErrorDomain = @"com.yubico.invalid-pin";
NSInteger const YKFInvalidPinErrorCode = 1;

@interface YKFInvalidPinError()

@property (nonatomic, readwrite) int retries;

@end

@implementation YKFInvalidPinError

+ (instancetype)invalidPinErrorWithRetries:(int)retries {
    YKFInvalidPinError *error = [[YKFInvalidPinError alloc] initWithDomain:YKFInvalidPinErrorDomain code:YKFInvalidPinErrorCode userInfo:nil];
    error.retries = retries;
    return error;
}

@end
