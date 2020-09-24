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
#import "YKFKeySession.h"
#import "YKFKeyRequest.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 Receives updates when the service performs a set of operations.
 The service can be its own delegate or it can receive forwarded updates from a central delegate.
 */
@protocol YKFKeySessionDelegate<NSObject>

- (void)keyService:(YKFKeySession *)service willExecuteRequest:(nullable YKFKeyRequest *)request;

@end

@interface YKFKeySession()<YKFKeySessionDelegate>

@property (nonatomic, weak) id<YKFKeySessionDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
