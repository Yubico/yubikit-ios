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

#import "YKFSCPStaticKeys.h"
#import "YKFNSDataAdditions+Private.h"

@implementation YKFSCPStaticKeys

static NSData *defaultKey;

+ (void)initialize {
    if (self == [YKFSCPStaticKeys class]) {
        uint8_t defaultKeyBytes[] = {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
                                     0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f};
        defaultKey = [NSData dataWithBytes:defaultKeyBytes length:sizeof(defaultKeyBytes)];
    }
}

- (instancetype)initWithEnc:(NSData *)enc mac:(NSData *)mac dek:(NSData * _Nullable)dek {
    self = [super init];
    if (self) {
        _enc = enc;
        _mac = mac;
        _dek = dek;
    }
    return self;
}

- (YKFSCPSessionKeys *)deriveWithContext:(NSData *)context {
    NSError *error = nil;
    NSData *senc = [YKFSCPStaticKeys deriveKeyWithKey:self.enc t:0x4 context:context l:0x80 error:&error];
    NSData *smac = [YKFSCPStaticKeys deriveKeyWithKey:self.mac t:0x6 context:context l:0x80 error:&error];
    NSData *srmac = [YKFSCPStaticKeys deriveKeyWithKey:self.mac t:0x7 context:context l:0x80 error:&error];

    if (error) {
        NSLog(@"Error deriving keys: %@", error.localizedDescription);
        return nil;
    }

    return [[YKFSCPSessionKeys alloc] initWithSenc:senc smac:smac srmac:srmac dek:self.dek];
}

+ (instancetype)defaultKeys {
    return [[YKFSCPStaticKeys alloc] initWithEnc:defaultKey mac:defaultKey dek:defaultKey];
}

+ (NSData *)deriveKeyWithKey:(NSData *)key t:(int8_t)t context:(NSData *)context l:(int16_t)l error:(NSError **)error {
    if (l != 0x40 && l != 0x80) {
        if (error) {
            *error = [NSError errorWithDomain:@"StaticKeysError" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Invalid argument"}];
        }
        return nil;
    }

    NSMutableData *i = [NSMutableData dataWithLength:11];
    uint8_t tBytes = t;
    uint8_t zeroByte = 0;
    uint16_t lBigEndian = CFSwapInt16HostToBig(l);
    uint8_t oneByte = 1;

    [i appendBytes:&tBytes length:sizeof(tBytes)];
    [i appendBytes:&zeroByte length:sizeof(zeroByte)];
    [i appendBytes:&lBigEndian length:sizeof(lBigEndian)];
    [i appendBytes:&oneByte length:sizeof(oneByte)];
    [i appendData:context];

    NSData *digest = [i ykf_aesCMACWithKey:key];
    return [digest subdataWithRange:NSMakeRange(0, l / 8)];
}

@end
