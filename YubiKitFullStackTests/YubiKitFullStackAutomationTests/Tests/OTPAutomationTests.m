//
//  OTPAutomationTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "AutomationTest.h"
#import "OTPValidationWebService.h"
#import "TestSharedLogger.h"

#import "LoggingViewController.h"

// Smoke tests iterations
static const int OTPAutomationTestsOtpGenerationIterations = 20;

@interface OTPAutomationTests: AutomationTest
@end

@implementation OTPAutomationTests

- (void)test_WhenKeyIsTouched_AValidYubicoOTPIsGenerated {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenKeyIsTouched -> ValidYubicoOTPIsGenerated"];
    
    [self connectKey];
    
    // Wait after connecting the key before generating a OTP
    [AutomationTest waitForTimeInterval: 2];
    
    [self touchKey];

    [AutomationTest waitForTimeInterval: 6];
    
    NSString *otp = TestSharedLogger.shared.loggingViewController.otp;
    XCTAssert(otp.length, @"No OTP received from the key.");
    
    OTPValidationWebService *validationService = OTPValidationWebService.shared;
    BOOL valid = [validationService validateOTP:otp];
    
    [TestSharedLogger.shared logCondition:valid onSuccess:@"OTP validation successful." onFailure:@"OTP validation failed."];
    XCTAssert(valid, @"The key did not generate a valid Yubico OTP");
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

- (void)test_WhenRequestingMultipleOTPs_ValidYubicoOTPsAreGenerated {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenRequestingMultipleOTPs -> ValidYubicoOTPsAreGenerated"];
    
    [self connectKey];
    
    // Wait after connecting the key before generating a OTP
    [AutomationTest waitForTimeInterval: 2];
    
    NSString *lastReceivedOTP = nil;
    
    for (int i = 0; i < OTPAutomationTestsOtpGenerationIterations; ++i) {
        [TestSharedLogger.shared logMessage:@"Iteration %d", i];
        
        [self touchKey];
        [AutomationTest waitForTimeInterval: 6];
        
        NSString *otp = TestSharedLogger.shared.loggingViewController.otp;
        XCTAssert(otp.length, @"No OTP received from the key.");
        
        if (lastReceivedOTP) {
            BOOL newOTPGenerated = ![lastReceivedOTP isEqualToString:otp];
            
            XCTAssert(newOTPGenerated, @"The key did not generate a new otp after touch. Iteration %d", i);
            [TestSharedLogger.shared logCondition:newOTPGenerated onSuccess:@"New OTP generated." onFailure:@"A new OTP was not generated."];
            
            continue;
        }
        lastReceivedOTP = otp;
        
        OTPValidationWebService *validationService = OTPValidationWebService.shared;
        BOOL isValidOTP = [validationService validateOTP:otp];
        
        [TestSharedLogger.shared logCondition:isValidOTP onSuccess:@"OTP validation successful." onFailure:@"OTP validation failed."];
        
        XCTAssert(isValidOTP, @"The key did not generate a valid Yubico OTP at iteration %d: %@", i, otp);
        XCTAssert(otp.length == 44, @"The length of the OTP is not the default length. Length %lu", otp.length);
        
        if (!isValidOTP) {
            break; // Leave the loop on first failure.
        }
    }
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

@end
