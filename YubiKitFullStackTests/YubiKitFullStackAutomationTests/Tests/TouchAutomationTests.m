//
//  TouchAutomationTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2019-08-02.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AutomationTest.h"
#import "TestSharedLogger.h"

@interface TouchAutomationTests: AutomationTest
@end

@implementation TouchAutomationTests

- (void)test_WhenTouchForCCIDIsRequired_KeyHandlesTheTouch {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenTouchForCCIDIsRequired -> KeyHandlesTheTouch"];
    
    [self connectKey];
    
    id<YKFKeyRawCommandServiceProtocol> rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    XCTAssertNotNil(rawCommandService, @"Raw command service not available.");

    // Select the management application to test the touch
    
    static const NSUInteger aidSize = 8;
    static const UInt8 aid[aidSize] = {0xA0, 0x00, 0x00, 0x05, 0x27, 0x47, 0x11, 0x17};
    NSData *data = [NSData dataWithBytes:aid length:aidSize];
    YKFAPDU *selectAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:data type:YKFAPDUTypeShort];
    
    __block BOOL success = NO;
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Select expectation."];
    [rawCommandService executeCommand:selectAPDU completion:^(NSData *response, NSError *error) {
        if (!error) {
            success = YES;
        }
        [expectation fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    success = result == XCTWaiterResultCompleted;
    
    if (success) {
        [TestSharedLogger.shared logSuccess:@"Management application successfully selected."];
    } else {
        [TestSharedLogger.shared logError:@"Could not select the management application."];
    }
    XCTAssert(success, @"Could not select the management application.");
    
    // Execute the touch test APDU
    
    YKFAPDU *touchTestAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0x06 p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
    
    success = NO;
    expectation = [[XCTestExpectation alloc] initWithDescription:@"Touch expectation."];
    [rawCommandService executeCommand:touchTestAPDU completion:^(NSData *response, NSError *error) {
        if (!error) {
            success = YES;
        }
        [expectation fulfill];
    }];
    
    // Touch the key
    
    [self touchKey];
    
    result = [XCTWaiter waitForExpectations:@[expectation] timeout:5];
    success = result == XCTWaiterResultCompleted;
    
    // Check for touch successfully detected (no timeouts)
    
    if (success) {
        [TestSharedLogger.shared logSuccess:@"The touch was successfully detected."];
    } else {
        [TestSharedLogger.shared logError:@"The touch was not detected."];
    }
    XCTAssert(success, @"The touch was not detected.");
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

@end
