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

#import "YKFKeyFIDO2Session.h"
#import "YKFKeyFIDO2Session+Private.h"
#import "YKFAccessoryConnectionController.h"
#import "YKFKeyFIDO2Error.h"
#import "YKFKeyAPDUError.h"
#import "YKFKeyCommandConfiguration.h"
#import "YKFLogger.h"
#import "YKFBlockMacros.h"
#import "YKFNSDataAdditions.h"
#import "YKFAssert.h"

#import "YKFFIDO2PinAuthKey.h"
#import "YKFKeyFIDO2ClientPinRequest.h"
#import "YKFKeyFIDO2ClientPinResponse.h"

#import "YKFFIDO2MakeCredentialAPDU.h"
#import "YKFFIDO2GetAssertionAPDU.h"
#import "YKFFIDO2GetNextAssertionAPDU.h"
#import "YKFFIDO2TouchPoolingAPDU.h"
#import "YKFFIDO2ClientPinAPDU.h"
#import "YKFFIDO2GetInfoAPDU.h"
#import "YKFFIDO2ResetAPDU.h"

#import "YKFKeyFIDO2GetInfoResponse+Private.h"
#import "YKFKeyFIDO2MakeCredentialResponse+Private.h"
#import "YKFKeyFIDO2GetAssertionResponse+Private.h"

#import "YKFKeyFIDO2GetInfoResponse.h"
#import "YKFKeyFIDO2MakeCredentialResponse.h"
#import "YKFKeyFIDO2GetAssertionResponse.h"

#import "YKFNSDataAdditions+Private.h"
#import "YKFKeySessionError+Private.h"

#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

static const int YKFKeyFIDO2RequestMaxRetries = 30; // times
static const NSTimeInterval YKFKeyFIDO2RequestRetryTimeInterval = 0.5; // seconds
NSString* const YKFKeyFIDO2OptionRK = @"rk";
NSString* const YKFKeyFIDO2OptionUV = @"uv";
NSString* const YKFKeyFIDO2OptionUP = @"up";

#pragma mark - Private Response Blocks

typedef void (^YKFKeyFIDO2SessionResultCompletionBlock)
    (NSData* _Nullable response, NSError* _Nullable error);

typedef void (^YKFKeyFIDO2SessionClientPinCompletionBlock)
    (YKFKeyFIDO2ClientPinResponse* _Nullable response, NSError* _Nullable error);

typedef void (^YKFKeyFIDO2SessionClientPinSharedSecretCompletionBlock)
    (NSData* _Nullable sharedSecret, YKFCBORMap* _Nullable cosePlatformPublicKey, NSError* _Nullable error);

#pragma mark - YKFKeyFIDO2Session

@interface YKFKeyFIDO2Session()

@property (nonatomic, assign, readwrite) YKFKeyFIDO2SessionKeyState keyState;

// The cached authenticator pinToken, assigned after a successful validation.
@property NSData *pinToken;
// Keeps the state of the application selection to avoid reselecting the application.
@property BOOL applicationSelected;

@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

@end

@implementation YKFKeyFIDO2Session

@synthesize delegate;

+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyFIDO2SessionCompletion _Nonnull)completion {
    
    YKFKeyFIDO2Session *session = [YKFKeyFIDO2Session new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];

    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameFIDO2];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            [session updateKeyState:YKFKeyFIDO2SessionKeyStateIdle];
            completion(session, nil);
        }
    }];
}

- (void)clearSessionState {
    [self clearUserVerification];
}

#pragma mark - Key State

- (void)updateKeyState:(YKFKeyFIDO2SessionKeyState)keyState {
    if (self.keyState == keyState) {
        return;
    }
    self.keyState = keyState;
    [self.delegate keyStateChanged:keyState];
}

#pragma mark - Public Requests

