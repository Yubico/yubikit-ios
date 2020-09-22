//
//  YKFMGMTReadAPDU.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFMGMTReadAPDU.h"
#import "YKFAPDUCommandInstruction.h"

@implementation YKFMGMTReadAPDU

- (instancetype)init {
    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionMGMTRead p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
}

@end
