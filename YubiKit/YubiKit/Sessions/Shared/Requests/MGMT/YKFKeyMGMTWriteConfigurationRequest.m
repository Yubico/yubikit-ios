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
@property (nonatomic, readwrite) BOOL reboot;

@end

@implementation YKFKeyMGMTWriteConfigurationRequest

- (instancetype)initWithConfiguration:(nonnull YKFMGMTInterfaceConfiguration*) configuration reboot: (BOOL) reboot {
    YKFAssertAbortInit(configuration);
    
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.reboot = reboot;
        self.apdu = [[YKFMGMTWriteAPDU alloc] initWithRequest:self];
    }
    return self;
}

@end
