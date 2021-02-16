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

#ifndef YKFFeature_h
#define YKFFeature_h

#import "YKFVersion.h"

@interface YKFFeature: NSObject

@property (nonatomic, retain, readonly) NSString * _Nonnull name;
@property (nonatomic, retain, readonly) YKFVersion * _Nonnull version;

- (instancetype _Nonnull )initWithName:(NSString *_Nonnull)name version:(YKFVersion *_Nonnull)version;
- (instancetype _Nonnull )initWithName:(NSString *_Nonnull)name versionString:(NSString *_Nonnull)version;

- (bool)isSupportedBySession:(nonnull id<YKFVersionProtocol>)session;

@end

#endif /* YKFFeature_h */
