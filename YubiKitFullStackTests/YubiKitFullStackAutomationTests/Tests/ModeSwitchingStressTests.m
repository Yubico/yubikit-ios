//
//  ModeSwitchingStressTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-13.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "AutomationTest.h"
#import "TestSharedLogger.h"
#import "OTPValidationWebService.h"

// Smoke tests iterations
static const int ModeSwitchingStressTestsIterations = 5;

@interface ModeSwitchingStressTests: AutomationTest

@property (nonatomic) NSString *lastReceivedOTP;

@end

@implementation ModeSwitchingStressTests

- (void)test_WhenSwitchingBetweenU2FAndOTP_TheKeyProvidesCorrectResults {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenSwitchingBetweenU2FAndOTP -> TheKeyProvidesCorrectResults"];
    
    [self connectKey];
    
    // Wait after connecting the key before generating a OTP
    [AutomationTest waitForTimeInterval: 3];
    
    for (int i = 0; i < ModeSwitchingStressTestsIterations; ++i) {
        [TestSharedLogger.shared logMessage:@"Iteration #%d", i];
        
        [self requestAndValidateOTP];
        [AutomationTest waitForTimeInterval: 4]; // Add a delay to let the key the time to change mode
        
        [self performU2FRegistrationAndSigning];
        [AutomationTest waitForTimeInterval: 4]; // Add a delay to let the key the time to change mode
    }
}

- (void)test_WhenSwitchingBetweenU2FAndOATH_TheKeyProvidesCorrectResults {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenSwitchingBetweenU2FAndOATH -> TheKeyProvidesCorrectResults"];
    
    [self connectKey];
    
    for (int i = 0; i < ModeSwitchingStressTestsIterations; ++i) {
        [TestSharedLogger.shared logMessage:@"Iteration #%d", i];
        
        [self addOATHCredentialToKey];
        [AutomationTest waitForTimeInterval: 4]; // Add a delay to let the key the time to change mode
        
        [self performU2FRegistrationAndSigning];
    }
}

#pragma mark - Helpers

- (void)requestAndValidateOTP {
    [self touchKey];
    
    // A few seconds to get the OTP input and wait for the key to reset.
    [AutomationTest waitForTimeInterval: 6];
    
    NSString *otp = TestSharedLogger.shared.loggingViewController.otp;
    XCTAssert(otp.length, @"No OTP received from the key.");
    XCTAssert(otp.length == 44, @"Yubico OTP received from the key doesn't have the default lenght (44): %@", otp);
    
    if (self.lastReceivedOTP) {
        XCTAssert(![otp isEqualToString:self.lastReceivedOTP], @"A new OTP was not generated.");
    }
    self.lastReceivedOTP = otp;
    
    OTPValidationWebService *validationService = OTPValidationWebService.shared;
    BOOL valid = [validationService validateOTP:otp];
    
    [TestSharedLogger.shared logCondition:valid onSuccess:@"OTP validation successful." onFailure:@"OTP validation failed."];
    XCTAssert(valid, @"The key did not generate a valid Yubico OTP");
}

- (void)addOATHCredentialToKey {
    NSString *oathUrlString = @"otpauth://totp/Yubico:example_totp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
    
    NSURL *oathURL = [[NSURL alloc] initWithString:oathUrlString];
    XCTAssertNotNil(oathURL, @"Could not create URL for the OATH credential string URL.");
    
    YKFOATHCredential *credential = [[YKFOATHCredential alloc] initWithURL:oathURL];
    XCTAssertNotNil(credential, @"Could not create OATH credential from URL.");
    
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    XCTAssertNotNil(oathService, @"Oath service not available.");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [oathService performSelector:NSSelectorFromString(@"invalidateApplicationSelectionCache")];
#pragma clang diagnostic pop
    
    YKFKeyOATHPutRequest *putRequest = [[YKFKeyOATHPutRequest alloc] initWithCredential:credential];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Put expectation."];
    [oathService executePutRequest:putRequest completion:^(NSError * _Nullable error) {
        if (error) {
            return;
        }
        [expectation fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    BOOL success = result == XCTWaiterResultCompleted;
    
    [TestSharedLogger.shared logCondition:success onSuccess:@"OATH credential added." onFailure:@"Could not add OATH credential."];
    XCTAssertTrue(success, @"The credential was not added to the key.");
}

- (void)performU2FRegistrationAndSigning {
    // Perform a registration first to get a key handle
    NSString *keyHandle = [self executeU2FRegisterRequest];
    XCTAssert(keyHandle);
    
    // Perform a signing with the key handle from the registration
    [self executeU2FSignRequestWithKeyHandle:keyHandle];
}

#pragma mark - U2F Request execution helpers

- (NSString *)executeU2FRegisterRequest {
    NSString *challenge = @"D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc";
    NSString *appId = @"https://demo.yubico.com";
    
    return [self executeRegisterRequestWithChallenge:challenge appId:appId];
}

- (void)executeU2FSignRequestWithKeyHandle:(NSString *)keyHandle {
    NSString *challenge = @"D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc";
    NSString *appId = @"https://demo.yubico.com";
    
    [self executeSignRequestWithKeyHandle:keyHandle challenge:challenge appId:appId];
}

@end
