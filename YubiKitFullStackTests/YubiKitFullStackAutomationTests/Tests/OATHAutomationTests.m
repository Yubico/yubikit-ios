//
//  OATHAutomationTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-10-26.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YubiKit/YubiKit.h>

#import "TestSharedLogger.h"
#import "AutomationTest.h"

@interface OATHAutomationTests: AutomationTest
@end

@implementation OATHAutomationTests

+ (void)setUp {
    [super setUp];
    [self resetApplication];
}

#pragma mark - Add Credentials

- (void)test_WhenAddingTOTPCredential_TheCredentialIsAddedToTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenAddingTOTPCredential -> TheCredentialIsAddedToTheKey"];
    
    [self connectKey];

    NSString *oathUrlString = @"otpauth://totp/Yubico:example_totp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredential *credential = [self credentialWithURLString:oathUrlString];
    
    [self addCredentialToKey:credential];
}

- (void)test_WhenAddingHOTPCredential_TheCredentialIsAddedToTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenAddingTOTPCredential -> TheCredentialIsAddedToTheKey"];
    
    [self connectKey];
    
    NSString *oathUrlString = @"otpauth://hotp/Yubico:example_hotp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&counter=123";
    YKFOATHCredential *credential = [self credentialWithURLString:oathUrlString];
    
    [self addCredentialToKey:credential];
}

- (void)test_WhenAddingMultipleTimeTheSameCredential_TheCredentialIsOverridedOnTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenAddingMultipleTimeTheSameCredential -> TheCredentialIsOverridedOnTheKey"];
    
    [self connectKey];
    
    NSString *oathUrlString = @"otpauth://hotp/Yubico:example_hotp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&counter=123";
    YKFOATHCredential *credential = [self credentialWithURLString:oathUrlString];
    
    [self addCredentialToKey:credential];
    [self addCredentialToKey:credential];
}

#pragma mark - Delete Credentials

- (void)test_WhenDeletingCredential_TheCredentialIsRemovedFromTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenDeletingCredential -> TheCredentialIsRemovedFromTheKey"];
    
    [self connectKey];
    
    NSString *oathUrlString = @"otpauth://hotp/Yubico:example_hotp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&counter=123";
    YKFOATHCredential *credential = [self credentialWithURLString:oathUrlString];
    
    [self addCredentialToKey:credential];
    [self deleteCredentialFromTheKey:credential];
}

#pragma mark - Calculate Credentials

- (void)test_WhenCalculatingCredential_OTPIsReceived {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenCalculatingCredential -> OTPIsReceived"];
    
    [self connectKey];
    
    NSString *oathUrlString = @"otpauth://hotp/Yubico:example_hotp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&counter=123";
    YKFOATHCredential *credential = [self credentialWithURLString:oathUrlString];
    
    [self addCredentialToKey:credential];
    YKFKeyOATHCalculateResponse *calculateResponse = [self calculateCredential:credential];
    
    XCTAssertNotNil(calculateResponse.otp, @"Calculate request did not return an OTP.");
    XCTAssert(calculateResponse.otp.length == 6, @"The calculate OTP has the wrong length.");
}

#pragma mark - Listing Credentials

- (void)test_WhenListingCredentials_TheResultContainsCredentials {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenListingCredentials -> TheResultContainsCredentials"];
    
    [self connectKey];
    
    NSString *oathUrlString = @"otpauth://totp/Yubico:example_totp@yubico.com?"
                               "secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredential *credential = [self credentialWithURLString:oathUrlString];
    
    [self addCredentialToKey:credential];
    YKFKeyOATHListResponse *listResponse = [self listCredentials];
    
    XCTAssert(listResponse.credentials.count > 0, @"List response does not return credentials.");
}

#pragma mark - Helpers

- (YKFOATHCredential *)credentialWithURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    XCTAssertNotNil(url, @"Invalid OATH URL");
    
    YKFOATHCredential *credential = [[YKFOATHCredential alloc] initWithURL:url];
    XCTAssertNotNil(credential, @"Could not create OATH credential.");

    return credential;
}

- (void)addCredentialToKey:(YKFOATHCredential *)credential {
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    XCTAssertNotNil(oathService, @"Oath service not available.");
    
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
    
    XCTAssertTrue(success, @"The credential was not added to the key.");
}

- (void)deleteCredentialFromTheKey:(YKFOATHCredential *)credential {
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    XCTAssertNotNil(oathService, @"Oath service not available.");
    
    YKFKeyOATHDeleteRequest *deleteRequest = [[YKFKeyOATHDeleteRequest alloc] initWithCredential:credential];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Delete expectation."];
    [oathService executeDeleteRequest:deleteRequest completion:^(NSError * _Nullable error) {
        if (error) {
            return;
        }
        [expectation fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    BOOL success = result == XCTWaiterResultCompleted;
    
    XCTAssertTrue(success, @"The credential was not removed from the key.");
}

- (YKFKeyOATHListResponse *)listCredentials {
    __block YKFKeyOATHListResponse *listResponse = nil;
    
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    NSAssert(oathService, @"Oath service not available.");
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"List expectation."];
    [oathService executeListRequestWithCompletion:^(YKFKeyOATHListResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return;
        }
        listResponse = response;
        [expectation fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    BOOL success = result == XCTWaiterResultCompleted;
    
    NSAssert(success, @"Could not list the credentials on the OATH application.");
    
    return listResponse;
}

- (YKFKeyOATHCalculateResponse *)calculateCredential:(YKFOATHCredential *)credential {
    __block YKFKeyOATHCalculateResponse *calculateResponse = nil;
    
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    NSAssert(oathService, @"Oath service not available.");
    
    YKFKeyOATHCalculateRequest *calculateRequest = [[YKFKeyOATHCalculateRequest alloc] initWithCredential:credential];
    XCTAssertNotNil(calculateRequest, @"Could not create calculate request from credential.");
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Calculate expectation."];
    [oathService executeCalculateRequest:calculateRequest completion:^(YKFKeyOATHCalculateResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return;
        }
        calculateResponse = response;
        [expectation fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    BOOL success = result == XCTWaiterResultCompleted;
    NSAssert(success, @"Could not calculate the credential.");
    
    return calculateResponse;
}

// Called before executing the tests
+ (BOOL)resetApplication {
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Reset expectation."];
    [oathService executeResetRequestWithCompletion:^(NSError * _Nullable error) {
        [expectation fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:10];
    return result == XCTWaiterResultCompleted;
}

@end
