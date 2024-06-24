// Copyright 2018-2024 Yubico AB
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
#import "YKFPIVKeyType.h"

YKFPIVKeyType YKFPIVKeyTypeFromKey(SecKeyRef key) {
    NSDictionary *attributes = (__bridge NSDictionary*)SecKeyCopyAttributes(key);
    long size = [attributes[(__bridge NSString*)kSecAttrKeySizeInBits] integerValue];
    NSString *type = attributes[(__bridge NSString*)kSecAttrKeyType];
    if ([type isEqual:(__bridge NSString*)kSecAttrKeyTypeRSA]) {
        if (size == 1024) {
            return YKFPIVKeyTypeRSA1024;
        }
        if (size == 2048) {
            return YKFPIVKeyTypeRSA2048;
        }
        if (size == 3072) {
            return YKFPIVKeyTypeRSA3072;
        }
        if (size == 4096) {
            return YKFPIVKeyTypeRSA4096;
        }
    }
    if ([type isEqual:(__bridge NSString*)kSecAttrKeyTypeEC]) {
        if (size == 256) {
            return YKFPIVKeyTypeECCP256;
        }
        if (size == 384) {
            return YKFPIVKeyTypeECCP384;
        }
    }
    return YKFPIVKeyTypeUnknown;
}


int YKFPIVSizeFromKeyType(YKFPIVKeyType keyType) {
    switch (keyType) {
        case YKFPIVKeyTypeECCP256:
            return 256 / 8;
        case YKFPIVKeyTypeECCP384:
            return 384 / 8;
        case YKFPIVKeyTypeRSA1024:
            return 1024 / 8;
        case YKFPIVKeyTypeRSA2048:
            return 2048 / 8;
        case YKFPIVKeyTypeRSA3072:
            return 3072 / 8;
        case YKFPIVKeyTypeRSA4096:
            return 4096 / 8;
        default:
            return 0;
    }
}
