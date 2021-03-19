// Copyright 2018-2021 Yubico AB
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
#import "YKFNSDataAdditions.h"

@interface YKFPIVPaddingTests : XCTestCase

@end

@implementation YKFPIVPaddingTests

- (void)testPadRSAPKCS1Data {
    NSData *data = [@"Hello World!" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSData *padded = [YKFPIVPadding padData:data keyType:YKFPIVKeyTypeRSA1024 algorithm:kSecKeyAlgorithmRSAEncryptionPKCS1 error:&error];
    NSData *trailingData = [NSData dataFromHexString:@"0048656c6c6f20576f726c6421"];
    NSData *resultTrailingData = [padded subdataWithRange:NSMakeRange(128 - 13, 13)];
    XCTAssertEqualObjects(trailingData, resultTrailingData);
    NSData *beginData = [NSData dataFromHexString:@"0002"];
    NSData *resultBeginData = [padded subdataWithRange:NSMakeRange(0, 2)];
    XCTAssertEqualObjects(beginData, resultBeginData);
    NSData *unpadded = [YKFPIVPadding unpadRSAData:padded algorithm:kSecKeyAlgorithmRSAEncryptionPKCS1 error:&error];
    NSString *result = [[NSString alloc] initWithData:unpadded encoding:NSUTF8StringEncoding];
    XCTAssert([result isEqual:@"Hello World!"]);
}

- (void)testUnpadRSAEncryptionPKCS1PaddedData {
    NSData *rsaEncryptionPKCS1PaddedData = [NSData dataFromHexString:@"00022b781255b78f9570844701748107f506effbea5f0822b41dded192938906cefe16eef190d4cf7f7b0866badf94ca0e4e08fda43e4619edec2703987a56a78aa4c2d36a8f89c43f1f9c0ab681e45a759744ef946d65d95e74536b28b83cdc1c62e36c014c8b4a50c178a54306ce7395240e0048656c6c6f20576f726c6421"];

    NSError *error = nil;
    NSData *unpadded = [YKFPIVPadding unpadRSAData:rsaEncryptionPKCS1PaddedData algorithm:kSecKeyAlgorithmRSAEncryptionPKCS1 error:&error];

    NSString *result = [[NSString alloc] initWithData:unpadded encoding:NSUTF8StringEncoding];
    XCTAssert([result isEqual:@"Hello World!"]);
}

- (void)testUnpadRSAEncryptionOAEPSHA224Data {
    NSData *rsaEncryptionOAEPSHA224Data = [NSData dataFromHexString:@"00bcbb35b6ef5c94a85fb3439a6dabda617a08963cf81023bac19c619b024cb71b8aee25cc30991279c908198ba623fba88547741dbf17a6f2a737ec95542b56b2b429bea8bd3145af7c8f144dcf804b89d3f9de21d6d6dc852fc91c666b8582bf348e1388ac2f54651ae6a1f5355c8d96daf96c922a9f1a499d890412d09454"];
    
    NSError *error = nil;
    NSData *unpadded = [YKFPIVPadding unpadRSAData:rsaEncryptionOAEPSHA224Data algorithm:kSecKeyAlgorithmRSAEncryptionOAEPSHA224 error:&error];
    
    NSString *result = [[NSString alloc] initWithData:unpadded encoding:NSUTF8StringEncoding];
    XCTAssert([result isEqual:@"Hello World!"]);
}

- (void)testUnpadWrongData {
    NSData *rsaEncryptionOAEPSHA224Data = [NSData dataFromHexString:@"00bcbb35b6ef5c94a85fb3439a6dabda617a08963cf81023bac19c619b024cb71b8aee25cc30991279c908198ba623fba88547741dbf17a6f2a737ec95542b56b2b429bea8bd3145af7c8f144dcf804b89d3f9de21d6d6dc852fc91c666b8582bf348e1388ac2f54651ae6a1f5355c8d96daf96c922a9f1a499d890412d09454"];
    
    NSError *error = nil;
    NSData *result = [YKFPIVPadding unpadRSAData:rsaEncryptionOAEPSHA224Data algorithm:kSecKeyAlgorithmRSAEncryptionPKCS1 error:&error];

    XCTAssertNil(result);
}

@end
