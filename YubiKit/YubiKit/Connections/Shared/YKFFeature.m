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
#import "YKFFeature.h"
#import "YKFAssert.h"

@interface YKFFeature()

@property (nonatomic, retain, readwrite) NSString * _Nonnull name;
@property (nonatomic, retain, readwrite) YKFVersion * _Nonnull version;

@end

@implementation YKFFeature


- (instancetype)initWithName:(NSString *)name version:(YKFVersion *)version {
    self = [super init];
    if (self) {
        self.name = name;
        self.version = version;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name versionString:(NSString *)versionString {
    NSArray *versions = [versionString componentsSeparatedByString:@"."];
    if (versions.count != 3) {
        [NSException raise:@"Malformed version string" format:@"%@ is not a valid version string", versionString];
    }
    return [self initWithName:name version:[[YKFVersion alloc] initWithBytes:[versions[0] intValue] minor:[versions[1] intValue] micro:[versions[2] intValue]]];
}

- (bool)isSupportedBySession:(nonnull id<YKFVersionProtocol>)session {
    NSComparisonResult comparision = [session.version compare:self.version];
    return (comparision == NSOrderedSame || comparision == NSOrderedDescending);
}

@end
