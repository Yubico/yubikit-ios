//
//  YKFInvalidPinError.h
//  YubiKit
//
//  Created by Jens Utbult on 2024-06-19.
//  Copyright © 2024 Yubico. All rights reserved.
//

#ifndef YKFInvalidPinError_h
#define YKFInvalidPinError_h

extern NSString* const YKFInvalidPinErrorDomain;
extern NSInteger const YKFInvalidPinErrorCode;

@interface YKFInvalidPinError: NSError

@property (nonatomic, readonly) int retries;

+ (instancetype)invalidPinErrorWithRetries:(int)retries;

@end
#endif /* YKFInvalidPinError_h */
