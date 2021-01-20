//
//  YKFVersion.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/6/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFVersion.h"

@interface YKFVersion()

@property (nonatomic, readwrite) UInt8 major;
@property (nonatomic, readwrite) UInt8 minor;
@property (nonatomic, readwrite) UInt8 micro;

@end

@implementation YKFVersion

- (instancetype)initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro {
    self = [super init];
    if (self) {
        self.major = major;
        self.minor = minor;
        self.micro = micro;
    }
    return self;
}

@end
