//
//  YKFKeyManagementWriteConfigurationRequest.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyManagementWriteConfigurationRequest.h"
#import "YKFKeyManagementRequest+Private.h"
#import "YKFAssert.h"
#import "YKFManagementWriteAPDU.h"

@interface YKFKeyManagementWriteConfigurationRequest()

@property (nonatomic, readwrite) YKFManagementInterfaceConfiguration *configuration;
@property (nonatomic, readwrite) BOOL reboot;

@end

@implementation YKFKeyManagementWriteConfigurationRequest

- (instancetype)initWithConfiguration:(nonnull YKFManagementInterfaceConfiguration*) configuration reboot: (BOOL) reboot {
    YKFAssertAbortInit(configuration);
    
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.reboot = reboot;
        self.apdu = [[YKFManagementWriteAPDU alloc] initWithRequest:self];
    }
    return self;
}

@end
