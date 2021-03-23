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
#import "YKFPIVKeyType.h"

typedef NS_ENUM(NSUInteger, YKFPIVSlot) {
    YKFPIVSlotAuthentication = 0x9a,
    YKFPIVSlotSignature = 0x9c,
    YKFPIVSlotKeyManagement = 0x9d,
    YKFPIVSlotCardAuth = 0x9e,
    YKFPIVSlotAttestation = 0xf9
};

@class YKFPIVSessionFeatures, YKFPIVManagementKeyType, YKFPIVManagementKeyMetadata;

NS_ASSUME_NONNULL_BEGIN

typedef void (^YKFPIVSessionCompletionBlock)
    (NSError* _Nullable error);

typedef void (^YKFPIVSessionSignCompletionBlock)
    (NSData* _Nullable signature, NSError* _Nullable error);

typedef void (^YKFPIVSessionDecryptCompletionBlock)
    (NSData* _Nullable decrypted, NSError* _Nullable error);

typedef void (^YKFPIVSessionCalculateSecretCompletionBlock)
    (NSData* _Nullable secret, NSError* _Nullable error);

typedef void (^YKFPIVSessionAttestKeyCompletionBlock)
    (SecCertificateRef _Nullable certificate, NSError* _Nullable error);

typedef void (^YKFPIVSessionReadKeyCompletionBlock)
    (SecKeyRef _Nullable key, NSError* _Nullable error);

typedef void (^YKFPIVSessionReadCertCompletionBlock)
    (SecCertificateRef _Nullable cert, NSError* _Nullable error);

typedef void (^YKFPIVSessionSerialNumberCompletionBlock)
    (int serialNumber, NSError* _Nullable error);

typedef void (^YKFPIVSessionVerifyPinCompletionBlock)
    (int retries, NSError* _Nullable error);

typedef void (^YKFPIVSessionPinPukMetadataCompletionBlock)
    (bool isDefault, int retriesTotal, int retriesRemaining, NSError* _Nullable error);

typedef void (^YKFPIVSessionPinAttemptsCompletionBlock)
    (int retriesRemaining, NSError* _Nullable error);

typedef void (^YKFPIVSessionManagementKeyMetadataCompletionBlock)
    (YKFPIVManagementKeyMetadata* _Nullable metaData, NSError* _Nullable error);

@interface YKFPIVSession: NSObject <YKFVersionProtocol>

@property (nonatomic, readonly) YKFVersion * _Nonnull version;
@property (nonatomic, readonly) YKFPIVSessionFeatures * _Nonnull features;

- (void)signWithKeyInSlot:(YKFPIVSlot)slot type:(YKFPIVKeyType)keyType algorithm:(SecKeyAlgorithm)algorithm message:(nonnull NSData *)message completion:(nonnull YKFPIVSessionSignCompletionBlock)completion;

- (void)decryptWithKeyInSlot:(YKFPIVSlot)slot algorithm:(SecKeyAlgorithm)algorithm encrypted:(nonnull NSData *)encrypted completion:(nonnull YKFPIVSessionDecryptCompletionBlock)completion;

- (void)calculateSecretKeyInSlot:(YKFPIVSlot)slot peerPublicKey:(SecKeyRef)peerPublicKey completion:(nonnull YKFPIVSessionCalculateSecretCompletionBlock)completion;

- (void)attestKeyInSlot:(YKFPIVSlot)slot completion:(nonnull YKFPIVSessionAttestKeyCompletionBlock)completion;

- (void)generateKeyInSlot:(YKFPIVSlot)slot type:(YKFPIVKeyType)type completion:(nonnull YKFPIVSessionReadKeyCompletionBlock)completion;

- (void)putCertificate:(SecCertificateRef)certificate inSlot:(YKFPIVSlot)slot completion:(YKFPIVSessionCompletionBlock)completion;

- (void)readCertificateFromSlot:(YKFPIVSlot)slot completion:(nonnull YKFPIVSessionReadCertCompletionBlock)completion;

- (void)deleteCertificateInSlot:(YKFPIVSlot)slot completion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)setManagementKey:(nonnull NSData *)managementKey type:(nonnull YKFPIVManagementKeyType *)type requiresTouch:(BOOL)requiresTouch completion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)authenticateWithManagementKey:(nonnull NSData *)managementKey keyType:(nonnull YKFPIVManagementKeyType *)keyType completion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)resetWithCompletion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)verifyPin:(nonnull NSString *)pin completion:(nonnull YKFPIVSessionVerifyPinCompletionBlock)completion;

- (void)setPin:(nonnull NSString *)pin oldPin:(nonnull NSString *)oldPin completion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)setPuk:(nonnull NSString *)puk oldPuk:(nonnull NSString *)oldPuk completion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)unblockPin:(nonnull NSString *)puk newPin:(nonnull NSString *)newPin completion:(nonnull YKFPIVSessionCompletionBlock)completion;

- (void)getSerialNumberWithCompletion:(nonnull YKFPIVSessionSerialNumberCompletionBlock)completion;

- (void)getManagementKeyMetadata:(nonnull YKFPIVSessionManagementKeyMetadataCompletionBlock)completion;

- (void)getPinMetadata:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion;

- (void)getPukMetadata:(nonnull YKFPIVSessionPinPukMetadataCompletionBlock)completion;

- (void)getPinAttempts:(nonnull YKFPIVSessionPinAttemptsCompletionBlock)completion;

- (void)setPinAttempts:(int)pinAttempts pukAttempts:(int)pukAttempts completion:(nonnull YKFPIVSessionCompletionBlock)completion;

/*
 Not available: use only the instance from the YKFAccessorySession.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end

#endif
