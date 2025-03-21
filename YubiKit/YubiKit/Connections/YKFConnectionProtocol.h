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

#ifndef YKFConnectionProtocol_h
#define YKFConnectionProtocol_h

@class YKFOATHSession, YKFU2FSession, YKFFIDO2Session, YKFPIVSession, YKFChallengeResponseSession, YKFManagementSession, YKFSecurityDomainSession, YKFSmartCardInterface, YKFAPDU;
@protocol YKFSCPKeyParamsProtocol;

@protocol YKFConnectionProtocol<NSObject>

typedef void (^YKFOATHSessionCompletionBlock)(YKFOATHSession *_Nullable, NSError* _Nullable);

/// @abstract Returns a YKFOATHSession for interacting with the OATH application on the YubiKey.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)oathSession:(YKFOATHSessionCompletionBlock _Nonnull)completion;

/// @abstract Returns a YKFOATHSession for interacting with the OATH application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)oathSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFOATHSessionCompletionBlock _Nonnull)completion;

typedef void (^YKFU2FSessionCompletionBlock)(YKFU2FSession *_Nullable, NSError* _Nullable);

/// @abstract Returns a YKFU2FSession for interacting with the U2F application on the YubiKey.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)u2fSession:(YKFU2FSessionCompletionBlock _Nonnull)completion;

/// @abstract Returns a YKFU2FSession for interacting with the U2F application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)u2fSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFU2FSessionCompletionBlock _Nonnull)completion;

typedef void (^YKFFIDO2SessionCompletionBlock)(YKFFIDO2Session *_Nullable, NSError* _Nullable);

/// @abstract Returns a YKFOATHSession for interacting with the OATH application on the YubiKey.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)fido2Session:(YKFFIDO2SessionCompletionBlock _Nonnull)completion;

/// @abstract Returns a YKFFIDO2Session for interacting with the FIDO2 application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)fido2Session:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFFIDO2SessionCompletionBlock _Nonnull)completion;

typedef void (^YKFPIVSessionCompletionBlock)(YKFPIVSession *_Nullable, NSError* _Nullable);

/// @abstract Returns a YKFPIVSession for interacting with the PIV application on the YubiKey.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)pivSession:(YKFPIVSessionCompletionBlock _Nonnull)completion;

/// @abstract Returns a YKFPIVSession for interacting with the PIV application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)pivSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFPIVSessionCompletionBlock _Nonnull)completion;

typedef void (^YKFChallengeResponseSessionCompletionBlock)(YKFChallengeResponseSession *_Nullable, NSError* _Nullable);

/// @abstract Returns a YKFChallengeResponseSession for interacting with the Challenge Response application on the YubiKey.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)challengeResponseSession:(YKFChallengeResponseSessionCompletionBlock _Nonnull)completion;

/// @abstract Returns a YKFChallengeResponseSession for interacting with the Challenge Response application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)challengeResponseSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFChallengeResponseSessionCompletionBlock _Nonnull)completion;

typedef void (^YKFManagementSessionCompletion)(YKFManagementSession *_Nullable, NSError* _Nullable);

/// @abstract Returns a YKFManagementSession for interacting with the Management application on the YubiKey.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)managementSession:(YKFManagementSessionCompletion _Nonnull)completion;

/// @abstract Returns a YKFManagementSession for interacting with the Management application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)managementSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFManagementSessionCompletion _Nonnull)completion;

typedef void (^YKFSecurityDomainSessionCompletion)(YKFSecurityDomainSession *_Nullable, NSError* _Nullable);

- (void)securityDomainSession:(YKFSecurityDomainSessionCompletion _Nonnull)completion;

/// @abstract Returns a YKFSecurityDomainSession for interacting with the Security Domain application on the YubiKey.
/// @param scpKeyParams SCP key params for the session.
/// @param completion The completion handler that gets called once the application is selected on
///                   the YubiKey. This handler is executed on a background thread.
- (void)securityDomainSession:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams completion:(YKFSecurityDomainSessionCompletion _Nonnull)completion;

/// @abstract The smart card interface to the YubiKey.
/// @discussion Use this for communicating with the YubiKey by sending APDUs to the it. Only use this
///             when none of the supplied sessions can be used.
@property (nonatomic, readonly) YKFSmartCardInterface *_Nullable smartCardInterface;

typedef void (^YKFRawComandCompletion)(NSData *_Nullable, NSError *_Nullable);

/// @abstract Send a APDU and get the unparsed result as an NSData from the YubiKey.
/// @param apdu The APDU to send to the YubiKey.
/// @param completion The unparsed result from the YubiKey or an error.
/// @discussion Use this for communicating with the YubiKey by sending APDUs to the it. Only use this
///             when the `SmartCardInterface` or any of the supplied sessions can not be used.
- (void)executeRawCommand:(NSData *_Nonnull)apdu completion:(YKFRawComandCompletion _Nonnull)completion;

/// @abstract Send command as NSData and get the unparsed result as an NSData from the YubiKey.
/// @param data The NSData to send to the YubiKey.
/// @param timeout The timeout to wait before cancelling the command sent to the YubiKey.
/// @param completion The unparsed result from the YubiKey or an error.
/// @discussion Use this for communicating with the YubiKey by sending APDUs to the it. Only use this
///             when the `SmartCardInterface` or any of the supplied sessions can not be used.
- (void)executeRawCommand:(NSData *_Nonnull)data timeout:(NSTimeInterval)timeout completion:(YKFRawComandCompletion _Nonnull)completion;

@end

#endif
