//
//  YKFKeyMGMTError.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTError.h"
#import "YKFKeySessionError+Private.h"

static NSString* const YKFKeyMGMTErrorCodeUnexpectedResponseDescription = @"Invalid response returned";

@implementation YKFKeyMGMTError

static NSDictionary *errorMap = nil;

+ (YKFKeySessionError *)errorWithCode:(NSUInteger)code {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [YKFKeyMGMTError buildErrorMap];
    });
    
    NSString *errorDescription = errorMap[@(code)];
    if (!errorDescription) {
        return [super errorWithCode:code];
    }
    return [[YKFKeySessionError alloc] initWithCode:code message:errorDescription];
}

+ (void)buildErrorMap {
    errorMap = @{@(YKFKeyMGMTErrorCodeUnexpectedResponse): YKFKeyMGMTErrorCodeUnexpectedResponseDescription };
}

@end
