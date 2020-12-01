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

#import "YKFKeyOATHSession.h"
#import "YKFKeyOATHSession+Private.h"
#import "YKFAccessoryConnectionController.h"
#import "YKFKeyOATHError.h"
#import "YKFKeyAPDUError.h"
#import "YKFOATHCredentialValidator.h"
#import "YKFLogger.h"
#import "YKFKeyCommandConfiguration.h"
#import "YKFBlockMacros.h"
#import "YKFAssert.h"

#import "YKFSelectOATHApplicationAPDU.h"
#import "YKFOATHSendRemainingAPDU.h"
#import "YKFOATHSetCodeAPDU.h"
#import "YKFOATHValidateAPDU.h"

#import "YKFKeySessionError+Private.h"

#import "YKFNSDataAdditions.h"
#import "YKFNSDataAdditions+Private.h"

#import "YKFAPDU+Private.h"

#import "YKFOATHPutAPDU.h"
#import "YKFOATHDeleteAPDU.h"
#import "YKFOATHRenameAPDU.h"
#import "YKFOATHCalculateAPDU.h"
#import "YKFOATHCalculateAllAPDU.h"

#import "YKFKeyOATHCalculateAllResponse.h"
#import "YKFKeyOATHCalculateAllResponse.h"
#import "YKFKeyOATHCalculateResponse+Private.h"
#import "YKFKeyOATHCalculateResponse.h"
#import "YKFKeyOATHListResponse.h"
#import "YKFKeyOATHSelectApplicationResponse.h"
#import "YKFKeyOATHSelectApplicationResponse.h"
#import "YKFKeyOATHValidateResponse.h"

#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

static const NSTimeInterval YKFKeyOATHServiceTimeoutThreshold = 10; // seconds

typedef void (^YKFKeyOATHServiceResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);

@interface YKFKeyOATHSession()

@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

/*
 In case of OATH, the reselection of the application leads to the loss of authentication (if any). To avoid
 this the select application response is cached to avoid reselecting the applet. If the request fails with
 timeout the cache gets invalidated to allow again the following requests to select the application again.
 */
@property (nonatomic) YKFKeyOATHSelectApplicationResponse *cachedSelectApplicationResponse;
@property (nonatomic, readonly) BOOL isValid;

@end

@implementation YKFKeyOATHSession

- (BOOL)isValid {
    return self.cachedSelectApplicationResponse != nil;
}

+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyOATHSessionCompletion _Nonnull)completion {
    YKFKeyOATHSession *session = [YKFKeyOATHSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameOATH];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            session.cachedSelectApplicationResponse = [[YKFKeyOATHSelectApplicationResponse alloc] initWithResponseData:data];
            completion(session, nil);
        }
    }];
}

-(YKFKeyVersion *)version {
    return _cachedSelectApplicationResponse.version;
}

#pragma mark - Credential Add/Delete

- (void)putCredential:(YKFOATHCredential *)credential completion:(YKFKeyOATHSessionCompletionBlock)completion {
    YKFParameterAssertReturn(credential);
    YKFParameterAssertReturn(completion);
    
    YKFKeySessionError *credentialError = [YKFOATHCredentialValidator validateCredential:credential includeSecret:YES];
    if (credentialError) {
        completion(credentialError);
        return;
    }
    
    YKFOATHPutAPDU *apdu = [[YKFOATHPutAPDU alloc] initWithCredential:credential];
    
    [self executeOATHCommand:apdu completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        // No result except status code
        completion(error);
    }];
}

- (void)deleteCredential:(YKFOATHCredential *)credential completion:(YKFKeyOATHSessionCompletionBlock)completion {
    YKFParameterAssertReturn(credential);
    YKFParameterAssertReturn(completion);

    YKFKeySessionError *credentialError = [YKFOATHCredentialValidator validateCredential:credential includeSecret:NO];
    if (credentialError) {
        completion(credentialError);
        return;
    }

    YKFOATHDeleteAPDU *apdu = [[YKFOATHDeleteAPDU alloc] initWithCredential:credential];
    [self executeOATHCommand:apdu completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        // No result except status code
        completion(error);
    }];
}

