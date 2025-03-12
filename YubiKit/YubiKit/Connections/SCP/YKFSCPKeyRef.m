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

#import "YKFSCPKeyRef.h"

@implementation YKFSCPKeyRef

- (instancetype)initWithKid:(uint8_t)kid kvn:(uint8_t)kvn {
    if (self = [super init]) {
        _kid = kid;
        _kvn = kvn;
    }
    return self;
}

- (NSData *)data {
    uint8_t values[] = {_kid, _kvn};
    return [NSData dataWithBytes:values length:sizeof(values)];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[YKFSCPKeyRef class]]) {
        return NO;
    }
    YKFSCPKeyRef *other = (YKFSCPKeyRef *)object;
    return self.kid == other.kid && self.kvn == other.kvn;
}

- (NSUInteger)hash {
    return (self.kid << 8) | self.kvn;
}

@end
