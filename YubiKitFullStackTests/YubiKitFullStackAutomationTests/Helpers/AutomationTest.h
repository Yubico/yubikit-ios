//
//  AutomationTest.h
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-06-20.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YubiKit/YubiKit.h>

@interface AutomationTest : XCTestCase

@property (nonatomic, readonly) YKFAccessorySession *accessorySession;

// MoLY commands

- (void)connectKey;
- (void)disconnectKey;
- (void)touchKey;

// U2F Commands Execution

- (NSString *)executeRegisterRequestWithChallenge:(NSString *)challenge appId:(NSString *)appId;
- (void)executeSignRequestWithKeyHandle:(NSString *)keyHandle challenge:(NSString *)challenge appId:(NSString *)appId;

// Helpers

+ (void)waitForTimeInterval:(NSTimeInterval)timeInterval;

@end
