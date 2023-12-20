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

#import "YKFNSStringAdditions.h"

@implementation NSString(NSString_OATH)

- (void)ykf_OATHKeyExtractForType:(YKFOATHCredentialType)type period:(NSUInteger *)period issuer:(NSString **)issuer account:(NSString **)account {
    
    if (type == YKFOATHCredentialTypeTOTP) {
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^((\\d+)/)?(([^:]+):)?(.+)$"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        if (error != nil) { [NSException raise:@"Malformed regex" format:@"Built in regex for parsing yubikey keys is malformed."]; }
        
        NSTextCheckingResult *match = [regex matchesInString:self
                                                       options:0
                                                         range:NSMakeRange(0, [self length])].firstObject;
        if (match != nil) {
            NSRange periodRange = [match rangeAtIndex:2];
            if (periodRange.location != NSNotFound) {
                *period = [self substringWithRange:periodRange].intValue;
            }
            NSRange issuerRange = [match rangeAtIndex:4];
            if (issuerRange.location != NSNotFound) {
                *issuer = [self substringWithRange:issuerRange];
            }
            NSRange accountRange = [match rangeAtIndex:5];
            if (accountRange.location != NSNotFound) {
                *account = [self substringWithRange:accountRange];
            }
        } else {
            //Invalid id, use it directly as name.
            *account = self;
        }
    } else {
        if ([self containsString: @":"]) {
            NSArray<NSString*> *parts = [self componentsSeparatedByString:@":"];
            *issuer = parts[0];
            *account = parts[1];
        } else {
            *account = self;
        }
    }
}

@end
