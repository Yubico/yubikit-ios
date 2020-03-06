//
//  YKFKeyMGMTWriteConfigurationRequest.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTWriteConfigurationRequest.h"
#import "YKFKeyMGMTRequest+Private.h"
#import "YKFAssert.h"
#import "YKFMGMTWriteAPDU.h"

@interface YKFKeyMGMTWriteConfigurationRequest()

@property (nonatomic, readwrite) YKFMGMTInterfaceConfiguration *configuration;

@end

@implementation YKFKeyMGMTWriteConfigurationRequest

@synthesize reboot = _reboot;

- (instancetype)initWithConfiguration:(nonnull YKFMGMTInterfaceConfiguration*) configuration withReboot: (BOOL) withReboot {
    YKFAssertAbortInit(configuration);
    
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.reboot = withReboot;
        self.apdu = [[YKFMGMTWriteAPDU alloc] initWithRequest:self];
    }
    return self;
}

@end
