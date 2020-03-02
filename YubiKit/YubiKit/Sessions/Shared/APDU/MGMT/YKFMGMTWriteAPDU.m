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

static UInt8 const YKFMGMTConfigurationTagsReboot = 0x0c;

- (instancetype)initWithRequest:(nonnull YKFKeyMGMTWriteConfigurationRequest *)request {
    YKFAssertAbortInit(request);

    NSMutableData *configData = [[NSMutableData alloc] init];
    YKFMGMTInterfaceConfiguration *configuration = request.configuration;
    if (configuration.usbMaskChanged) {
        [configData ykf_appendShortWithTag:YKFMGMTReadConfigurationTagsUsbEnabled data:configuration.usbEnabledMask];
    }
    
    if (configuration.nfcMaskChanged) {
        [configData ykf_appendShortWithTag:YKFMGMTReadConfigurationTagsNfcEnabled data:configuration.nfcEnabledMask];
    }
    
    if (request.reboot) {
        // specify that device requires reboot (force disconnection of YubiKey)
        [configData ykf_appendByte:YKFMGMTConfigurationTagsReboot];
        [configData ykf_appendByte:0];
    }
    
    NSMutableData *rawRequest = [[NSMutableData alloc] init];
    [rawRequest ykf_appendByte:configData.length];
    [rawRequest appendData:configData];

    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionMGMTWrite p1:0x00 p2:0x00 data:rawRequest type:YKFAPDUTypeShort];
}

@end