- (void)getInfoWithCompletion:(YKFKeyFIDO2SessionGetInfoCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    YKFAPDU *apdu = [[YKFFIDO2CommandAPDU alloc] initWithCommand:YKFFIDO2CommandGetInfo data:nil];
    
    ykf_weak_self();
    [self executeFIDO2Command:apdu retryCount:0 completion:^(NSData * data, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSData *cborData = [strongSelf cborFromKeyResponseData:data];
        YKFKeyFIDO2GetInfoResponse *getInfoResponse = [[YKFKeyFIDO2GetInfoResponse alloc] initWithCBORData:cborData];
        
        if (getInfoResponse) {
            completion(getInfoResponse, nil);
        } else {
            completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
        }
    }];
}

- (void)verifyPin:(NSString *)pin completion:(YKFKeyFIDO2SessionCompletionBlock)completion {
    YKFParameterAssertReturn(pin);
    YKFParameterAssertReturn(completion);

    [self clearUserVerification];
    
    ykf_weak_self();
    [self executeGetSharedSecretWithCompletion:^(NSData *sharedSecret, YKFCBORMap *cosePlatformPublicKey, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(error);
            return;
        }        
        YKFParameterAssertReturn(sharedSecret)
        YKFParameterAssertReturn(cosePlatformPublicKey)
        
        // Get the authenticator pinToken
        YKFKeyFIDO2ClientPinRequest *clientPinGetPinTokenRequest = [[YKFKeyFIDO2ClientPinRequest alloc] init];
        clientPinGetPinTokenRequest.pinProtocol = 1;
        clientPinGetPinTokenRequest.subCommand = YKFKeyFIDO2ClientPinRequestSubCommandGetPINToken;
        clientPinGetPinTokenRequest.keyAgreement = cosePlatformPublicKey;
        
        NSData *pinData = [pin dataUsingEncoding:NSUTF8StringEncoding];
        NSData *pinHash = [[pinData ykf_SHA256] subdataWithRange:NSMakeRange(0, 16)];
        clientPinGetPinTokenRequest.pinHashEnc = [pinHash ykf_aes256EncryptedDataWithKey:sharedSecret];
        
        [strongSelf executeClientPinRequest:clientPinGetPinTokenRequest completion:^(YKFKeyFIDO2ClientPinResponse *response, NSError *error) {
            if (error) {
                completion(error);
                return;
            }
            NSData *encryptedPinToken = response.pinToken;
            if (!encryptedPinToken) {
                completion([YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
                return;
            }
            
            // Cache the pinToken
            strongSelf.pinToken = [response.pinToken ykf_aes256DecryptedDataWithKey:sharedSecret];
            
            if (!strongSelf.pinToken) {
                completion([YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
            } else {
                completion(nil);
            }
        }];
    }];
}

- (void)clearUserVerification {
    if (!self.pinToken && !self.applicationSelected) {
        return;
    }
    
    YKFLogVerbose(@"Clearing FIDO2 Session user verification.");
    self.pinToken = nil;
// TODO: We can't do this anymore. Should we handle it in some other way?
//        strongSelf.applicationSelected = NO; // Force also an application re-selection.
}

- (void)changePin:(nonnull NSString *)oldPin to:(nonnull NSString *)newPin completion:(nonnull YKFKeyFIDO2SessionCompletionBlock)completion {
    YKFParameterAssertReturn(oldPin);
    YKFParameterAssertReturn(newPin);
    YKFParameterAssertReturn(completion);

    if (oldPin.length < 4 || newPin.length < 4 ||
        oldPin.length > 255 || newPin.length > 255) {
        completion([YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodePIN_POLICY_VIOLATION]);
        return;
    }
    
    ykf_weak_self();
    [self executeGetSharedSecretWithCompletion:^(NSData *sharedSecret, YKFCBORMap *cosePlatformPublicKey, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(error);
            return;
        }
        YKFParameterAssertReturn(sharedSecret)
        YKFParameterAssertReturn(cosePlatformPublicKey)
        
        // Change the PIN
        YKFKeyFIDO2ClientPinRequest *changePinRequest = [[YKFKeyFIDO2ClientPinRequest alloc] init];
        NSData *oldPinData = [oldPin dataUsingEncoding:NSUTF8StringEncoding];
        NSData *newPinData = [[newPin dataUsingEncoding:NSUTF8StringEncoding] ykf_fido2PaddedPinData];

        changePinRequest.pinProtocol = 1;
        changePinRequest.subCommand = YKFKeyFIDO2ClientPinRequestSubCommandChangePIN;
        changePinRequest.keyAgreement = cosePlatformPublicKey;

        NSData *oldPinHash = [[oldPinData ykf_SHA256] subdataWithRange:NSMakeRange(0, 16)];
        changePinRequest.pinHashEnc = [oldPinHash ykf_aes256EncryptedDataWithKey:sharedSecret];

        changePinRequest.pinEnc = [newPinData ykf_aes256EncryptedDataWithKey:sharedSecret];
        
        NSMutableData *pinAuthData = [NSMutableData dataWithData:changePinRequest.pinEnc];
        [pinAuthData appendData:changePinRequest.pinHashEnc];
        changePinRequest.pinAuth = [[pinAuthData ykf_fido2HMACWithKey:sharedSecret] subdataWithRange:NSMakeRange(0, 16)];
        
        [strongSelf executeClientPinRequest:changePinRequest completion:^(YKFKeyFIDO2ClientPinResponse *response, NSError *error) {
            if (error) {
                completion(error);
                return;
            }
            // clear the cached pin token.
            strongSelf.pinToken = nil;
            completion(nil);
        }];
    }];
}

- (void)setPin:(nonnull NSString *)pin completion:(nonnull YKFKeyFIDO2SessionCompletionBlock)completion {
    YKFParameterAssertReturn(pin);
    YKFParameterAssertReturn(completion);

    if (pin.length < 4 || pin.length > 255) {
        completion([YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodePIN_POLICY_VIOLATION]);
        return;
    }
    
    ykf_weak_self();
    [self executeGetSharedSecretWithCompletion:^(NSData *sharedSecret, YKFCBORMap *cosePlatformPublicKey, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(error);
            return;
        }
        YKFParameterAssertReturn(sharedSecret)
        YKFParameterAssertReturn(cosePlatformPublicKey)
        
        // Set the new PIN
        YKFKeyFIDO2ClientPinRequest *setPinRequest = [[YKFKeyFIDO2ClientPinRequest alloc] init];
        setPinRequest.pinProtocol = 1;
        setPinRequest.subCommand = YKFKeyFIDO2ClientPinRequestSubCommandSetPIN;
        setPinRequest.keyAgreement = cosePlatformPublicKey;
        
        NSData *pinData = [[pin dataUsingEncoding:NSUTF8StringEncoding] ykf_fido2PaddedPinData];
        
        setPinRequest.pinEnc = [pinData ykf_aes256EncryptedDataWithKey:sharedSecret];
        setPinRequest.pinAuth = [[setPinRequest.pinEnc ykf_fido2HMACWithKey:sharedSecret] subdataWithRange:NSMakeRange(0, 16)];
        
        [strongSelf executeClientPinRequest:setPinRequest completion:^(YKFKeyFIDO2ClientPinResponse *response, NSError *error) {
            if (error) {
                completion(error);
                return;
            }
            completion(nil);
        }];
    }];
}

- (void)getPinRetriesWithCompletion:(YKFKeyFIDO2SessionGetPinRetriesCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    YKFKeyFIDO2ClientPinRequest *pinRetriesRequest = [[YKFKeyFIDO2ClientPinRequest alloc] init];
    pinRetriesRequest.pinProtocol = 1;
    pinRetriesRequest.subCommand = YKFKeyFIDO2ClientPinRequestSubCommandGetRetries;
    
    [self executeClientPinRequest:pinRetriesRequest completion:^(YKFKeyFIDO2ClientPinResponse *response, NSError *error) {
        if (error) {
            completion(0, error);
            return;
        }
        completion(response.retries, nil);
    }];
}

- (void)makeCredentialWithClientDataHash:(NSData *)clientDataHash
                                      rp:(YKFFIDO2PublicKeyCredentialRpEntity *)rp
                                    user:(YKFFIDO2PublicKeyCredentialUserEntity *)user
                        pubKeyCredParams:(NSArray *)pubKeyCredParams
                              excludeList:(NSArray * _Nullable)excludeList
                                 options:(NSDictionary  * _Nullable)options
                              completion:(YKFKeyFIDO2SessionMakeCredentialCompletionBlock)completion {
    YKFParameterAssertReturn(clientDataHash);
    YKFParameterAssertReturn(rp);
    YKFParameterAssertReturn(user);
    YKFParameterAssertReturn(pubKeyCredParams);
    YKFParameterAssertReturn(options);
    YKFParameterAssertReturn(completion);

    // Attach the PIN authentication if the pinToken is present.
    NSData *pinAuth;
    NSUInteger pinProtocol = 0;
    if (self.pinToken) {
        YKFParameterAssertReturn(clientDataHash);
        pinProtocol = 1;
        NSData *hmac = [clientDataHash ykf_fido2HMACWithKey:self.pinToken];
        pinAuth = [hmac subdataWithRange:NSMakeRange(0, 16)];
        if (pinAuth) {
            completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER]);
        }
    }
    
    YKFAPDU *apdu = [[YKFFIDO2MakeCredentialAPDU alloc] initWithClientDataHash:clientDataHash rp:rp user:user pubKeyCredParams:pubKeyCredParams excludeList:excludeList pinAuth:pinAuth pinProtocol:pinProtocol options:options];
    
    if (!apdu) {
        YKFKeySessionError *error = [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER];
        completion(nil, error);
        return;
    }
    
    ykf_weak_self();
    [self executeFIDO2Command:apdu retryCount:0 completion:^(NSData *data, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSData *cborData = [strongSelf cborFromKeyResponseData:data];
        YKFKeyFIDO2MakeCredentialResponse *makeCredentialResponse = [[YKFKeyFIDO2MakeCredentialResponse alloc] initWithCBORData:cborData];
        
        if (makeCredentialResponse) {
            completion(makeCredentialResponse, nil);
        } else {
            completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
        }
    }];
}

