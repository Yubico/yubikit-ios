//
//  YKFManagementReadAPDU.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementReadAPDU.h"
#import "YKFAPDUCommandInstruction.h"

@implementation YKFManagementReadAPDU

- (instancetype)init {
    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionManagementRead p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
}

@end
