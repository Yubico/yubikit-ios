//
//  YKFKeyMGMTSelectApplicationResponse.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTSelectApplicationResponse.h"
#import "YKFKeyMGMTSelectApplicationResponse+Private.h"
#import "YKFKeyVersion.h"
#import "YKFAssert.h"

@interface YKFKeyMGMTSelectApplicationResponse()

@property (nonatomic, readwrite, nonnull) YKFKeyVersion *version;

@end

@implementation YKFKeyMGMTSelectApplicationResponse

static NSUInteger const MinFirmwareVersionStringSize = 5; // e.g. "5.2.3"

- (nullable instancetype)initWithKeyResponseData:(nonnull NSData *)responseData {
    YKFAssertAbortInit(responseData.length);
    
    self = [super init];
    if (self) {
        // Parses version from string format "Firmware version 5.2.1"
        YKFAssertAbortInit(responseData.length > MinFirmwareVersionStringSize);

        NSString *responseString = [[NSString alloc] initWithBytes:responseData.bytes length:responseData.length encoding:NSASCIIStringEncoding];
        NSArray *responseArray = [responseString componentsSeparatedByString:@" "];

        YKFAssertAbortInit(responseArray.count > 0);
        NSString *versionString = responseArray.lastObject;

        NSArray *versionArray = [versionString componentsSeparatedByString:@"."];
        YKFAssertAbortInit(versionArray.count == 3)
        
        NSUInteger major = [versionArray[0] intValue];
        NSUInteger minor = [versionArray[1] intValue];
        NSUInteger micro = [versionArray[2] intValue];

        self.version = [[YKFKeyVersion alloc] initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro];
    }
    return self;
}

@end
