// Copyright 2018-2020 Yubico AB
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

@class YKFOATHSession, YKFU2FSession, YKFFIDO2Session, YKFPIVSession, YKFChallengeResponseSession, YKFManagementSession, YKFSmartCardInterface;

@protocol YKFConnectionProtocol<NSObject>

typedef void (^YKFOATHSessionCallback)(YKFOATHSession *_Nullable, NSError* _Nullable);
- (void)oathSession:(YKFOATHSessionCallback _Nonnull)callback;

typedef void (^YKFU2FSessionCallback)(YKFU2FSession *_Nullable, NSError* _Nullable);
- (void)u2fSession:(YKFU2FSessionCallback _Nonnull)callback;

typedef void (^YKFFIDO2SessionCallback)(YKFFIDO2Session *_Nullable, NSError* _Nullable);
- (void)fido2Session:(YKFFIDO2SessionCallback _Nonnull)callback;

typedef void (^YKFPIVSessionCallback)(YKFPIVSession *_Nullable, NSError* _Nullable);
- (void)pivSession:(YKFPIVSessionCallback _Nonnull)callback;

typedef void (^YKFChallengeResponseSessionCallback)(YKFChallengeResponseSession *_Nullable, NSError* _Nullable);
- (void)challengeResponseSession:(YKFChallengeResponseSessionCallback _Nonnull)callback;

typedef void (^YKFManagementSessionCallback)(YKFManagementSession *_Nullable, NSError* _Nullable);
- (void)managementSession:(YKFManagementSessionCallback _Nonnull)callback;

@property (nonatomic, readonly) YKFSmartCardInterface *_Nullable smartCardInterface;

@end
