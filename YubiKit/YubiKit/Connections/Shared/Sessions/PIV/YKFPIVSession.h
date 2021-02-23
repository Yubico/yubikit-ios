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

#ifndef YKFPIVSession_h
#define YKFPIVSession_h

#import "YKFVersion.h"

@class YKFPIVSessionFeatures;

typedef void (^YKFPIVSessionCompletionBlock)
    (NSError* _Nullable error);

typedef void (^YKFPIVSessionSerialNumberCompletionBlock)
    (int serialNumber, NSError* _Nullable error);

typedef void (^YKFPIVSessionVerifyPinCompletionBlock)
    (int retries, NSError* _Nullable error);

typedef void (^YKFPIVSessionPinPukMetadataCompletionBlock)
    (bool isDefault, int retriesTotal, int retriesRemaining, NSError* _Nullable error);

@interface YKFPIVSession: NSObject <YKFVersionProtocol>

@property (nonatomic, readonly) YKFVersion * _Nonnull version;
@property (nonatomic, readonly) YKFPIVSessionFeatures * _Nonnull features;

- (void)resetWithCompletion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)verifyPin:(nonnull NSString *)pin completion:(nonnull YKFPIVSessionVerifyPinCompletionBlock)completion;

- (void)getSerialNumberWithCompletion:(nonnull YKFPIVSessionSerialNumberCompletionBlock)completion;

- (void)getPinMetadata:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion;

- (void)getPukMetadata:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion;

/*
 Not available: use only the instance from the YKFAccessorySession.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end

#endif