- (void)getAssertionWithClientDataHash:(NSData *)clientDataHash
                                  rpId:(NSString *)rpId
                             allowList:(NSArray * _Nullable)allowList
                               options:(NSDictionary * _Nullable)options
                            completion:(YKFKeyFIDO2SessionGetAssertionCompletionBlock)completion {
    YKFParameterAssertReturn(clientDataHash);
    YKFParameterAssertReturn(rpId);
    YKFParameterAssertReturn(completion);
    
    // Attach the PIN authentication if the pinToken is present.
    NSData *pinAuth;
    NSUInteger pinProtocol = 0;
//    if (self.pinToken) {
//        YKFParameterAssertReturn(clientDataHash);
//        pinProtocol = 1;
//        NSData *hmac = [clientDataHash ykf_fido2HMACWithKey:self.pinToken];
//        pinAuth = [hmac subdataWithRange:NSMakeRange(0, 16)];
//        if (!pinAuth) {
//            completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER]);
//        }
//    }
    
    YKFFIDO2GetAssertionAPDU *apdu = [[YKFFIDO2GetAssertionAPDU alloc] initWithClientDataHash:clientDataHash
                                                                                         rpId:rpId
                                                                                    allowList:allowList
                                                                                      pinAuth:pinAuth
                                                                                  pinProtocol:pinProtocol
                                                                                      options:options];
    if (!apdu) {
        YKFKeySessionError *error = [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER];
        completion(nil, error);
        return;
    }
    
    ykf_weak_self();
    [self executeFIDO2Command:apdu retryCount:0 completion:^(NSData *data, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSData *cborData = [strongSelf cborFromKeyResponseData:data];
        YKFKeyFIDO2GetAssertionResponse *getAssertionResponse = [[YKFKeyFIDO2GetAssertionResponse alloc] initWithCBORData:cborData];
        
        if (getAssertionResponse) {
            completion(getAssertionResponse, nil);
        } else {
            completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
        }
    }];
}

