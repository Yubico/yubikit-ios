//
//  GnubbyManualTests.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-24.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "GnubbyManualTests.h"
#import "TestSharedLogger.h"

typedef NS_ENUM(NSUInteger, GnubbyManualTestsInstruction) {
    GnubbyTestsInstructionEcho = 0x10
};

@implementation GnubbyManualTests

#pragma mark - Test setup

- (void)setupTestList {
    NSMutableArray *tests = [[NSMutableArray alloc] init];
        
    // Short echo test Gnubby
    NSValue *gnubbyShortEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingAShortValue_ValueIsReceivedBack)];
    NSArray *gnubbyShortGnubbyEchoTestEntry = @[@"Gnubby echo test #1", @"Short value echo test.", gnubbyShortEchoTestSelector];
    [tests addObject:gnubbyShortGnubbyEchoTestEntry];
    
    // Repeated short echo test Gnubby
    NSValue *gnubbyRepeatedShortEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingTheSameValueMultipleTimes_ValueIsReceivedBack)];
    NSArray *gnubbyRepeatedShortEchoTestEntry = @[@"Gnubby echo test #2", @"Repeated short value echo test.", gnubbyRepeatedShortEchoTestSelector];
    [tests addObject:gnubbyRepeatedShortEchoTestEntry];
    
    // Ping with length in interval Gnubby
    NSValue *gnubbyIntervalEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingValuesInAnInterval_ValuesAreReceivedBack)];
    NSArray *gnubbyIntervalEchoTestEntry = @[@"Gnubby echo test #3", @"Interval echo test.", gnubbyIntervalEchoTestSelector];
    [tests addObject:gnubbyIntervalEchoTestEntry];
    
    // Ping incrementing values with length in interval
    NSValue *gnubbyIncrementingIntervalEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingIncrementingValuesInAnInterval_ValuesAreReceivedBack)];
    NSArray *gnubbyIncrementingIntervalEchoTestEntry = @[@"Gnubby echo test #4", @"Incrementing interval echo test.", gnubbyIncrementingIntervalEchoTestSelector];
    [tests addObject:gnubbyIncrementingIntervalEchoTestEntry];
    
    // Set the list
    self.testList = @[@[@"Echo tests", tests]];
}

- (void)testEcho_WhenSendingAShortValue_ValueIsReceivedBack {
    [self executeGnubbyU2FApplicationSelection];
    [self pingGnubbyWithRandomDataLength:20];
    [TestSharedLogger.shared logSepparator];
}

- (void)testEcho_WhenSendingTheSameValueMultipleTimes_ValueIsReceivedBack {
    [self executeGnubbyU2FApplicationSelection];
    for (int i = 0; i < 100; ++i) {
        [self pingGnubbyWithRandomDataLength:20];
    }
}

- (void)testEcho_WhenSendingValuesInAnInterval_ValuesAreReceivedBack {
    [self executeGnubbyU2FApplicationSelection];
    for (int dataLength = 1; dataLength <= 1024; ++dataLength) {
        [self pingGnubbyWithRandomDataLength:dataLength];
    }
}

- (void)testEcho_WhenSendingIncrementingValuesInAnInterval_ValuesAreReceivedBack {
    [self executeGnubbyU2FApplicationSelection];
    for (int dataLength = 1; dataLength <= 1024; ++dataLength) {
        [self pingGnubbyWithIncrementingDataLength:dataLength];
    }
}

#pragma mark - Test helpers

- (void)pingGnubbyWithData:(NSData *)data length:(NSUInteger)length {
    [TestSharedLogger.shared logMessage:@"Queue ping with data length: %d", length];
    
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:GnubbyTestsInstructionEcho p1:0 p2:0 data:data type:YKFAPDUTypeExtended];
    
    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"When requesting echo: %@", error.localizedDescription];
            return;
        }
        
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];
        
        NSData *echoData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        if ([echoData isEqualToData:data]) {
            [TestSharedLogger.shared logSuccess:@"Received data is equal with sent data."];
        } else {
            [TestSharedLogger.shared logError:@"Received data is not equal with sent data."];
        }
    }];
}

- (void)pingGnubbyWithRandomDataLength:(NSUInteger)length {
    NSUInteger dataLength = length;
    NSData *randomData = [self.testDataGenerator randomDataWithLength:dataLength];
    
    [self pingGnubbyWithData:randomData length:dataLength];
}

- (void)pingGnubbyWithIncrementingDataLength:(NSUInteger)length {
    NSUInteger dataLength = length;
    
    NSMutableData *incrementData = [NSMutableData dataWithCapacity:length];
    
    for (uint32_t j=0; j<=length; j++) {
        uint8_t byte = j % 0xFF;
        [incrementData appendBytes:&byte length:sizeof(byte)];
    }
    
    [self pingGnubbyWithData:incrementData length:dataLength];
}

@end
