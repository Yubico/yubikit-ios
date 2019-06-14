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

#import "YKFOATHCredential.h"
#import "YKFOATHCredential+Private.h"
#import "YKFAssert.h"
#import "MF_Base32Additions.h"

static NSUInteger const YKFOATHCredentialDefaultDigits = 6;
static NSUInteger const YKFOATHCredentialDefaultPeriod = 30; // seconds

static NSString* const YKFOATHCredentialScheme = @"otpauth";

static NSString* const YKFOATHCredentialURLTypeHOTP = @"hotp";
static NSString* const YKFOATHCredentialURLTypeTOTP = @"totp";

static NSString* const YKFOATHCredentialURLParameterSecret = @"secret";
static NSString* const YKFOATHCredentialURLParameterIssuer = @"issuer";
static NSString* const YKFOATHCredentialURLParameterDigits = @"digits";
static NSString* const YKFOATHCredentialURLParameterPeriod = @"period";
static NSString* const YKFOATHCredentialURLParameterCounter = @"counter";
static NSString* const YKFOATHCredentialURLParameterAlgorithm = @"algorithm";

static NSString* const YKFOATHCredentialURLParameterValueSHA1 = @"SHA1";
static NSString* const YKFOATHCredentialURLParameterValueSHA256 = @"SHA256";
static NSString* const YKFOATHCredentialURLParameterValueSHA512 = @"SHA512";

@implementation YKFOATHCredential

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        if (![self parseUrl: url]) {
            self = nil;
        }
    }
    return self;
}

#pragma mark - Properties Overrides

- (YKFOATHCredentialType)type{
    if (_type) {
        return _type;
    }
    return YKFOATHCredentialTypeHOTP;
}

- (YKFOATHCredentialAlgorithm)algorithm {
    if (_algorithm) {
        return _algorithm;
    }
    return YKFOATHCredentialAlgorithmSHA1;
}

- (NSUInteger)digits {
    if (_digits) {
        return _digits;
    }
    return YKFOATHCredentialDefaultDigits;
}

- (NSUInteger)period {
    if (_period) {
        return _period;
    }
    return self.type == YKFOATHCredentialTypeTOTP ? YKFOATHCredentialDefaultPeriod : 0;
}

- (NSString *)key {
    if (!_key) {
        if (self.type == YKFOATHCredentialTypeTOTP) {
            return [NSString stringWithFormat:@"%ld/%@", (unsigned long)self.period, self.label];
        } else {
            return self.label;
        }
    }
    return _key;
}

#pragma mark - URL Parsing

- (BOOL)parseUrl:(NSURL *)url {
    YKFParameterAssertReturnValue(url, NO);
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    
    // Check scheme
    if (![urlComponents.scheme isEqualToString:YKFOATHCredentialScheme]) {
        return NO;
    }
    
    if (![self parseTypeFromUrlComponents:urlComponents])       { return NO; }
    if (![self parseLabelFromUrlComponents:urlComponents])      { return NO; }
    if (![self parseSecretFromUrlComponents:urlComponents])     { return NO; }
    if (![self parseIssuerFromUrlComponents:urlComponents])     { return NO; }
    if (![self parseAlgorithmFromUrlComponents:urlComponents])  { return NO; }
    if (![self parseDigitsFromUrlComponents:urlComponents])     { return NO; }

    // Parse specific parameters
    if (self.type == YKFOATHCredentialTypeHOTP) {
        return [self parserHOTPParamsFromUrlComponents:urlComponents];
    } else {
        return [self parserTOTPParamsFromUrlComponents:urlComponents];
    }
}

#pragma mark - Specific Parameters

- (BOOL)parseDigitsFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *digits = [self queryParameterValueForName:YKFOATHCredentialURLParameterDigits inUrlComponents:urlComponents];
    if (digits) {
        int value = [digits intValue];
        if (value && (value == 6 || value == 8)) {
            self.digits = value;
        } else {
            return NO; // Invalid digits number
        }
    } else {
        self.digits = YKFOATHCredentialDefaultDigits;
    }
    return YES;
}

- (BOOL)parseAlgorithmFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *algorithm = [self queryParameterValueForName:YKFOATHCredentialURLParameterAlgorithm inUrlComponents:urlComponents];
    
    if (!algorithm || [algorithm isEqualToString:YKFOATHCredentialURLParameterValueSHA1]) {
        self.algorithm = YKFOATHCredentialAlgorithmSHA1;
    } else if ([algorithm isEqualToString:YKFOATHCredentialURLParameterValueSHA256]) {
        self.algorithm = YKFOATHCredentialAlgorithmSHA256;
    } else if ([algorithm isEqualToString:YKFOATHCredentialURLParameterValueSHA512]) {
        self.algorithm = YKFOATHCredentialAlgorithmSHA512;
    } else {
        return NO; // Unknown algorithm
    }
    
    return YES;
}

- (BOOL)parseIssuerFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *issuer = [self queryParameterValueForName:YKFOATHCredentialURLParameterIssuer inUrlComponents:urlComponents];
    if (issuer && self.issuer) {
        if (![issuer isEqualToString:self.issuer]) { // Malformed URI: issuers don't match
            return NO;
        }
    } else if (issuer) {
        self.issuer = issuer;
    }
    return YES;
}

- (BOOL)parseSecretFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *base32EncodedSecret = [self queryParameterValueForName:YKFOATHCredentialURLParameterSecret inUrlComponents:urlComponents];
    if (!base32EncodedSecret) {
        return NO;
    }
    self.secret = [NSData dataWithBase32String:base32EncodedSecret];
    return YES;
}

- (BOOL)parseLabelFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *label = urlComponents.path;
    label = [label stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if (!label.length) {
        return NO;
    }
    self.label = label;
    
    if ([self.label containsString:@":"]) { // Issuer is present in the label
        NSArray *labelComponents = [self.label componentsSeparatedByString:@":"];
        self.issuer = labelComponents.firstObject; // It's fine if nil
        self.account = labelComponents.lastObject;
    } else {
        self.account = label;
    }
    
    return YES;
}

- (BOOL)parseTypeFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    if ([urlComponents.host isEqualToString:YKFOATHCredentialURLTypeHOTP]) {
        self.type = YKFOATHCredentialTypeHOTP;
    } else if ([urlComponents.host isEqualToString:YKFOATHCredentialURLTypeTOTP]) {
        self.type = YKFOATHCredentialTypeTOTP;
    } else {
        return NO;
    }
    return YES;
}

- (BOOL)parserHOTPParamsFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *counter = [self queryParameterValueForName:YKFOATHCredentialURLParameterCounter inUrlComponents:urlComponents];
    if (!counter) {
        return NO;
    }
    self.counter = MAX(0, [counter intValue]);
    return YES;
}

- (BOOL)parserTOTPParamsFromUrlComponents:(NSURLComponents *)urlComponents {
    YKFParameterAssertReturnValue(urlComponents, NO);
    
    NSString *period = [self queryParameterValueForName:YKFOATHCredentialURLParameterPeriod inUrlComponents:urlComponents];
    if (period) {
        self.period = MAX(30, [period intValue]);
    }
    return YES;
}

#pragma mark - Helpers

- (NSString *)queryParameterValueForName:(NSString *)name inUrlComponents:(NSURLComponents *)urlComponents {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    return [urlComponents.queryItems filteredArrayUsingPredicate:predicate].firstObject.value;
}

@end
