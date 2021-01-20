//
//  YKFManagementError.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/10/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementError.h"
#import "YKFSessionError+Private.h"

static NSString* const YKFManagementErrorCodeUnexpectedResponseDescription = @"Invalid response returned";

@implementation YKFManagementError

static NSDictionary *errorMap = nil;

+ (YKFSessionError *)errorWithCode:(NSUInteger)code {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [YKFManagementError buildErrorMap];
    });
    
    NSString *errorDescription = errorMap[@(code)];
    if (!errorDescription) {
        return [super errorWithCode:code];
    }
    return [[YKFSessionError alloc] initWithCode:code message:errorDescription];
}

+ (void)buildErrorMap {
    errorMap = @{@(YKFManagementErrorCodeUnexpectedResponse): YKFManagementErrorCodeUnexpectedResponseDescription };
}

@end
