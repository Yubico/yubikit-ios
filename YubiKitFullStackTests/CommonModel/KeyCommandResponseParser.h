//
//  KeyCommandResponseParser.h
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-07-10.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyCommandResponseParser: NSObject

+ (NSUInteger)statusCodeFromData:(NSData *)data;

@end
