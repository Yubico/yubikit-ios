//
//  OTPUIResponder.h
//  YubiKitFullStackManualTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTPUIResponder;
@protocol OTPUIResponderDelegate<NSObject>

- (void)otpUIResponderDidStartReadingOTP:(OTPUIResponder *)responder;
- (void)otpUIResponder:(OTPUIResponder *)responder didReadOTP:(NSString *)otp;

@end

@interface OTPUIResponder : UIView

@property (nonatomic, weak) id<OTPUIResponderDelegate> delegate;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end
