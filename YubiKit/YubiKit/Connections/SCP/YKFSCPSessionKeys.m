// Copyright Yubico AB
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

#import "YKFNSDataAdditions+Private.h"
#import "YKFSCPSessionKeys.h"

@implementation YKFSCPSessionKeys

- (instancetype)initWithSenc:(NSData *)senc smac:(NSData *)smac srmac:(NSData *)srmac dek:(NSData * _Nullable)dek {
    self = [super init];
    if (self) {
        _senc = senc;
        _smac = smac;
        _srmac = srmac;
        _dek = dek;
    }
    return self;
}

- (NSString *)debugDescription {
    NSString *sencHex = self.senc.ykf_hexadecimalString;
    NSString *smacHex = self.smac.ykf_hexadecimalString;
    NSString *srmacHex = self.srmac.ykf_hexadecimalString;
    NSString *dekHex = self.dek ? self.dek.ykf_hexadecimalString : @"nil";
    return [NSString stringWithFormat:@"YKFSCPSessionKeys(senc: %@, smac: %@, srmac: %@, dek: %@)",
            sencHex, smacHex, srmacHex, dekHex];
}

@end
