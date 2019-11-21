//
//  RawCommandAutomationTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-12-03.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YubiKit/YubiKit.h>

#import "AutomationTest.h"
#import "TestSharedLogger.h"

@interface RawCommandAutomationTests: AutomationTest
@end

@implementation RawCommandAutomationTests

#pragma mark - Async Tests

- (void)test_WhenUsingTheRawCommandInterface_CommandsCanBeExecutedAgainstTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenUsingTheRawCommandInterface -> ApplicationsCanBeSelected"];
    
    [self connectKey];
    
    YKFKeyRawCommandService *rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    XCTAssertNotNil(rawCommandService, @"Raw Command Service not available.");

    // Select the PIV Application
    
    char appId[] = {0xA0, 0x00, 0x00, 0x03, 0x08};
    NSData *appIDData = [NSData dataWithBytes:appId length:5];
    
    YKFAPDU *selectPivAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:appIDData type:YKFAPDUTypeShort];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Application selection."];
    
    [rawCommandService executeCommand:selectPivAPDU completion:^(NSData *response, NSError *error) {
        if (error || (!error && !response)) {
            return;
        }
        
        UInt16 statusCode = [self statusCodeFromKeyResponse:response];
        XCTAssertEqual(statusCode, 0x9000, @"Error status code returned by the key.");
        
        [expectation fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    XCTAssert(result == XCTWaiterResultCompleted, @"Async raw command application selection failed.");
    
    // Verify
    
    expectation = [[XCTestExpectation alloc] initWithDescription:@"Verify command."];
    
    char verifyCommand[] = {0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff};
    NSData *verifyData = [NSData dataWithBytes:verifyCommand length:8];
    YKFAPDU *verifyApdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x20 p1:0x00 p2:0x80 data:verifyData type:YKFAPDUTypeShort];
    
    [rawCommandService executeCommand:verifyApdu completion:^(NSData *response, NSError *error) {
        if (error || (!error && !response)) {
            return;
        }
        
        UInt16 statusCode = [self statusCodeFromKeyResponse:response];
        XCTAssertEqual(statusCode, 0x9000, @"Error status code returned by the key.");
        
        [expectation fulfill];
    }];

    result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    XCTAssert(result == XCTWaiterResultCompleted, @"Async verify command failed.");
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

#pragma mark - Sync Tests

- (void)test_WhenUsingTheSyncRawCommandInterface_CommandsCanBeExecutedAgainstTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenUsingTheSyncRawCommandInterface -> ApplicationsCanBeSelected"];
    
    [self connectKey];

    YKFKeyRawCommandService *rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    XCTAssertNotNil(rawCommandService, @"Raw Command Service not available.");

    // Select the PIV Application
    
    [TestSharedLogger.shared logMessage:@"Selecting the PIV application..."];
    
    char appId[] = {0xA0, 0x00, 0x00, 0x03, 0x08};
    NSData *appIDData = [NSData dataWithBytes:appId length:5];
    
    YKFAPDU *selectPivAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:appIDData type:YKFAPDUTypeShort];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Application selection."];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        [rawCommandService executeSyncCommand:selectPivAPDU completion:^(NSData *response, NSError *error) {
            XCTAssertNil(error, @"Error returned when selcting the PIV application on the key.");
            XCTAssertNotNil(response, @"Empty response when selecting the application.");
            
            UInt16 statusCode = [self statusCodeFromKeyResponse:response];
            XCTAssertEqual(statusCode, 0x9000, @"Error status code returned by the key.");
        }];
        
        [expectation fulfill];
    });
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    XCTAssert(result == XCTWaiterResultCompleted, @"Sync raw command application selection failed.");
    
    // Verify

    [TestSharedLogger.shared logMessage:@"Sending a verify command..."];
    
    expectation = [[XCTestExpectation alloc] initWithDescription:@"Verify command."];
    
    char verifyCommand[] = {0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff};
    NSData *verifyData = [NSData dataWithBytes:verifyCommand length:8];
    YKFAPDU *verifyApdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x20 p1:0x00 p2:0x80 data:verifyData type:YKFAPDUTypeShort];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        [rawCommandService executeSyncCommand:verifyApdu completion:^(NSData *response, NSError *error) {
            XCTAssertNil(error, @"Error returned when running verify against the key PIV application.");
            
            UInt16 statusCode = [self statusCodeFromKeyResponse:response];
            XCTAssertEqual(statusCode, 0x9000, @"Error status code returned by the key.");
        }];
        
        [expectation fulfill];
    });
    
    result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    XCTAssert(result == XCTWaiterResultCompleted, @"Sync verify command failed.");
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

#pragma mark - Helpers

- (UInt16)statusCodeFromKeyResponse:(NSData *)response {
    XCTAssertNotNil(response, @"Nil response when parsing the status code.");
    XCTAssert(response.length >= 2, @"Key response data is too short.");
    
    UInt8 *bytePtr = (UInt8 *)response.bytes;
    
    UInt8 msb = bytePtr[response.length - 2];
    UInt8 lsb = bytePtr[response.length - 1];
    
    return ((UInt16)msb << 8) + lsb;
}

@end
