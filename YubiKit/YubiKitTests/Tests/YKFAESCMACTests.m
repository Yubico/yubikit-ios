// Copyright 2018-2025 Yubico AB
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
#import "YKFPIVPadding+Private.h"
#import "YKFPIVKeyType.h"
#import "YKFNSDataAdditions+Private.h"

@interface YKFAESCMACTests : XCTestCase

@end

@implementation YKFAESCMACTests

-(void)testAESCMAC_0 {
    NSData *key = [NSData dataFromHexString:@"2b7e1516 28aed2a6 abf71588 09cf4f3c"];
    NSData *msg = [NSData new];
    NSData *expectedMac = [NSData dataFromHexString:@"bb1d6929 e9593728 7fa37d12 9b756746"];
    NSData *result = [msg ykf_aesCMACWithKey: key];
    XCTAssertEqualObjects(result, expectedMac);
}

-(void)testAESCMAC_16 {
    NSData *key = [NSData dataFromHexString:@"2b7e1516 28aed2a6 abf71588 09cf4f3c"];
    NSData *msg = [NSData dataFromHexString:@"6bc1bee2 2e409f96 e93d7e11 7393172a"];
    NSData *expectedMac = [NSData dataFromHexString:@"070a16b4 6b4d4144 f79bdd9d d04a287c"];
    NSData *result = [msg ykf_aesCMACWithKey: key];
    XCTAssertEqualObjects(result, expectedMac);
}

-(void)testAESCMAC_40 {
    NSData *key = [NSData dataFromHexString:@"2b7e1516 28aed2a6 abf71588 09cf4f3c"];
    NSData *msg = [NSData dataFromHexString:@"6bc1bee2 2e409f96 e93d7e11 7393172a ae2d8a57 1e03ac9c 9eb76fac 45af8e51 30c81c46 a35ce411"];
    NSData *expectedMac = [NSData dataFromHexString:@"dfa66747 de9ae630 30ca3261 1497c827"];
    NSData *result = [msg ykf_aesCMACWithKey: key];
    XCTAssertEqualObjects(result, expectedMac);
}

-(void)testAESCMAC_64 {
    NSData *key = [NSData dataFromHexString:@"2b7e1516 28aed2a6 abf71588 09cf4f3c"];
    NSData *msg = [NSData dataFromHexString:@"6bc1bee2 2e409f96 e93d7e11 7393172a ae2d8a57 1e03ac9c 9eb76fac 45af8e51 30c81c46 a35ce411 e5fbc119 1a0a52ef f69f2445 df4f9b17 ad2b417b e66c3710"];
    NSData *expectedMac = [NSData dataFromHexString:@"51f0bebf 7e3b9d92 fc497417 79363cfe"];
    NSData *result = [msg ykf_aesCMACWithKey: key];
    XCTAssertEqualObjects(result, expectedMac);
}

-(void)testShiftLeftWithCarryOver {
    NSData *data = [NSData dataFromHexString:@"01 ff 03 04"];
    NSData *shiftedData = [data ykf_shiftedLeftByOne];
    XCTAssertEqualObjects(shiftedData, [NSData dataFromHexString:@"03 fe 06 08"]);
    NSLog(@"%@", [shiftedData ykf_hexadecimalString]);
}

-(void)testShiftLeftWithCarryOverFirst {
    NSData *data = [NSData dataFromHexString:@"ff 02 03 04"];
    NSData *shiftedData = [data ykf_shiftedLeftByOne];
    XCTAssertEqualObjects(shiftedData, [NSData dataFromHexString:@"fe 04 06 08"]);
    NSLog(@"%@", [shiftedData ykf_hexadecimalString]);
}

-(void)testShiftLeftWithCarryOverLast {
    NSData *data = [NSData dataFromHexString:@"01 02 03 ff"];
    NSData *shiftedData = [data ykf_shiftedLeftByOne];
    XCTAssertEqualObjects(shiftedData, [NSData dataFromHexString:@"02 04 07 fe"]);
    NSLog(@"%@", [shiftedData ykf_hexadecimalString]);
}

-(void)testShiftLeftNoCarryOver {
    NSData *data = [NSData dataFromHexString:@"01 02 03 04"];
    NSLog(@"%@", [data ykf_hexadecimalString]);

    NSData *shiftedData = [data ykf_shiftedLeftByOne];
    XCTAssertEqualObjects(shiftedData, [NSData dataFromHexString:@"02 04 06 08"]);
    NSLog(@"%@", [shiftedData ykf_hexadecimalString]);
}

-(void)testXor {
    NSData *data = [NSData dataFromHexString:@"1F 2B"];
    NSData *key = [NSData dataFromHexString:@"AA BB"];
    NSData *result = [data ykf_xorWithKey:key];
    NSLog(@"%@", [result ykf_hexadecimalString]);
    XCTAssertEqualObjects(result, [NSData dataFromHexString:@"b5 90"]);
}

@end
