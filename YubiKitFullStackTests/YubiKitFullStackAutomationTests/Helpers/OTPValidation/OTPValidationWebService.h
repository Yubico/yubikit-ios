//
//  OTPValidationWebService.h
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTPValidationWebService : NSObject

+ (OTPValidationWebService *)shared;

- (BOOL)validateOTP:(NSString *)otp;

@end