- (void)getNextAssertionWithCompletion:(YKFKeyFIDO2SessionGetAssertionCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    YKFAPDU *apdu = [[YKFFIDO2GetNextAssertionAPDU alloc] init];
    
    ykf_weak_self();
    [self executeFIDO2Command:apdu retryCount:0 completion:^(NSData *data, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSData *cborData = [strongSelf cborFromKeyResponseData:data];
        YKFKeyFIDO2GetAssertionResponse *getAssertionResponse = [[YKFKeyFIDO2GetAssertionResponse alloc] initWithCBORData:cborData];
        
        if (getAssertionResponse) {
            completion(getAssertionResponse, nil);
        } else {
            completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
        }
    }];
}

- (void)resetWithCompletion:(YKFKeyFIDO2SessionCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    YKFAPDU *apdu = [[YKFFIDO2ResetAPDU alloc] init];
    
    ykf_weak_self();
    [self executeFIDO2Command:apdu retryCount:0 completion:^(NSData *response, NSError *error) {
        ykf_strong_self();
        if (!error) {
            [strongSelf clearUserVerification];
        }
        completion(error);
    }];
}

#pragma mark - Private Requests

- (void)executeClientPinRequest:(YKFKeyFIDO2ClientPinRequest *)request completion:(YKFKeyFIDO2SessionClientPinCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    YKFFIDO2ClientPinAPDU *apdu = [[YKFFIDO2ClientPinAPDU alloc] initWithRequest:request];
    if (!apdu) {
        YKFKeySessionError *error = [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER];
        completion(nil, error);
        return;
    }
    request.apdu = apdu;
    
    ykf_weak_self();
    [self executeFIDO2Command:request.apdu retryCount:0 completion:^(NSData *data, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSData *cborData = [strongSelf cborFromKeyResponseData:data];
        YKFKeyFIDO2ClientPinResponse *clientPinResponse = nil;
        
        // In case of Set/Change PIN no CBOR payload is returned.
        if (cborData.length) {
            clientPinResponse = [[YKFKeyFIDO2ClientPinResponse alloc] initWithCBORData:cborData];
        }
        
        if (clientPinResponse) {
            completion(clientPinResponse, nil);
        } else {
            if (cborData.length) {
                completion(nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
            } else {
                completion(nil, nil);
            }
        }
    }];
}

- (void)executeGetSharedSecretWithCompletion:(YKFKeyFIDO2SessionClientPinSharedSecretCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    // Generate the platform key.
    YKFFIDO2PinAuthKey *platformKey = [[YKFFIDO2PinAuthKey alloc] init];
    if (!platformKey) {
        completion(nil, nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER]);
        return;
    }
    YKFCBORMap *cosePlatformPublicKey = platformKey.cosePublicKey;
    if (!cosePlatformPublicKey) {
        completion(nil, nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER]);
        return;
    }
    
    // Get the authenticator public key.
    YKFKeyFIDO2ClientPinRequest *clientPinKeyAgreementRequest = [[YKFKeyFIDO2ClientPinRequest alloc] init];
    clientPinKeyAgreementRequest.pinProtocol = 1;
    clientPinKeyAgreementRequest.subCommand = YKFKeyFIDO2ClientPinRequestSubCommandGetKeyAgreement;
    clientPinKeyAgreementRequest.keyAgreement = cosePlatformPublicKey;
    
    [self executeClientPinRequest:clientPinKeyAgreementRequest completion:^(YKFKeyFIDO2ClientPinResponse *response, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        NSDictionary *authenticatorKeyData = response.keyAgreement;
        if (!authenticatorKeyData) {
            completion(nil, nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
            return;
        }
        YKFFIDO2PinAuthKey *authenticatorKey = [[YKFFIDO2PinAuthKey alloc] initWithCosePublicKey:authenticatorKeyData];
        if (!authenticatorKey) {
            completion(nil, nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeINVALID_CBOR]);
            return;
        }
        
        // Generate the shared secret.
        NSData *sharedSecret = [platformKey sharedSecretWithAuthKey:authenticatorKey];
        if (!sharedSecret) {
            completion(nil, nil, [YKFKeyFIDO2Error errorWithCode:YKFKeyFIDO2ErrorCodeOTHER]);
            return;
        }
        sharedSecret = [sharedSecret ykf_SHA256];
        
        // Success
        completion(sharedSecret, cosePlatformPublicKey, nil);
    }];
}

