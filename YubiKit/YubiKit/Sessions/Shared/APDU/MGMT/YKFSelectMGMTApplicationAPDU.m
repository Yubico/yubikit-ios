//
//  YKFSelectMGMTApplicationAPDU.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFSelectMGMTApplicationAPDU.h"
#import "YKFAPDUCommandInstruction.h"

static const NSUInteger YKFMgmtAIDSize = 8;
static const UInt8 YKFMgmtAID[YKFMgmtAIDSize] = {0xA0, 0x00, 0x00, 0x05, 0x27, 0x47, 0x11, 0x17};

@implementation YKFSelectMGMTApplicationAPDU

- (instancetype)init {
    NSData *data = [NSData dataWithBytes:YKFMgmtAID length:YKFMgmtAIDSize];
    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionSelectApplication p1:0x04 p2:0x00 data:data type:YKFAPDUTypeShort];
}


@end
