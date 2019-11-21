//
//  KeyConnectionAutomationTests.m
//  KeyConnectionAutomationTests
//
//  Created by Conrad Ciobanica on 2018-06-20.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YubiKit/YubiKit.h>

#import "TestSharedLogger.h"
#import "AutomationTest.h"

static const int KeyConnectionAutomationTestsReplugIterations = 5;
static const int KeyConnectionAutomationTestsReconnectIterations = 10;

@interface KeyConnectionAutomationTests: AutomationTest
@end

@implementation KeyConnectionAutomationTests

- (void)test_WhenKeyIsPluggedIn_KeyServiceIsOpened {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenKeyIsPluggedIn -> KeyServiceIsOpened."];

    [self connectKey];
    
    YKFAccessorySessionState sessionState = self.accessorySession.sessionState;
    BOOL sessionOpened = sessionState == YKFAccessorySessionStateOpen;
    
    [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
    XCTAssert(sessionOpened);
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

- (void)test_WhenKeyIsPluggedOut_KeyServiceIsClosed {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenKeyIsPluggedOut -> KeyServiceIsClosed."];
    
    [self connectKey];
    
    YKFAccessorySessionState sessionState = self.accessorySession.sessionState;
    BOOL sessionOpened = sessionState == YKFAccessorySessionStateOpen;
    
    [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
    XCTAssert(sessionOpened);
    
    [self disconnectKey];
        
    sessionState = self.accessorySession.sessionState;
    BOOL sessionClosed = sessionState == YKFAccessorySessionStateClosed;
    
    [TestSharedLogger.shared logCondition:sessionClosed onSuccess:@"Session is closed." onFailure:@"Session is open."];
    XCTAssert(sessionClosed);
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

- (void)test_WhenKeyIsPluggedIn_CanManuallyOpenAnCloseTheSession {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenKeyIsPluggedIn -> CanManuallyOpenAnCloseTheSession."];
    
    [self connectKey];
    
    YKFAccessorySessionState sessionState = self.accessorySession.sessionState;
    BOOL sessionOpened = sessionState == YKFAccessorySessionStateOpen;
    
    [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
    XCTAssert(sessionOpened);
    
    // Close and open the session while the key is connected
    
    // Manually stop the session
    [self.accessorySession stopSession];
    [AutomationTest waitForTimeInterval:1];
    
    sessionState = self.accessorySession.sessionState;
    BOOL sessionClosed = sessionState == YKFAccessorySessionStateClosed;
    
    [TestSharedLogger.shared logCondition:sessionClosed onSuccess:@"Session is closed." onFailure:@"Session is open."];
    XCTAssert(sessionClosed);
    
    // Manually open the session
    [self.accessorySession startSession];
    [AutomationTest waitForTimeInterval:1];
    
    sessionState = self.accessorySession.sessionState;
    sessionOpened = sessionState == YKFAccessorySessionStateOpen;
    
    [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
    XCTAssert(sessionOpened);
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

#pragma mark - Stress

- (void)test_WhenKeyIsPluggedInAndOutMultipleTimes_AccessorySessionUpdatesState {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenKeyIsPluggedInAndOutMultipleTimes -> AccessorySessionUpdatesState."];
    
    for (int i = 0; i < KeyConnectionAutomationTestsReplugIterations; ++i) {
        [TestSharedLogger.shared logMessage:@"Iteration #%d", i];
        [self connectKey];
        
        YKFAccessorySessionState sessionState = self.accessorySession.sessionState;
        BOOL sessionOpened = sessionState == YKFAccessorySessionStateOpen;
        
        [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
        XCTAssert(sessionOpened);
        
        [self disconnectKey];
        
        sessionState = self.accessorySession.sessionState;
        BOOL sessionClosed = sessionState == YKFAccessorySessionStateClosed;
        
        [TestSharedLogger.shared logCondition:sessionClosed onSuccess:@"Session is closed." onFailure:@"Session is open."];
        XCTAssert(sessionClosed);
    }
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

- (void)test_WhenKeyIsPluggedIn_CanManuallyOpenAnCloseTheSessionMultipleTimes {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Test: WhenKeyIsPluggedIn -> CanManuallyOpenAnCloseTheSessionMultipleTimes."];
    
    [self connectKey];
    
    YKFAccessorySessionState sessionState = self.accessorySession.sessionState;
    BOOL sessionOpened = sessionState == YKFAccessorySessionStateOpen;
    
    [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
    XCTAssert(sessionOpened);
    
    for (int i = 0; i < KeyConnectionAutomationTestsReconnectIterations; ++i) {        
        [TestSharedLogger.shared logMessage:@"Iteration #%d", i];
        
        // Manually stop the session
        [self.accessorySession stopSession];
        [AutomationTest waitForTimeInterval:1];
        
        sessionState = self.accessorySession.sessionState;
        BOOL sessionClosed = sessionState == YKFAccessorySessionStateClosed;
        
        [TestSharedLogger.shared logCondition:sessionClosed onSuccess:@"Session is closed." onFailure:@"Session is open."];
        XCTAssert(sessionClosed);
        
        // Manually open the session
        [self.accessorySession startSession];
        [AutomationTest waitForTimeInterval:1];
        
        sessionState = self.accessorySession.sessionState;
        sessionOpened = sessionState == YKFAccessorySessionStateOpen;
        
        [TestSharedLogger.shared logCondition:sessionOpened onSuccess:@"Session is open." onFailure:@"Session is closed."];
        XCTAssert(sessionOpened);
    }
    
    [TestSharedLogger.shared logMessage:@"Done."];
}

@end
