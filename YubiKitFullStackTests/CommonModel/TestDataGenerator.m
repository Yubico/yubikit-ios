//
//  TestDataGenerator.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-17.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "TestDataGenerator.h"

@implementation TestDataGenerator

- (NSData *)randomDataWithLength:(NSUInteger)length {
    NSAssert(length > 0, @"Invalid size.");
    
    NSMutableData *randomData = [[NSMutableData alloc] initWithCapacity:length];
    for (int i = 0; i < length; ++i) {
        UInt8 randByte = arc4random_uniform(UINT8_MAX);
        [randomData appendBytes:&randByte length:1];
    }
    return randomData;
}

- (NSData *)uniformDataWithRepeatedValue:(UInt8 *)value length:(NSUInteger)length {
    void *buffer = malloc(length);
    if (!buffer) {
        return nil;
    }
    memset(buffer, 0, length);
    NSData *data = [NSData dataWithBytes:buffer length:length];
    free(buffer);
    
    return data;
}

- (NSData *)dataFromHexString:(NSString *)string  {
    NSAssert(string.length % 2 == 0, @"String does not have the right format.");
    NSMutableData* data = [[NSMutableData alloc] init];
    
    for (int i = 0; i < string.length; i += 2) {
        NSString *value = [string substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:value];
        
        unsigned int scannedValue = 0;
        [scanner scanHexInt:&scannedValue];
        
        UInt8 byteValue = scannedValue;
        [data appendBytes:&byteValue length:1];
    }
    
    return data;
}

@end
