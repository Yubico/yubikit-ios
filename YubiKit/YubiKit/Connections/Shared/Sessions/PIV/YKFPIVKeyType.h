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

#ifndef YKFPIVKeyType_h
#define YKFPIVKeyType_h

typedef NS_ENUM(NSUInteger, YKFPIVKeyType) {
    YKFPIVKeyTypeRSA1024 = 0x06,
    YKFPIVKeyTypeRSA2048 = 0x07,
    YKFPIVKeyTypeRSA3072 = 0x05,
    YKFPIVKeyTypeRSA4096 = 0x16,
    YKFPIVKeyTypeECCP256 = 0x11,
    YKFPIVKeyTypeECCP384 = 0x14,
    YKFPIVKeyTypeUnknown = 0x00
};

YKFPIVKeyType YKFPIVKeyTypeFromKey(SecKeyRef key);
int YKFPIVSizeFromKeyType(YKFPIVKeyType keyType);

#endif /* YKFPIVKeyType_h */
