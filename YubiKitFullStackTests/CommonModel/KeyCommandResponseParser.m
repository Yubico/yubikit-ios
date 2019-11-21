//
//  KeyCommandResponseParser.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-07-10.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <YubiKit/YubiKit.h>
#import <YubiKit/Helpers/Additions/YKFNSDataAdditions+Private.h>
#import "KeyCommandResponseParser.h"

@implementation KeyCommandResponseParser

+ (NSUInteger)statusCodeFromData:(NSData *)data {
    return [data ykf_getBigEndianIntegerInRange:NSMakeRange([data length] - 2, 2)];
}

@end