#pragma mark - Request Execution

- (void)executeFIDO2Command:(YKFAPDU *)apdu retryCount:(int)retryCount completion:(YKFKeyFIDO2SessionResultCompletionBlock)completion {
    YKFParameterAssertReturn(apdu);
    YKFParameterAssertReturn(completion);
    
    [self updateKeyState:YKFKeyFIDO2SessionKeyStateProcessingRequest];
    
    ykf_weak_self();
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        ykf_safe_strong_self();

        if (data) {
            UInt8 fido2Error = [self fido2ErrorCodeFromResponseData:data];
            if (fido2Error != YKFKeyFIDO2ErrorCodeSUCCESS) {
                completion(nil, [YKFKeyFIDO2Error errorWithCode:fido2Error]);
            } else {
                completion(data, nil);
            }
            [strongSelf updateKeyState:YKFKeyFIDO2SessionKeyStateIdle];
        } else {
            if (error.code == YKFKeyAPDUErrorCodeFIDO2TouchRequired) {
                [strongSelf handleTouchRequired:apdu retryCount:retryCount completion:completion];
            } else {
                [strongSelf updateKeyState:YKFKeyFIDO2SessionKeyStateIdle];
                completion(nil, error);
            }
        }
    }];
}

#pragma mark - Helpers

