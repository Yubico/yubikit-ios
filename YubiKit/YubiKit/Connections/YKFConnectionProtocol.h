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

@class YKFKeyOATHSession, YKFKeyU2FSession, YKFKeyFIDO2Session, YKFKeyRawCommandSession, YKFKeyChallengeResponseSession, YKFKeyManagementSession;

@protocol YKFConnectionProtocol<NSObject>

typedef void (^OATHSession)(YKFKeyOATHSession *_Nullable, NSError* _Nullable);
- (void)oathSession:(OATHSession _Nonnull)callback;

typedef void (^U2FSession)(YKFKeyU2FSession *_Nullable, NSError* _Nullable);
- (void)u2fSession:(U2FSession _Nonnull)callback;

typedef void (^FIDO2Session)(YKFKeyFIDO2Session *_Nullable, NSError* _Nullable);
- (void)fido2Session:(FIDO2Session _Nonnull)callback;

typedef void (^RawCommandSession)(YKFKeyRawCommandSession *_Nullable, NSError* _Nullable);
- (void)rawCommandSession:(RawCommandSession _Nonnull)callback;

typedef void (^ChallengeResponseSession)(YKFKeyChallengeResponseSession *_Nullable, NSError* _Nullable);
- (void)challengeResponseSession:(ChallengeResponseSession _Nonnull)callback;

typedef void (^ManagementSession)(YKFKeyManagementSession *_Nullable, NSError* _Nullable);
- (void)managementSession:(ManagementSession _Nonnull)callback;

@end
