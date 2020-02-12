//
//  YKFKeyVersion.h
//  YubiKit
//
//  Created by Irina Makhalova on 2/6/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Class represents firmware version of YubiKey
 */
@interface YKFKeyVersion : NSObject

@property (nonatomic, readonly) UInt8 major;
@property (nonatomic, readonly) UInt8 minor;
@property (nonatomic, readonly) UInt8 micro;

- (instancetype)initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
