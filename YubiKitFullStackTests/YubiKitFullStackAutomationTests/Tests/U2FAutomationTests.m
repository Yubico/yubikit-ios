//
//  U2FAutomationTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-06-25.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YubiKit/YubiKit.h>

#import "TestSharedLogger.h"
#import "AutomationTest.h"
#import "MoLYService.h"

// Smoke tests iterations
static const int U2FAutomationTestsRegistrationIterations = 5;
static const int U2FAutomationTestsSignIterations = 5;

@interface U2FAutomationTests: AutomationTest
@end

@implementation U2FAutomationTests

- (void)test_WhenRequestingRegistration_KeyHandlesTheRequest {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenRequestingRegistration -> KeyHandlesTheRequest"];
    
    [self connectKey];
    
    NSString *keyHandle = [self executeRegisterRequest];
    XCTAssert(keyHandle);
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

- (void)test_WhenRequestingSigning_KeyHandlesTheRequest {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenRequestingSigning -> KeyHandlesTheRequest."];
    
    [self connectKey];
        
    // Perform a registration first to get a key handle
    NSString *keyHandle = [self executeRegisterRequest];
    XCTAssert(keyHandle);
    
    // Perform a signing with the key handle from the registration
    [self executeSignRequestWithKeyHandle:keyHandle];
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

#pragma mark - Stress tests

- (void)test_WhenRequestingRegistrationMultipleTimes_KeyHandlesTheRequests {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenRequestingRegistrationMultipleTimes -> KeyHandlesTheRequests"];
    
    [self connectKey];
    
    for (int i = 0; i < U2FAutomationTestsRegistrationIterations; ++i) {
        [TestSharedLogger.shared logMessage:@"Iteration #%d", i];
        [self executeRegisterRequest];
    }
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

- (void)test_WhenRequestingSigningMultipleTimes_KeyHandlesTheRequests {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenRequestingSigningMultipleTimes -> KeyHandlesTheRequests"];
    
    [self connectKey];
        
    for (int i = 0; i < U2FAutomationTestsSignIterations; ++i) {
        [TestSharedLogger.shared logMessage:@"Iteration #%d", i];
        
        // Perform a registration first to get a key handle
        NSString *keyHandle = [self executeRegisterRequest];
        XCTAssert(keyHandle);
        
        // Perform a signing with the key handle from the registration
        [self executeSignRequestWithKeyHandle:keyHandle];
    }
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

#pragma mark - Request execution helpers

- (NSString *)executeRegisterRequest {
    NSString *challenge = @"D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc";
    NSString *appId = @"https://demo.yubico.com";
    
    return [self executeRegisterRequestWithChallenge:challenge appId:appId];
}

- (void)executeSignRequestWithKeyHandle:(NSString *)keyHandle {
    NSString *challenge = @"D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc";
    NSString *appId = @"https://demo.yubico.com";
    
    [self executeSignRequestWithKeyHandle:keyHandle challenge:challenge appId:appId];
}

@end
