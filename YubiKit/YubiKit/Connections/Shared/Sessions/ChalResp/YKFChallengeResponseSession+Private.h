// Copyright 2018-2019 Yubico AB
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
#import "YKFSessionProtocol+Private.h"
#import "YKFChallengeResponseSession.h"

@protocol YKFConnectionControllerProtocol, YKFSCPKeyParamsProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface YKFChallengeResponseSession()<YKFSessionProtocol>

typedef void (^YKFChallengeResponseSessionCompletion)(YKFChallengeResponseSession *_Nullable, NSError* _Nullable);
+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                               completion:(YKFChallengeResponseSessionCompletion _Nonnull)completion;

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                           scpKeyParams:(nonnull id<YKFSCPKeyParamsProtocol>)scpKeyParams
                             completion:(YKFChallengeResponseSessionCompletion _Nonnull)completion;

@end

NS_ASSUME_NONNULL_END

