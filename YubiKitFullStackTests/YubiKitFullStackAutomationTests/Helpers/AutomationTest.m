//
//  AutomationTest.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-06-20.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <YubiKit/YubiKit.h>

#import "TestSharedLogger.h"
#import "AutomationTest.h"
#import "MoLYService.h"
#import "U2FDataParser.h"

static const NSTimeInterval MoLYConnectionPlugoutPluginDelay = 4; // seconds
static const NSTimeInterval MoLYConnectionReactionDelay = 3; // seconds
static const NSTimeInterval MoLYConnectionTouchDelay = 1.5; // seconds

@implementation AutomationTest

+ (void)setUp {
    [super setUp];
    
    NSString *className = NSStringFromClass(self);
    
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage: @"Starting %@", className];
    [TestSharedLogger.shared logSepparator];
    
    [[MoLYService shared] plugout];
    [self waitForTimeInterval:MoLYConnectionReactionDelay];
}

+ (void)tearDown {
    [super tearDown];
    
    [[MoLYService shared] plugout];
    [self waitForTimeInterval:MoLYConnectionReactionDelay];
}

#pragma mark - Computed properties

- (YKFAccessorySession *)accessorySession {
    return YubiKitManager.shared.accessorySession;
}

#pragma mark - MoLY commands

- (void)connectKey {
    YKFAccessorySessionState sessionState = [YubiKitManager shared].accessorySession.sessionState;
    if (sessionState == YKFAccessorySessionStateOpen) {
        return;
    }
    
    XCTAssert([[MoLYService shared] plugin], @"Plugging in the key failed.");
    [AutomationTest waitForTimeInterval:MoLYConnectionPlugoutPluginDelay];
    
    sessionState = [YubiKitManager shared].accessorySession.sessionState;
    XCTAssert(sessionState == YKFAccessorySessionStateOpen, @"The session is not open after the key was connected to the device.");
}

- (void)disconnectKeyAndWaitForTimeInterval:(NSTimeInterval)delay {
    YKFAccessorySessionState sessionState = [YubiKitManager shared].accessorySession.sessionState;
    if (sessionState == YKFAccessorySessionStateOpen) {
        XCTAssert([[MoLYService shared] plugout], @"Plugging out the key failed.");
    }
    
    if (delay > 0) {
        [AutomationTest waitForTimeInterval:delay];
    }
}

- (void)disconnectKey {
    [self disconnectKeyAndWaitForTimeInterval:MoLYConnectionPlugoutPluginDelay];
}

- (void)touchKey {
    XCTAssert([[MoLYService shared] touch], @"Touching the key failed.");
    [AutomationTest waitForTimeInterval:MoLYConnectionReactionDelay + MoLYConnectionTouchDelay];
}

#pragma mark - U2F Commands Execution

- (NSString *)executeRegisterRequestWithChallenge:(NSString *)challenge appId:(NSString *)appId {
    [self selectU2FApplication];
    
    YKFKeyU2FRegisterRequest *registerRequest = [[YKFKeyU2FRegisterRequest alloc] initWithChallenge:challenge appId:appId];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Registration request."];
    
    // Send registration request
    
    [TestSharedLogger.shared logMessage:@"Sending registration request to key."];
    
    XCTAssert(self.accessorySession.u2fService);
    
    __weak typeof(self) weakSelf = self;
    __block NSString *keyHandle = nil;
    
    [self.accessorySession.u2fService executeRegisterRequest:registerRequest completion:^(YKFKeyU2FRegisterResponse *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [TestSharedLogger.shared logCondition:!error onSuccess:@"Payload received." onFailure:@"Error received."];
        
        if (error) {
            // Cancel all queued commands
            [strongSelf.accessorySession cancelCommands];
        } else {
            XCTAssert(response.clientData, @"The response does not have the client data.");
            XCTAssert(response.registrationData, @"The response does not have the registration data.");
            
            keyHandle = [U2FDataParser keyHandleFromRegistrationData:response.registrationData];
            XCTAssert(keyHandle, @"Nil key handle parsed after registration");
            
            if (response.clientData && response.registrationData) {
                [expectation fulfill];
            }
        }
    }];
    
    // Wait and then touch
    [AutomationTest waitForTimeInterval:1];
    [self touchKey];
    
    // Wait for the key to respond
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    BOOL registrationSuccessful = result == XCTWaiterResultCompleted;
    
    [TestSharedLogger.shared logCondition:registrationSuccessful onSuccess:@"Registration successful." onFailure:@"Registration failed."];
    XCTAssert(registrationSuccessful, @"Registration request failed.");
    
    // Return the key handle
    return keyHandle;
}

- (void)executeSignRequestWithKeyHandle:(NSString *)keyHandle challenge:(NSString *)challenge appId:(NSString *)appId {
    [self selectU2FApplication];
    
    YKFKeyU2FSignRequest *signRequest = [[YKFKeyU2FSignRequest alloc] initWithChallenge:challenge keyHandle:keyHandle appId:appId];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Signing selection."];
    
    // Send registration request
    
    [TestSharedLogger.shared logMessage:@"Sending signing request to key."];
    
    XCTAssert(self.accessorySession.u2fService);
    
    __weak typeof(self) weakSelf = self;
    
    [self.accessorySession.u2fService executeSignRequest:signRequest completion:^(YKFKeyU2FSignResponse *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [TestSharedLogger.shared logCondition:!error onSuccess:@"Payload received." onFailure:@"Error received."];
        
        if (error) {
            // Cancel all queued commands
            [strongSelf.accessorySession cancelCommands];
        } else {
            XCTAssert(response.signature, @"Empty signature received after signing.");
            if (response.signature) {
                [expectation fulfill];
            }
        }
    }];
    
    // Wait and then touch
    [AutomationTest waitForTimeInterval:1];
    [self touchKey];
    
    // Wait for the key to respond
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    BOOL signingSuccessful = result == XCTWaiterResultCompleted;
    
    [TestSharedLogger.shared logCondition:signingSuccessful onSuccess:@"Signing successful." onFailure:@"Signing failed."];
    XCTAssert(signingSuccessful, @"Signing request failed.");
}

- (void)selectU2FApplication {    
    static const NSUInteger applicationIdSize = 8;
    UInt8 u2fApplicationId[applicationIdSize] = {0xA0, 0x00, 0x00, 0x06, 0x47, 0x2F, 0x00, 0x01};
    NSData *data = [NSData dataWithBytes:u2fApplicationId length:applicationIdSize];
    YKFAPDU *selectU2FApplicationAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:data type:YKFAPDUTypeShort];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Application selection."];
    
    __weak typeof(self) weakSelf = self;
    [self.accessorySession.rawCommandService executeCommand:selectU2FApplicationAPDU completion:^(NSData *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (error) {
            [TestSharedLogger.shared logError: @"U2F application selection failed with error: %@", error.localizedDescription];
            
            // Cancel all queued commands
            [strongSelf.accessorySession cancelCommands];
        }
        
        [expectation fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    XCTAssert(result == XCTWaiterResultCompleted);
}

#pragma mark - Helpers

+ (void)waitForTimeInterval:(NSTimeInterval)timeInterval {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Delay."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:timeInterval];
    NSAssert(result == XCTWaiterResultTimedOut, @"Delay failure.");
}

@end
