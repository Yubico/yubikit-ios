//
//  PCSCAutomationTests.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-12-05.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YubiKit/YubiKit.h>

#import "AutomationTest.h"
#import "TestSharedLogger.h"

@interface PCSCAutomationTests: AutomationTest
@end

@implementation PCSCAutomationTests

- (void)test_WhenUsingThePCSCInterface_CommandsCanBeExecutedAgainstTheKey {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenUsingThePCSCInterface -> CommandsCanBeExecutedAgainstTheKey"];
    
    [self connectKey];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"PCSC execution expectation."];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        SInt32 context = 0;
        SInt64 result = YKF_SCARD_S_SUCCESS;
        SInt32 card = 0;
        UInt32 activeProtocol = YKF_SCARD_PROTOCOL_T1;

        // Get the context.
        
        [TestSharedLogger.shared logMessage:@"Getting context..."];
        
        result = YKFSCardEstablishContext(YKF_SCARD_SCOPE_USER, nil, nil, &context);
        XCTAssertEqual(result, YKF_SCARD_S_SUCCESS, @"Could not create context.");
        
        // Connect the key.
        
        [TestSharedLogger.shared logMessage:@"Opening the key session..."];
        
        result = YKFSCardConnect(context, "", YKF_SCARD_SHARE_EXCLUSIVE, YKF_SCARD_PROTOCOL_T1, &card, &activeProtocol);
        XCTAssertEqual(result, YKF_SCARD_S_SUCCESS, @"Could not connect to the key.");
        
        // Send a select PIV application from the key.
        
        [TestSharedLogger.shared logMessage:@"Selecting the PIV application..."];
        
        UInt8 command[] = {0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08};
        UInt8 *response = malloc(UINT8_MAX + 2);
        UInt32 responseLength = UINT8_MAX + 2;
        
        result = YKFSCardTransmit(card, nil, command, 10, nil, response, &responseLength);
        XCTAssertEqual(result, YKF_SCARD_S_SUCCESS, @"Could not send command to the key.");
        XCTAssertEqual(response[responseLength - 2], 0x90);
        XCTAssertEqual(response[responseLength - 1], 0x00);
        
        free(response);
        
        // Send a verify command to the key.
        
        [TestSharedLogger.shared logMessage:@"Sending a verify command..."];
        
        UInt8 verifyCommand[] = {0x00, 0x20, 0x00, 0x80, 0x08, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff};
        UInt8 *verifyResponse = malloc(UINT8_MAX + 2);
        UInt32 verifyResponseLength = UINT8_MAX + 2;
        
        result = YKFSCardTransmit(card, nil, verifyCommand, 13, nil, verifyResponse, &verifyResponseLength);
        XCTAssertEqual(result, YKF_SCARD_S_SUCCESS, @"Could not send command to the key.");
        XCTAssertEqual(verifyResponse[verifyResponseLength - 2], 0x90);
        XCTAssertEqual(verifyResponse[verifyResponseLength - 1], 0x00);
        
        free(verifyResponse);
        
        [expectation fulfill];
    });
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:15];
    XCTAssert(result == XCTWaiterResultCompleted, @"PCSC execution did timeout.");
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

@end
