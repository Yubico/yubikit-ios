//
//  YKFKeyMGMTReadConfigurationRequest.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTReadConfigurationRequest.h"
#import "YKFKeyMGMTRequest+Private.h"
#import "YKFMGMTReadAPDU.h"

@implementation YKFKeyMGMTReadConfigurationRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        self.apdu = [[YKFMGMTReadAPDU alloc] init];
    }
    return self;
}

@end
