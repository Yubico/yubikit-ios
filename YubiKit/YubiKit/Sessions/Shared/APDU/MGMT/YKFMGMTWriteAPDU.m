//
//  YKFMGMTWriteAPDU.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFMGMTWriteAPDU.h"
#import "YKFAPDUCommandInstruction.h"
#import "YKFMGMTInterfaceConfiguration+Private.h"
#import "YKFMGMTReadConfigurationTags.h"
#import "YKFNSMutableDataAdditions.h"
#import "YKFAssert.h"

@implementation YKFMGMTWriteAPDU

- (instancetype)initWithRequest:(nonnull YKFKeyMGMTWriteConfigurationRequest *)request {
    YKFAssertAbortInit(request);

    NSMutableData *rawRequest = [[NSMutableData alloc] init];
    YKFMGMTInterfaceConfiguration *configuration = request.configuration;
    if (configuration.usbMaskChanged) {
        [rawRequest ykf_appendShortWithTag:YKFMGMTReadConfigurationTagsUsbEnabled data:configuration.usbEnabledMask];
    }
    
    if (configuration.nfcMaskChanged) {
        [rawRequest ykf_appendShortWithTag:YKFMGMTReadConfigurationTagsUsbEnabled data:configuration.nfcEnabledMask];
    }

    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionMGMTWrite p1:0x00 p2:0x00 data:rawRequest type:YKFAPDUTypeShort];
}

@end
