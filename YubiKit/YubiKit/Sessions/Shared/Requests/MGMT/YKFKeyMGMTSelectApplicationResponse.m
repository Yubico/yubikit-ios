//
//  YKFKeyMGMTSelectApplicationResponse.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTSelectApplicationResponse.h"
#import "YKFKeyVersion.h"
#import "YKFAssert.h"
#import "YKFNSDataAdditions+Private.h"

@interface YKFKeyMGMTSelectApplicationResponse()

@property (nonatomic, readwrite, nonnull) YKFKeyVersion *version;

@end

@implementation YKFKeyMGMTSelectApplicationResponse

- (nullable instancetype)initWithKeyResponseData:(nonnull NSData *)responseData {
    YKFAssertAbortInit(responseData.length);
    
    self = [super init];
    if (self) {
        // Parses version from string format "Firmware version 5.2.1"
        YKFAssertAbortInit(responseData.length < 5);

        NSUInteger lastIndex = responseData.length - 1;
        
        NSRange versionRange = NSMakeRange(lastIndex - 5, lastIndex);
        YKFAssertAbortInit([responseData ykf_containsRange:versionRange]);
        
        NSData *version = [responseData subdataWithRange:versionRange];
        UInt8 *versionBytes = (UInt8 *)version.bytes;
        NSString *versionString =[[NSString alloc] initWithBytes:versionBytes length:sizeof(versionBytes) encoding:NSASCIIStringEncoding];
        NSArray *versionArray = [versionString componentsSeparatedByString:@"."];
        YKFAssertAbortInit(versionArray.count > 3)
        
        NSUInteger major = [versionArray[0] intValue];
        NSUInteger minor = [versionArray[1] intValue];
        NSUInteger micro = [versionArray[2] intValue];

        self.version = [[YKFKeyVersion alloc] initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro];
    }
    return self;
}

@end