- (UInt8)fido2ErrorCodeFromResponseData:(NSData *)data {
    YKFAssertReturnValue(data.length >= 1, @"Cannot extract FIDO2 error code from the key response.", YKFKeyFIDO2ErrorCodeOTHER);
    UInt8 *payloadBytes = (UInt8 *)data.bytes;
    return payloadBytes[0];
}

- (NSData *)cborFromKeyResponseData:(NSData *)data {
    YKFAssertReturnValue(data.length >= 1, @"Cannot extract FIDO2 cbor from the key response.", nil);
    
    // discard the error byte
    return [data subdataWithRange:NSMakeRange(1, data.length - 1)];
}

- (void)handleTouchRequired:(YKFAPDU *)apdu  retryCount:(int)retryCount completion:(YKFKeyFIDO2SessionResultCompletionBlock)completion {
    YKFParameterAssertReturn(apdu);
    YKFParameterAssertReturn(completion);
    
    if (retryCount >= YKFKeyFIDO2RequestMaxRetries) {
        YKFKeySessionError *timeoutError = [YKFKeySessionError errorWithCode:YKFKeySessionErrorTouchTimeoutCode];
        completion(nil, timeoutError);

        [self updateKeyState:YKFKeyFIDO2SessionKeyStateIdle];
        return;
    }
    
    [self updateKeyState:YKFKeyFIDO2SessionKeyStateTouchKey];
    retryCount += 1;

    ykf_weak_self();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, YKFKeyFIDO2RequestRetryTimeInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ykf_safe_strong_self();

        YKFAPDU* apdu = [[YKFFIDO2TouchPoolingAPDU alloc] init];
        [strongSelf executeFIDO2Command:apdu retryCount:retryCount completion:completion];
    });
}

@end
