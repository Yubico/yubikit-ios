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

#import <CommonCrypto/CommonCrypto.h>

#import "YKFOATHCredentialTemplate.h"
#import "YKFOATHCredential+Private.h"
#import "YKFAssert.h"
#import "YKFLogger.h"
#import "YKFNSDataAdditions.h"
#import "MF_Base32Additions.h"

NSString* const YKFOATHCredentialTemplateErrorDomain = @"com.yubico.oath.credential.template";
static const int YKFOATHCredentialValidatorMaxNameSize = 64;

@interface NSURLComponents (YKFOATHCredentialTemplateParsing)

- (nullable NSString *)queryParameterValueForName:(NSString *)name;

@end

@implementation NSURLComponents (YKFOATHCredentialTemplateParsing)

- (nullable NSString *)queryParameterValueForName:(NSString *)name {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    return [self.queryItems filteredArrayUsingPredicate:predicate].firstObject.value;
}

@end

@interface YKFOATHCredentialTemplateError : NSError

+ (instancetype)ykfErrorWithCode:(YKFOATHCredentialTemplateErrorCode)code;

@end

@implementation YKFOATHCredentialTemplateError

+ (instancetype)ykfErrorWithCode:(YKFOATHCredentialTemplateErrorCode)code {
    NSString *message;
    switch (code) {
        case YKFOATHCredentialTemplateErrorCodeScheme:
            message = @"Missing scheme in URL";
            break;
        case YKFOATHCredentialTemplateErrorCodeType:
            message = @"Failed to get account type from URL";
            break;
        case YKFOATHCredentialTemplateErrorCodeLabel:
            message = @"Missing account name";
            break;
        case YKFOATHCredentialTemplateErrorCodeAlgorithm:
            message = @"Unknown algorithm";
            break;
        case YKFOATHCredentialTemplateErrorCodeCounter:
            message = @"Missing counter parameter";
            break;
        case YKFOATHCredentialTemplateErrorCodeDigits:
            message = @"Unsupported number of digits";
            break;
        case YKFOATHCredentialTemplateErrorCodeMissingSecret:
            message = @"Missing secret";
            break;
        case YKFOATHCredentialTemplateErrorCodeInvalidSecret:
            message = @"Invalid Base32 encoded secret";
            break;
        case YKFOATHCredentialTemplateErrorNameIssuerToLong:
            message = @"Account name and issuer is to long";
            break;
        case YKFOATHCredentialTemplateErrorIssuerContainsColon:
            message = @"Character ':' is not allowed in issuer";
            break;
    }
    return [[YKFOATHCredentialTemplateError alloc] initWithDomain:YKFOATHCredentialTemplateErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

@end


@interface YKFOATHCredentialTemplate ()
@property (nonatomic) YKFOATHCredentialType type;
@property (nonatomic) YKFOATHCredentialAlgorithm algorithm;
@property (nonatomic) NSData *secret;
@property (nonatomic) NSString *issuer;
@property (nonatomic) NSUInteger digits;
@property (nonatomic) NSUInteger period;
@property (nonatomic) UInt32 counter;
@property (nonatomic) NSString *accountName;
@end

@implementation YKFOATHCredentialTemplate

- (instancetype)initWithURL:(NSURL *)url skipValidation:(YKFOATHCredentialTemplateValidation)skipValidation error:(NSError **)error {
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    
    // Scheme
    if (![urlComponents.scheme isEqualToString:YKFOATHCredentialScheme]) {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeScheme];
        return nil;
    }
    
    // Parse account name and issuer
    if (!(skipValidation & YKFOATHCredentialTemplateValidationLabel) && urlComponents.path.length < 2) {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeLabel];
        return nil;
    }
    
    if (urlComponents.path.length < 1) {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeLabel];
        return nil;
    }
    
    NSString *name = [urlComponents.path substringFromIndex:1];
    NSString *issuer = [urlComponents queryParameterValueForName:YKFOATHCredentialURLParameterIssuer];
    if ([name containsString:@":"]) {
        NSMutableArray *labelComponents = [[name componentsSeparatedByString:@":"] mutableCopy];
        issuer = labelComponents.firstObject;
        if (labelComponents.count == 2) {
            name = labelComponents.lastObject;
        } else {
            [labelComponents removeObjectAtIndex:0];
            name = [labelComponents componentsJoinedByString:@":"];
        }
    }
    
    // OATH Type
    YKFOATHCredentialType type;
    if ([urlComponents.host isEqualToString:YKFOATHCredentialURLTypeHOTP]) {
        type = YKFOATHCredentialTypeHOTP;
    } else if ([urlComponents.host isEqualToString:YKFOATHCredentialURLTypeTOTP]) {
        type = YKFOATHCredentialTypeTOTP;
    } else {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeType];
        return nil;
    }
    
    // Algorithm
    YKFOATHCredentialAlgorithm algorithm;
    NSString *algorithmString = [urlComponents queryParameterValueForName:YKFOATHCredentialURLParameterAlgorithm];
    if (!algorithmString || [algorithmString isEqualToString:YKFOATHCredentialURLParameterValueSHA1]) {
        algorithm = YKFOATHCredentialAlgorithmSHA1;
    } else if ([algorithmString isEqualToString:YKFOATHCredentialURLParameterValueSHA256]) {
        algorithm = YKFOATHCredentialAlgorithmSHA256;
    } else if ([algorithmString isEqualToString:YKFOATHCredentialURLParameterValueSHA512]) {
        algorithm = YKFOATHCredentialAlgorithmSHA512;
    } else {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeAlgorithm];
        return nil;
    }
    
    // Number of digits
    NSUInteger digits = YKFOATHCredentialDefaultDigits;
    NSString *digitsString = [urlComponents queryParameterValueForName:YKFOATHCredentialURLParameterDigits];
    if (digitsString) {
        digits = [digitsString intValue];
    }
    
    // Period
    NSUInteger period = 0;
    if (type == YKFOATHCredentialTypeTOTP) {
        period = YKFOATHCredentialDefaultPeriod;
        NSString *periodString = [urlComponents queryParameterValueForName:YKFOATHCredentialURLParameterPeriod];
        if (periodString) {
            period = [periodString intValue];
        }
    }
    
    // Counter
    UInt32 counter = 0;
    if (type == YKFOATHCredentialTypeHOTP) {
        NSString *counterString = [urlComponents queryParameterValueForName:YKFOATHCredentialURLParameterCounter];
        if (counterString) {
            counter = MAX(0, [counterString intValue]);
        } else {
            *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeCounter];
            return nil;
        }
    }
    
    // Secret
    NSData *secret;
    NSString *base32EncodedSecret = [urlComponents queryParameterValueForName:YKFOATHCredentialURLParameterSecret];
    if (!base32EncodedSecret) {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeMissingSecret];
        return nil;
    }
    secret = [NSData ykf_dataWithBase32String:base32EncodedSecret];
    if (!secret.length) {
        *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeInvalidSecret];
        return nil;
    }
    
    return [self initWithType:type
                    algorithm:algorithm
                       secret:secret
                       issuer:issuer
                  accountName:name
                       digits:digits
                       period:period
                      counter:counter
               skipValidation:skipValidation
                        error:error];
}

