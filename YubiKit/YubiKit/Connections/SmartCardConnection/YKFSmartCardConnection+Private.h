// Copyright 2018-2022 Yubico AB
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

#import "YKFSmartCardConnection.h"

#ifndef YKFSmartCardConnecton_Private_h
#define YKFSmartCardConnecton_Private_h

@protocol YKFSmartCardConnectionDelegate <NSObject>

- (void)didConnectSmartCard:(YKFSmartCardConnection *_Nonnull)connection;
- (void)didDisconnectSmartCard:(YKFSmartCardConnection *_Nonnull)connection error:(NSError *_Nullable)error;
- (void)didFailConnectingSmartCard:(NSError *_Nonnull)error;

@end

@interface YKFSmartCardConnection()

@property (nonatomic, readonly) YKFSmartCardConnectionState state;
@property(nonatomic, weak) id<YKFSmartCardConnectionDelegate> _Nullable delegate;

/*
 Hidden initializer to avoid the creation of multiple instances outside YubiKit.
 */
- (nullable instancetype)initWithDelegate:(nonnull id<YKFSmartCardConnectionDelegate>)delegate;

@end

#endif /* YKFSmartCardConnecton_Private_h */
