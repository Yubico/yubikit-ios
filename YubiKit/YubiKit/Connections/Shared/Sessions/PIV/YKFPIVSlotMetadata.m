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
#import "YKFPIVSlotMetadata.h"

@interface YKFPIVSlotMetadata()

@property (nonatomic, readwrite) YKFPIVKeyType keyType;
@property (nonatomic, readwrite) YKFPIVPinPolicy pinPolicy;
@property (nonatomic, readwrite) YKFPIVTouchPolicy touchPolicy;
@property (nonatomic, readwrite) SecKeyRef publicKey;
@property (nonatomic, readwrite) bool generated;

@end

@implementation YKFPIVSlotMetadata

- (instancetype)initWithKeyType:(YKFPIVKeyType)keyType publicKey:(SecKeyRef)publicKey pinPolicy:(YKFPIVPinPolicy)pinPolicy touchPolicy:(YKFPIVTouchPolicy)touchPolicy generated:(bool)generated {
    self = [super init];
    if (self) {
        self.keyType = keyType;
        self.publicKey = publicKey;
        self.pinPolicy = pinPolicy;
        self.touchPolicy = touchPolicy;
        self.generated = generated;
    }
    return self;
};

@end