- (instancetype)initWithURL:(NSURL *)url error:(NSError **)error {
    return [self initWithURL:url skipValidation:0 error:error];
}

- (instancetype)initWithURL:(NSURL *)url {
    NSError *ignoreError;
    return [self initWithURL:url skipValidation:0 error:&ignoreError];
}

- (instancetype)initWithType:(YKFOATHCredentialType)type
                   algorithm:(YKFOATHCredentialAlgorithm)algorithm
                      secret:(NSData *)secret
                      issuer:(NSString *_Nullable)issuer
                 accountName:(NSString *)accountName
                      digits:(NSUInteger)digits
                      period:(NSUInteger)period
                     counter:(UInt32)counter
              skipValidation:(YKFOATHCredentialTemplateValidation)skipValidation
                       error:(NSError **)error {
    self = [super init];
    if (self) {
        _type = type;
        _algorithm = algorithm;
        
        if (secret.length == 0) {
            *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeMissingSecret];
            return nil;
        }
        if (secret.length < YKFOATHCredentialMinSecretLength) {
            NSMutableData *paddedSecret = [[NSMutableData alloc] initWithData:secret];
            [paddedSecret increaseLengthBy: YKFOATHCredentialMinSecretLength - secret.length];
            _secret = paddedSecret;
        } else {
            switch (self.algorithm) {
                case YKFOATHCredentialAlgorithmSHA1:
                    if (secret.length > CC_SHA1_BLOCK_BYTES) {
                        _secret = [secret ykf_SHA1];
                    } else {
                        _secret = secret;
                    }
                    break;
                case YKFOATHCredentialAlgorithmSHA256:
                    if (secret.length > CC_SHA256_BLOCK_BYTES) {
                        _secret = [secret ykf_SHA256];
                    } else {
                        _secret = secret;
                    }
                    break;
                case YKFOATHCredentialAlgorithmSHA512:
                    if (secret.length > CC_SHA512_BLOCK_BYTES) {
                        _secret = [secret ykf_SHA512];
                    } else {
                        _secret = secret;
                    }
                    break;
                default:
                    *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeAlgorithm];
                    return nil;
            }
        }
        
        _period = period;
        _issuer = issuer;
        _accountName = accountName;

        // Digits
        if (digits == 6 || digits == 7 || digits == 8) {
            _digits = digits;
        } else {
            *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeDigits];
            return nil;
        }
        _counter = counter;
        
        if (!(skipValidation & YKFOATHCredentialTemplateValidationIssuer) && [_issuer containsString:@":"]) {
            *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorIssuerContainsColon];
            return nil;
        }

        if (!(skipValidation & YKFOATHCredentialTemplateValidationLabel) && !_accountName.length) {
            *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorCodeLabel];
            return nil;
        }
        
        NSString *key = [YKFOATHCredentialUtils keyFromAccountName:_accountName issuer:_issuer period:_period type:_type];
        if (!(skipValidation & YKFOATHCredentialTemplateValidationLabel) && key.length > YKFOATHCredentialValidatorMaxNameSize) {
            *error = [YKFOATHCredentialTemplateError ykfErrorWithCode:YKFOATHCredentialTemplateErrorNameIssuerToLong];
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithType:(YKFOATHCredentialType)type
                   algorithm:(YKFOATHCredentialAlgorithm)algorithm
                      secret:(NSData *)secret
                      issuer:(NSString *_Nullable)issuer
                 accountName:(NSString *)accountName
                      digits:(NSUInteger)digits
                      period:(NSUInteger)period
                     counter:(UInt32)counter
                       error:(NSError **)error {
    return [self initWithType:type algorithm:algorithm secret:secret issuer:issuer accountName:accountName digits:digits period:period counter:counter skipValidation:0 error:error];
}

- (instancetype)initWithType:(YKFOATHCredentialType)type
                   algorithm:(YKFOATHCredentialAlgorithm)algorithm
                      secret:(NSData *)secret
                      issuer:(NSString *_Nullable)issuer
                 accountName:(NSString *)accountName
                      digits:(NSUInteger)digits
                      period:(NSUInteger)period
                     counter:(UInt32)counter {
    NSError *ignoreError;
    return [self initWithType:type algorithm:algorithm secret:secret issuer:issuer accountName:accountName digits:digits period:period counter:counter skipValidation:0 error:&ignoreError];
}

- (instancetype)initTOTPWithAlgorithm:(YKFOATHCredentialAlgorithm)algorithm
                               secret:(NSData *)secret
                               issuer:(NSString *_Nullable)issuer
                          accountName:(NSString *)accountName {
    return [self initTOTPWithAlgorithm:algorithm
                                secret:secret
                                issuer:issuer
                           accountName:accountName
                                digits:YKFOATHCredentialDefaultDigits
                                period:YKFOATHCredentialDefaultPeriod];
}

- (instancetype)initTOTPWithAlgorithm:(YKFOATHCredentialAlgorithm)algorithm
                               secret:(NSData *)secret
                               issuer:(NSString *_Nullable)issuer
                          accountName:(NSString *)accountName
                               digits:(NSUInteger)digits
                               period:(NSUInteger)period {
    return [self initWithType:YKFOATHCredentialTypeTOTP
                    algorithm:algorithm
                       secret:secret
                       issuer:issuer
                  accountName:accountName
                       digits:digits
                       period:period
                      counter:0];
}

- (instancetype)initHOTPWithAlgorithm:(YKFOATHCredentialAlgorithm)algorithm
                               secret:(NSData *)secret
                               issuer:(NSString *_Nullable)issuer
                              accountName:(NSString *)accountName {
    return [self initHOTPWithAlgorithm:algorithm
                                secret:secret
                                issuer:issuer
                               accountName:accountName
                                digits:YKFOATHCredentialDefaultDigits
                               counter:0];
}

- (instancetype)initHOTPWithAlgorithm:(YKFOATHCredentialAlgorithm)algorithm
                               secret:(NSData *)secret
                               issuer:(NSString *_Nullable)issuer
                          accountName:(NSString *)accountName
                               digits:(NSUInteger)digits
                              counter:(UInt32)counter {
    return [self initWithType:YKFOATHCredentialTypeHOTP
                    algorithm:algorithm
                       secret:secret
                       issuer:issuer
                  accountName:accountName
                       digits:digits
                       period:0
                      counter:counter];
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    YKFOATHCredentialTemplate *copy = [YKFOATHCredentialTemplate new];
    copy.accountName = [self.accountName copyWithZone:zone];
    copy.issuer = [self.issuer copyWithZone:zone];
    copy.period = self.period;
    copy.digits = self.digits;
    copy.type = self.type;
    copy.algorithm = self.algorithm;
    copy.counter = self.counter;
    if (self.secret) {
        copy.secret = [self.secret copyWithZone:zone];
    }
    return copy;
}

@end
