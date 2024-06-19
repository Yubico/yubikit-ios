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

#ifndef Header_h
#define Header_h

#import "YKFPIVSlotMetadata.h"

@interface YKFPIVSlotMetadata()

- (instancetype)initWithKeyType:(YKFPIVKeyType)keyType publicKey:(SecKeyRef)publicKey pinPolicy:(YKFPIVPinPolicy)pinPolicy touchPolicy:(YKFPIVTouchPolicy)touchPolicy generated:(bool)generated NS_DESIGNATED_INITIALIZER;

@end

#endif /* Header_h */
