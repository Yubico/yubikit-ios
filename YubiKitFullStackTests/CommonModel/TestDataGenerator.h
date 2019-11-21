//
//  TestDataGenerator.h
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-17.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestDataGenerator : NSObject

- (NSData *)randomDataWithLength:(NSUInteger)length;
- (NSData *)uniformDataWithRepeatedValue:(UInt8 *)value length:(NSUInteger)length;

- (NSData *)dataFromHexString:(NSString *)string;

@end
