// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <XCTest/XCTest.h>
#import "YKFTestCase.h"
#import "YKFKeyRawCommandService.h"
#import "YKFKeyRawCommandService+Private.h"
#import "FakeYKFKeyConnectionController.h"

@interface YKFKeyRawCommandServiceTests: YKFTestCase

@property (nonatomic) FakeYKFKeyConnectionController *keyConnectionController;
@property (nonatomic) YKFKeyRawCommandService *rawCommandService;


@end

@implementation YKFKeyRawCommandServiceTests

- (void)setUp {
    self.keyConnectionController = [[FakeYKFKeyConnectionController alloc] init];
    self.rawCommandService = [[YKFKeyRawCommandService alloc] initWithConnectionController:self.keyConnectionController];
}

#pragma mark - Sync commands

- (void)test_WhenRunningSyncRawCommandsAgainstTheKey_CommandsAreForwardedToTheKey {
    NSData *command = [self dataWithBytes:@[@(0x00), @(0x01), @(0x02)]];
    NSData *commandResponse = [self dataWithBytes:@[@(0x00), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    NSData *responseData = [self executeSyncCommand:command];
    XCTAssertNotNil(responseData);
    
    NSData *executionCommandData = self.keyConnectionController.executionCommandData;
    XCTAssertNotNil(executionCommandData, @"No command data executed on the connection controller.");
    XCTAssertEqual(((UInt8*)executionCommandData.bytes)[0], 0x00);
    
    executionCommandData = [executionCommandData subdataWithRange:NSMakeRange(1, executionCommandData.length - 1)];
    XCTAssert([executionCommandData isEqualToData:command], @"Command sent to the key does not match the initial command.");
}

- (void)test_WhenRunningSyncRawCommandsAgainstTheKey_StatusCodeAreReturned {
    NSData *command = [self dataWithBytes:@[@(0x00), @(0x01), @(0x02)]];
    NSData *commandResponse = [self dataWithBytes:@[@(0x00), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    NSData *responseData = [self executeSyncCommand:command];
    
    XCTAssertEqual(responseData.length, 2, @"Response data too short.");
    XCTAssert([responseData isEqualToData:[commandResponse subdataWithRange:NSMakeRange(1, 2)]]);
}

- (void)test_WhenRunningSyncRawCommandsAgainstTheKey_ReturnedDataDoesNotHaveIAPFrame {
    
    // Regular response
    
    NSData *command = [self dataWithBytes:@[@(0x00), @(0x01), @(0x02)]];
    NSData *commandResponse = [self dataWithBytes:@[@(0x00), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    NSData *responseData = [self executeSyncCommand:command];
    
    UInt8 *bytes = (UInt8 *)responseData.bytes;
    XCTAssertNotEqual(bytes[0], 0x00);
    
    // WTX response
    
    commandResponse = [self dataWithBytes:@[@(0x01), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];

    responseData = [self executeSyncCommand:command];
    
    bytes = (UInt8 *)responseData.bytes;
    XCTAssertNotEqual(bytes[0], 0x00);
}

#pragma mark - Async commands

- (void)test_WhenRunningAsyncRawCommandsAgainstTheKey_CommandsAreForwardedToTheKey {
    NSData *command = [self dataWithBytes:@[@(0x00), @(0x01), @(0x02)]];
    NSData *commandResponse = [self dataWithBytes:@[@(0x00), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    NSData *responseData = [self executeAsyncCommand:command];
    XCTAssertNotNil(responseData);
    
    NSData *executionCommandData = self.keyConnectionController.executionCommandData;
    XCTAssertNotNil(executionCommandData, @"No command data executed on the connection controller.");
    XCTAssertEqual(((UInt8*)executionCommandData.bytes)[0], 0x00);
    
    executionCommandData = [executionCommandData subdataWithRange:NSMakeRange(1, executionCommandData.length - 1)];
    XCTAssert([executionCommandData isEqualToData:command], @"Command sent to the key does not match the initial command.");
}

- (void)test_WhenRunningAsyncRawCommandsAgainstTheKey_StatusCodeAreReturned {
    NSData *command = [self dataWithBytes:@[@(0x00), @(0x01), @(0x02)]];
    NSData *commandResponse = [self dataWithBytes:@[@(0x00), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    NSData *responseData = [self executeAsyncCommand:command];
    
    XCTAssertEqual(responseData.length, 2, @"Response data too short.");
    XCTAssert([responseData isEqualToData:[commandResponse subdataWithRange:NSMakeRange(1, 2)]]);
}

- (void)test_WhenRunningAsyncRawCommandsAgainstTheKey_ReturnedDataDoesNotHaveIAPFrame {
    
    // Regular response
    
    NSData *command = [self dataWithBytes:@[@(0x00), @(0x01), @(0x02)]];
    NSData *commandResponse = [self dataWithBytes:@[@(0x00), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    NSData *responseData = [self executeAsyncCommand:command];
    
    UInt8 *bytes = (UInt8 *)responseData.bytes;
    XCTAssertNotEqual(bytes[0], 0x00);
    
    // WTX response
    
    commandResponse = [self dataWithBytes:@[@(0x01), @(0x90), @(0x00)]];
    self.keyConnectionController.commandExecutionResponseDataSequence = @[commandResponse];
    
    responseData = [self executeSyncCommand:command];
    
    bytes = (UInt8 *)responseData.bytes;
    XCTAssertNotEqual(bytes[0], 0x00);
}

#pragma mark - Helpers

- (NSData *)executeSyncCommand:(NSData *)command {
    __block BOOL completionBlockExecuted = NO;
    __block NSData *responseData = nil;
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Application selection."];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        YKFAPDU *commandAPDU = [[YKFAPDU alloc] initWithData:command];
        YKFKeyRawCommandServiceResponseBlock completionBlock = ^(NSData *response, NSError *error) {
            if (error) {
                return;
            }            
            completionBlockExecuted = YES;
            responseData = response;
        };
        [self.rawCommandService executeSyncCommand:commandAPDU completion:completionBlock];
        [expectation fulfill];
    });
    
    [self waitForTimeInterval:0.2];
    XCTAssertTrue(completionBlockExecuted, @"Completion block not executed.");

    return responseData;
}

- (NSData *)executeAsyncCommand:(NSData *)command {
    __block BOOL completionBlockExecuted = NO;
    __block NSData *responseData = nil;
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Application selection."];
    
    YKFAPDU *commandAPDU = [[YKFAPDU alloc] initWithData:command];
    [self.rawCommandService executeCommand:commandAPDU completion:^(NSData *response, NSError *error) {
        if (error) {
            return;
        }
        completionBlockExecuted = YES;
        responseData = response;
        [expectation fulfill];
    }];
    
    [self waitForTimeInterval:0.2];
    XCTAssertTrue(completionBlockExecuted, @"Completion block not executed.");
    
    return responseData;
}

@end
