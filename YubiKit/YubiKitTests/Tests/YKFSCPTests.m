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
#import "YKFNSDataAdditions+Private.h"
#import "YKFSCPKeyRef.h"
#import "YKFSCPState.h"
#import "YKFSCPStaticKeys.h"
#import "YKFSCPSessionKeys.h"

@interface YKFSCPTests : XCTestCase

@end

@implementation YKFSCPTests

-(void)testEncryptAESECB {
    NSData *key = [NSData dataFromHexString:@"5ec1bf26a34a6300c23bb45a9f8420495e472259a729439158766cfee5497c2b"];
    NSData *msg = [@"Hello World!0000" dataUsingEncoding: NSUTF8StringEncoding];
    NSData *expectedResult = [NSData dataFromHexString:@"0cb774fc5a0a3d4fbb9a6b582cb56b84"];
    NSData *result = [msg ykf_cryptOperation:kCCEncrypt algorithm:kCCAlgorithmAES mode:kCCModeECB key:key iv:nil];
    XCTAssertEqualObjects(result, expectedResult);
}

-(void)testDecryptAESECB {
    NSData *data = [NSData dataFromHexString:@"0cb774fc5a0a3d4fbb9a6b582cb56b84fa4e95678dbb6cc763bb4ce68df9155ffa4e95678dbb6cc763bb4ce68df9155ffa4e95678dbb6cc763bb4ce68df9155f"];
    NSData *key = [NSData dataFromHexString:@"5ec1bf26a34a6300c23bb45a9f8420495e472259a729439158766cfee5497c2b"];
    NSString *result = [[NSString alloc] initWithData:[data ykf_cryptOperation:kCCDecrypt algorithm:kCCAlgorithmAES mode:kCCModeECB key:key iv:nil] encoding: NSUTF8StringEncoding];
    NSString *expectedResult = @"Hello World!0000000000000000000000000000000000000000000000000000";
    XCTAssertEqualObjects(result, expectedResult);
}

-(void)testEncryptAESCBC {
    NSData *key = [NSData dataFromHexString:@"5ec1bf26a34a6300c23bb45a9f842049"];
    NSData *iv = [NSData dataFromHexString:@"000102030405060708090a0b0c0d0e0f"];
    NSData *msg = [@"Hello World!0000" dataUsingEncoding: NSUTF8StringEncoding];
    NSData *expectedResult = [NSData dataFromHexString:@"9dcb09c51227ea753fad4c6bda8efa46"];
    NSData *result = [msg ykf_cryptOperation:kCCEncrypt algorithm:kCCAlgorithmAES mode:kCCModeCBC key:key iv:iv];
    XCTAssertEqualObjects(result, expectedResult);
}

-(void)testDecryptAESCBC {
    NSData *data = [NSData dataFromHexString:@"9dcb09c51227ea753fad4c6bda8efa46"];
    NSData *key = [NSData dataFromHexString:@"5ec1bf26a34a6300c23bb45a9f842049"];
    NSData *iv = [NSData dataFromHexString:@"000102030405060708090a0b0c0d0e0f"];
    NSString *result = [[NSString alloc] initWithData:[data ykf_cryptOperation:kCCDecrypt algorithm:kCCAlgorithmAES mode:kCCModeCBC key:key iv:iv] encoding: NSUTF8StringEncoding];
    NSString *expectedResult = @"Hello World!0000";
    XCTAssertEqualObjects(result, expectedResult);
}

@end
