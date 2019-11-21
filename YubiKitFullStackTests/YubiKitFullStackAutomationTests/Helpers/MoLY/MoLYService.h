//
//  MoLYService.h
//  YubiKitFullStackManualTests
//
//  Created by Conrad Ciobanica on 2018-06-19.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoLYService : NSObject

// This property disables the service to run a test on a local device with a key attached to it.
@property (nonatomic, assign) BOOL disabled;

+ (MoLYService *)shared;

- (BOOL)plugin;
- (BOOL)plugout;

- (BOOL)touch;

@end
