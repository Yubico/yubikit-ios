//
//  YKFKeyChallengeResponseError.m
//  YubiKit
//
//  Created by Irina Makhalova on 12/30/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import "YKFKeyChallengeResponseError.h"
#import "YKFKeySessionError+Private.h"

static NSString* const YKFKeyChallengeResponseNoConnectionDescription = @"YubiKey is not connected";
static NSString* const YKFKeyChallengeResponseEmptyResponseDescription = @"Response is empty. Make sure that YubiKey have programmed challenge-response secret";

@implementation YKFKeyChallengeResponseError

static NSDictionary *errorMap = nil;

+ (YKFKeySessionError *)errorWithCode:(NSUInteger)code {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [YKFKeyChallengeResponseError buildErrorMap];
    });
    
    NSString *errorDescription = errorMap[@(code)];
    if (!errorDescription) {
        return [super errorWithCode:code];
    }
    return [[YKFKeySessionError alloc] initWithCode:code message:errorDescription];
}

+ (void)buildErrorMap {
    errorMap =
    @{@(YKFKeyChallengeResponseErrorCodeNoConnection): YKFKeyChallengeResponseNoConnectionDescription,
      @(YKFKeyChallengeResponseErrorCodeEmptyResponse): YKFKeyChallengeResponseEmptyResponseDescription,
      };
}

@end
