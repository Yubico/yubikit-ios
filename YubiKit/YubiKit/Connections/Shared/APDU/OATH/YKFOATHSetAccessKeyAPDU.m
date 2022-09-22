// Copyright 2018-2022 Yubico AB
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

#import "YKFOATHSetAccessKeyAPDU.h"
#import "YKFAPDUCommandInstruction.h"
#import "YKFOATHCredential.h"
#import "YKFAssert.h"
#import "YKFNSMutableDataAdditions.h"
#import "YKFNSDataAdditions+Private.h"

static const UInt8 YKFOATHSetCodeAPDUKeyTag = 0x73;
static const UInt8 YKFOATHSetCodeAPDUChallengeTag = 0x74;
static const UInt8 YKFOATHSetCodeAPDUResponseTag = 0x75;

@implementation YKFOATHSetAccessKeyAPDU

- (instancetype)initWithAccessKey:(NSData *)accessKey {
    YKFAssertAbortInit(accessKey);
    
    NSMutableData *data = [[NSMutableData alloc] init];
    
    UInt8 algorithm = YKFOATHCredentialTypeTOTP | YKFOATHCredentialAlgorithmSHA1;
    
    [data ykf_appendEntryWithTag:YKFOATHSetCodeAPDUKeyTag headerBytes:@[@(algorithm)] data:accessKey];
    
    // Challenge
    UInt8 challengeBuffer[8];
    arc4random_buf(challengeBuffer, 8);
    NSData *challenge = [NSData dataWithBytes:challengeBuffer length:8];
    [data ykf_appendEntryWithTag:YKFOATHSetCodeAPDUChallengeTag data:challenge];
    
    // Response
    NSData *response = [challenge ykf_oathHMACWithKey:accessKey];
    [data ykf_appendEntryWithTag:YKFOATHSetCodeAPDUResponseTag data:response];
    
    return [super initWithCla:0 ins:0x03 p1:0 p2:0 data:data type:YKFAPDUTypeShort];
}

@end
