//
//  YKFMGMTWriteAPDU.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFMGMTWriteAPDU.h"
#import "YKFAPDUCommandInstruction.h"
#import "YKFKeyMGMTWriteConfigurationRequest.h"

@implementation YKFMGMTWriteAPDU

- (instancetype)initWithRequest:(nonnull YKFKeyMGMTWriteConfigurationRequest *)request {
    // TODO: put data
    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionMGMTWrite p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
}

@end
