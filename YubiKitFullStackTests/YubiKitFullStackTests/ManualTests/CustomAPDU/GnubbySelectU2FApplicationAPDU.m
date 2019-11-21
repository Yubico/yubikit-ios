//
//  GnubbySelectU2FApplicationAPDU.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-24.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "GnubbySelectU2FApplicationAPDU.h"

@implementation GnubbySelectU2FApplicationAPDU

static const UInt8 commandSelectApplication = 0xA4;
static const NSUInteger applicationIdSize = 8;
static const UInt8 gnubbyU2FApplicationId[applicationIdSize] = {0xA0, 0x00, 0x00, 0x05, 0x27, 0x10, 0x02, 0x01};

- (instancetype)init {
    NSData *data = [NSData dataWithBytes:gnubbyU2FApplicationId length:applicationIdSize];
    return [super initWithCla:0x00 ins:commandSelectApplication p1:0x04 p2:0x0C data:data type:YKFAPDUTypeShort];
}

@end
