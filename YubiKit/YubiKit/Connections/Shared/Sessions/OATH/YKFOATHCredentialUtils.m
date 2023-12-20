// Copyright 2018-2020 Yubico AB
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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import "YKFOATHCredentialUtils.h"
#import "YKFAssert.h"
#import "YKFOATHError.h"
#import "YKFSessionError.h"

#import "YKFSessionError+Private.h"
#import "YKFOATHCredential.h"
#import "YKFOATHCredentialTemplate.h"
#import "YKFOATHCredential+Private.h"

static const int YKFOATHCredentialValidatorMaxNameSize = 64;

@implementation YKFOATHCredentialUtils

+ (NSString *)keyFromAccountName:(NSString *)name issuer:(NSString *)issuer period:(NSUInteger)period type:(YKFOATHCredentialType)type {
    NSMutableString *accountId = [NSMutableString new];
    if (type == YKFOATHCredentialTypeTOTP && period != YKFOATHCredentialDefaultPeriod) {
        [accountId appendFormat:@"%ld/", (unsigned long)period];
    }
    if (issuer != nil) {
        [accountId appendFormat:@"%@:", issuer];
    }
    [accountId appendString:name];
    return accountId ;
}

@end
