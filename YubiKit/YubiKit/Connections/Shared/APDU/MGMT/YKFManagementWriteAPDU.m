//
//  YKFManagementWriteAPDU.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementWriteAPDU.h"
#import "YKFAPDUCommandInstruction.h"
#import "YKFManagementInterfaceConfiguration+Private.h"
#import "YKFManagementReadConfigurationTags.h"
#import "YKFNSMutableDataAdditions.h"
#import "YKFAssert.h"

@implementation YKFManagementWriteAPDU

static UInt8 const YKFManagementConfigurationTagsReboot = 0x0c;

- (instancetype)initWithRequest:(nonnull YKFKeyManagementWriteConfigurationRequest *)request {
    YKFAssertAbortInit(request);

    NSMutableData *configData = [[NSMutableData alloc] init];
    YKFManagementInterfaceConfiguration *configuration = request.configuration;
    if (configuration.usbMaskChanged) {
        [configData ykf_appendShortWithTag:YKFManagementReadConfigurationTagsUsbEnabled data:configuration.usbEnabledMask];
    }
    
    if (configuration.nfcMaskChanged) {
        [configData ykf_appendShortWithTag:YKFManagementReadConfigurationTagsNfcEnabled data:configuration.nfcEnabledMask];
    }
    
    if (request.reboot) {
        // specify that device requires reboot (force disconnection of YubiKey)
        [configData ykf_appendByte:YKFManagementConfigurationTagsReboot];
        [configData ykf_appendByte:0];
    }
    
    NSMutableData *rawRequest = [[NSMutableData alloc] init];
    [rawRequest ykf_appendByte:configData.length];
    [rawRequest appendData:configData];

    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionManagementWrite p1:0x00 p2:0x00 data:rawRequest type:YKFAPDUTypeShort];
}

@end
