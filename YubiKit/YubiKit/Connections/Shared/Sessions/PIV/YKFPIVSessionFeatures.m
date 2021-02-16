// Copyright 2018-2021 Yubico AB
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
#import "YKFPIVSessionFeatures.h"
#import "YKFFeature.h"

@interface YKFPIVSessionFeatures()
    @property (nonatomic, readwrite) YKFFeature * _Nonnull serial;
    @property (nonatomic, readwrite) YKFFeature * _Nonnull metadata;
@end

@implementation YKFPIVSessionFeatures

- (instancetype)init {
    self = [super init];
    if (self) {
        self.serial = [[YKFFeature alloc] initWithName:@"Serial number" versionString:@"5.0.0"];
        self.metadata = [[YKFFeature alloc] initWithName:@"Metadata" versionString:@"5.3.0"];
    }
    return self;
}

@end
