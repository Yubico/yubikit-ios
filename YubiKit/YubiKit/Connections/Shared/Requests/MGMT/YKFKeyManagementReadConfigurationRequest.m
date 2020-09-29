//
//  YKFKeyManagementReadConfigurationRequest.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyManagementReadConfigurationRequest.h"
#import "YKFKeyManagementRequest+Private.h"
#import "YKFManagementReadAPDU.h"

@implementation YKFKeyManagementReadConfigurationRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        self.apdu = [[YKFManagementReadAPDU alloc] init];
    }
    return self;
}

@end