- (void)renameCredential:(nonnull YKFOATHCredential *)credential
               newIssuer:(nonnull NSString*)newIssuer
              newAccount:(nonnull NSString*)newAccount
              completion:(YKFKeyOATHSessionCompletionBlock)completion {
    YKFParameterAssertReturn(credential);
    YKFParameterAssertReturn(newIssuer);
    YKFParameterAssertReturn(newAccount);
    YKFParameterAssertReturn(completion);
    
    YKFKeySessionError *credentialError = [YKFOATHCredentialValidator validateCredential:credential includeSecret:NO];
    if (credentialError) {
        completion(credentialError);
        return;
    }
    
    YKFOATHCredential *renamedCredential = credential.copy;
    renamedCredential.issuer = newIssuer;
    renamedCredential.account = newAccount;
    
    YKFKeySessionError *renamedCredentialError = [YKFOATHCredentialValidator validateCredential:renamedCredential includeSecret:NO];
    if (renamedCredentialError) {
        completion(renamedCredentialError);
        return;
    }
    
    YKFAPDU *apdu = [[YKFOATHRenameAPDU alloc] initWithCredential:credential renamedCredential:renamedCredential];
    
    [self executeOATHCommand:apdu completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        // No result except status code
        completion(error);
    }];
}

#pragma mark - Credential Calculation

- (void)calculateCredential:(YKFOATHCredential *)credential completion:(YKFKeyOATHSessionCalculateCompletionBlock)completion {
    YKFParameterAssertReturn(credential);
    YKFParameterAssertReturn(completion);
    
    YKFKeySessionError *credentialError = [YKFOATHCredentialValidator validateCredential:credential includeSecret:NO];
    if (credentialError) {
        completion(nil, credentialError);
        return;
    }
    
    NSDate *timestamp = [NSDate date];
    YKFAPDU *apdu = [[YKFOATHCalculateAPDU alloc] initWithCredential:credential timestamp:timestamp];
    
    [self executeOATHCommand:apdu completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyOATHCalculateResponse *response = [[YKFKeyOATHCalculateResponse alloc] initWithKeyResponseData:result
                                                                                             requestTimetamp:timestamp
                                                                                               requestPeriod:credential.period
                                                                                              truncateResult:!credential.notTruncated];
        if (!response) {
            completion(nil, [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeBadCalculationResponse]);
            return;
        }
        completion(response, nil);
    }];
}

- (void)calculateAllWithCompletion:(YKFKeyOATHSessionCalculateAllCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    NSDate *timestamp = [NSDate date];
    YKFAPDU *apdu = [[YKFOATHCalculateAllAPDU alloc] initWithTimestamp:timestamp];
    
    [self executeOATHCommand:apdu completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyOATHCalculateAllResponse *response = [[YKFKeyOATHCalculateAllResponse alloc] initWithKeyResponseData:result
                                                                                                   requestTimetamp:timestamp];
        if (!response) {
            completion(nil, [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeBadCalculateAllResponse]);
            return;
        }
        completion(response.credentials, nil);
    }];
}

#pragma mark - Credential Listing

- (void)listCredentialsWithCompletion:(YKFKeyOATHSessionListCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA1 p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
    
    [self executeOATHCommand:apdu completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyOATHListResponse *response = [[YKFKeyOATHListResponse alloc] initWithKeyResponseData:result];
        if (!response) {
            completion(nil, [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeBadListResponse]);
            return;
        }
        
        completion(response.credentials, nil);
    }];
}

#pragma mark - Reset

