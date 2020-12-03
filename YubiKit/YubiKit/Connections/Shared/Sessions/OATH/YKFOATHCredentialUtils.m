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
#import "YKFKeyOATHError.h"
#import "YKFKeySessionError.h"

#import "YKFKeySessionError+Private.h"
#import "YKFOATHCredential.h"
#import "YKFOATHCredentialTemplate.h"
#import "YKFOATHCredential+Private.h"

static const int YKFOATHCredentialValidatorMaxNameSize = 64;

@implementation YKFOATHCredentialUtils

+ (NSString *)labelFromCredentialIdentifier:(id<YKFOATHCredentialIdentifier>)credentialIdentifier {
    YKFAssertReturnValue(credentialIdentifier.account, @"Missing OATH credential account. Cannot build the credential label.", nil);
    
    if (credentialIdentifier.issuer) {
        return [NSString stringWithFormat:@"%@:%@", credentialIdentifier.issuer, credentialIdentifier.account];
    } else {
        return credentialIdentifier.account;
    }
}

+ (NSString *)keyFromCredentialIdentifier:(id<YKFOATHCredentialIdentifier>)credentialIdentifier {
    NSString *keyLabel = [YKFOATHCredentialUtils labelFromCredentialIdentifier:credentialIdentifier];
    
    if (credentialIdentifier.type == YKFOATHCredentialTypeTOTP) {
        if (credentialIdentifier.period != YKFOATHCredentialDefaultPeriod) {
            return [NSString stringWithFormat:@"%ld/%@", (unsigned long)credentialIdentifier.period, keyLabel];
        }
        else {
            return keyLabel;
        }
    } else {
        return keyLabel;
    }
}


+ (YKFKeySessionError *)validateCredentialTemplate:(YKFOATHCredentialTemplate *)credentialTemplate {
    YKFParameterAssertReturnValue(credentialTemplate, nil);
    
    if ([YKFOATHCredentialUtils keyFromCredentialIdentifier:credentialTemplate].length > YKFOATHCredentialValidatorMaxNameSize) {
        return [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeNameTooLong];
    }
    NSData *credentialSecret = credentialTemplate.secret;
    int shaAlgorithmBlockSize = 0;
    switch (credentialTemplate.algorithm) {
        case YKFOATHCredentialAlgorithmSHA1:
            shaAlgorithmBlockSize = CC_SHA1_BLOCK_BYTES;
            break;
        case YKFOATHCredentialAlgorithmSHA256:
            shaAlgorithmBlockSize = CC_SHA256_BLOCK_BYTES;
            break;
        case YKFOATHCredentialAlgorithmSHA512:
            shaAlgorithmBlockSize = CC_SHA512_BLOCK_BYTES;
            break;
        default:
            YKFAssertReturnValue(NO, @"Invalid OATH algorithm.", nil);
    }
    if (credentialSecret.length > shaAlgorithmBlockSize) {
        return [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeSecretTooLong];
    }
    return nil;
}

+ (YKFKeySessionError *)validateCredential:(YKFOATHCredential *)credential {
    YKFParameterAssertReturnValue(credential, nil);
    
    if ([YKFOATHCredentialUtils keyFromCredentialIdentifier:credential].length > YKFOATHCredentialValidatorMaxNameSize) {
        return [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeNameTooLong];
    }
    return nil;
}


@end
