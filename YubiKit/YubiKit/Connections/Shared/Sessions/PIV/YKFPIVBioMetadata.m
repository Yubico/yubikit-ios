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

#import "YKFPIVBioMetadata.h"

@interface YKFPIVBioMetadata()

@property (nonatomic, readwrite) bool isConfigured;
@property (nonatomic, readwrite) int attemptsRemaining;
@property (nonatomic, readwrite) bool temporaryPin;

@end

@implementation YKFPIVBioMetadata

- (instancetype)initWithIsConfigured:(bool)isConfigured attemptsRemaining:(int)attemptsRemaining temporaryPin:(bool)temporaryPin
{
    self = [super init];
    if (self) {
        self.isConfigured = isConfigured;
        self.attemptsRemaining = attemptsRemaining;
        self.temporaryPin = temporaryPin;
    }
    return self;
}

@end