- (void)resetWithCompletion:(YKFKeyOATHSessionCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    if (!self.isValid) {
        completion([YKFKeySessionError errorWithCode:YKFKeySessionErrorInvalidSessionStateStatusCode]);
        return;
    }
    
    self.cachedSelectApplicationResponse = nil;
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x04 p1:0xDE p2:0xAD data:[NSData data] type:YKFAPDUTypeShort];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (!error) {
            YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameOATH];
            [self.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
                if (error) {
                    completion(error);
                } else {
                    self.cachedSelectApplicationResponse = [[YKFKeyOATHSelectApplicationResponse alloc] initWithResponseData:data];
                    completion(nil);
                }
            }];
        } else {
            completion(error);
        }
    }];
}

#pragma mark - OATH Authentication

- (void)setCode:(NSString *)code completion:(YKFKeyOATHSessionCompletionBlock)completion {
    YKFParameterAssertReturn(code);
    YKFParameterAssertReturn(completion);
    // Check if the session is valid since we need the cached select application response later
    if (!self.isValid) {
        completion([YKFKeySessionError errorWithCode:YKFKeySessionErrorInvalidSessionStateStatusCode]);
        return;
    }
    // Build the request APDU with the select ID salt
    YKFOATHSetCodeAPDU *apdu = [[YKFOATHSetCodeAPDU alloc] initWithCode:code salt:self.cachedSelectApplicationResponse.selectID];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        completion(error);
    }];
}

- (void)validateCode:(NSString *)code completion:(YKFKeyOATHSessionCompletionBlock)completion {
    YKFParameterAssertReturn(code);
    YKFParameterAssertReturn(completion);
    if (!self.isValid) {
        completion([YKFKeySessionError errorWithCode:YKFKeySessionErrorInvalidSessionStateStatusCode]);
        return;
    }
    YKFOATHValidateAPDU *apdu = [[YKFOATHValidateAPDU alloc] initWithCode:code challenge:self.cachedSelectApplicationResponse.challenge salt:self.cachedSelectApplicationResponse.selectID];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            if (error.code == YKFKeyAPDUErrorCodeWrongData) {
                completion([YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeWrongPassword]);
            } else {
                completion(error);
            }
            return;
        }
        
        YKFKeyOATHValidateResponse *validateResponse = [[YKFKeyOATHValidateResponse alloc] initWithResponseData:data];
        if (!validateResponse) {
            completion([YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeBadValidationResponse]);
            return;
        }
        NSData *expectedApduData = apdu.expectedChallengeData;
        if (![validateResponse.response isEqualToData:expectedApduData]) {
            completion([YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeBadValidationResponse]);
            return;
        }
        
        completion(nil);
    }];
}

#pragma mark - Request Execution

- (void)executeOATHCommand:(YKFAPDU *)apdu completion:(YKFKeyOATHServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(apdu);
    YKFParameterAssertReturn(completion);
    if (!self.isValid) {
        completion(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorInvalidSessionStateStatusCode]);
        return;
    }
    
    NSDate *startTime = [NSDate date];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (data) {
            completion(data, nil);
            return;
        }
        NSTimeInterval executionTime = [startTime timeIntervalSinceNow];
        switch(error.code) {
            case YKFKeyAPDUErrorCodeAuthenticationRequired:
                if (executionTime < YKFKeyOATHServiceTimeoutThreshold) {
                    self.cachedSelectApplicationResponse = nil; // Clear the cache to allow the application selection again.
                    completion(nil, [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeAuthenticationRequired]);
                } else {
                    completion(nil, [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeTouchTimeout]);
                }
                break;
            case YKFKeyAPDUErrorCodeDataInvalid:
                completion(nil, [YKFKeyOATHError errorWithCode:YKFKeyOATHErrorCodeNoSuchObject]);
                break;
            default: {
                completion(nil, error);
            }
        }
    }];
}

#pragma mark - YKFSessionProtocol

- (void)clearSessionState {
    self.cachedSelectApplicationResponse = nil;
}

#pragma mark - Test Helpers

- (void)invalidateApplicationSelectionCache {
    self.cachedSelectApplicationResponse = nil;
}

@end
