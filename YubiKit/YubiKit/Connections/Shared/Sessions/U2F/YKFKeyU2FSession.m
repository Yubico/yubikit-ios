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

#import "YKFKeyU2FSession.h"
#import "YKFAccessoryConnectionController.h"
#import "YKFKeyU2FError.h"
#import "YKFKeyAPDUError.h"
#import "YKFBlockMacros.h"
#import "YKFAssert.h"

#import "YKFKeySessionError+Private.h"
#import "YKFKeyU2FSession+Private.h"
#import "YKFKeyU2FSignResponse.h"
#import "YKFKeyU2FRegisterResponse.h"

#import "YKFU2FRegisterAPDU.h"
#import "YKFU2FSignAPDU.h"

#import "YKFKeyU2FRegisterResponse+Private.h"
#import "YKFKeyU2FSignResponse+Private.h"
#import "YKFAPDU+Private.h"

#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

typedef void (^YKFKeyU2FServiceResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);

NSString* const YKFKeyU2FServiceProtocolKeyStatePropertyKey = @"keyState";

static const int YKFKeyU2FMaxRetries = 30; // times
static const NSTimeInterval YKFKeyU2FRetryTimeInterval = 0.5; // seconds

@interface YKFKeyU2FSession()

@property (nonatomic, assign, readwrite) YKFKeyU2FSessionKeyState keyState;
@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

@end

@implementation YKFKeyU2FSession

+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyU2FSessionCompletion _Nonnull)completion {
    YKFKeyU2FSession *session = [YKFKeyU2FSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameU2F];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(session, nil);
        }
    }];
}

- (void)clearSessionState {}

#pragma mark - Key State

- (void)updateKeyState:(YKFKeyU2FSessionKeyState)keyState {
    if (self.keyState == keyState) {
        return;
    }
    self.keyState = keyState;
}

#pragma mark - U2F Register

- (void)registerWithChallenge:(NSString *)challenge appId:(NSString *)appId completion:(YKFKeyU2FSessionRegisterCompletionBlock)completion {
    YKFParameterAssertReturn(challenge);
    YKFParameterAssertReturn(appId);
    YKFParameterAssertReturn(completion);

    YKFU2FRegisterAPDU *apdu = [[YKFU2FRegisterAPDU alloc] initWithChallenge:challenge appId:appId];
    ykf_weak_self();
    [self executeU2FCommand:apdu retryCount:0 completion:^(NSData *result, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyU2FRegisterResponse *registerResponse = [strongSelf processRegisterData:result clientData:apdu.clientData];
        completion(registerResponse, nil);
    }];
}

#pragma mark - U2F Sign

- (void)signWithChallenge:(NSString *)challenge
                keyHandle:(NSString *)keyHandle
                    appId:(NSString *)appId
               completion:(YKFKeyU2FSessionSignCompletionBlock)completion {
    YKFParameterAssertReturn(challenge);
    YKFParameterAssertReturn(keyHandle);
    YKFParameterAssertReturn(appId);
    YKFParameterAssertReturn(completion);

    YKFU2FSignAPDU *apdu = [[YKFU2FSignAPDU alloc] initWithChallenge:challenge keyHandle:keyHandle appId:appId];
    
    ykf_weak_self();
    [self executeU2FCommand:apdu retryCount:0 completion:^(NSData *result, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyU2FSignResponse *signResponse = [strongSelf processSignData:result keyHandle:keyHandle clientData:apdu.clientData];
        completion(signResponse, nil);
    }];
}

#pragma mark - Request Execution

- (void)executeU2FCommand:(YKFAPDU *)apdu retryCount:(int)retryCount completion:(YKFKeyU2FServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(apdu);
    YKFParameterAssertReturn(completion);
    
    ykf_weak_self();
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        ykf_safe_strong_self();
        
        if (data) {
            [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
            completion(data, nil);
            return;
        }
        
        switch (error.code) {
            case YKFKeyAPDUErrorCodeConditionNotSatisfied: {
                [strongSelf handleTouchRequired:apdu retryCount:retryCount completion:completion];
            }
            break;
                
            case YKFKeyAPDUErrorCodeWrongData: {
                [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
                YKFKeySessionError *connectionError = [YKFKeyU2FError errorWithCode:YKFKeyU2FErrorCodeU2FSigningUnavailable];
                completion(nil, connectionError);
            }
            break;

            default: {
                [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
                completion(nil, error);
            }
            break;
        }
    }];
}

#pragma mark - Private

- (void)handleTouchRequired:(YKFAPDU *)apdu retryCount:(int)retryCount completion:(YKFKeyU2FServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    if (retryCount >= YKFKeyU2FMaxRetries) {
        YKFKeySessionError *timeoutError = [YKFKeySessionError errorWithCode:YKFKeySessionErrorTouchTimeoutCode];
        completion(nil, timeoutError);
        
        [self updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
        return;
    }
    
    [self updateKeyState:YKFKeyU2FSessionKeyStateTouchKey];    
    retryCount += 1;
    
    ykf_weak_self();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, YKFKeyU2FRetryTimeInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ykf_safe_strong_self();
        [strongSelf executeU2FCommand:apdu retryCount:retryCount completion:completion];
    });
}

#pragma mark - Key responses

- (YKFKeyU2FSignResponse *)processSignData:(NSData *)data keyHandle:(NSString *)keyHandle clientData:(NSString *)clientData {
    return [[YKFKeyU2FSignResponse alloc] initWithKeyHandle:keyHandle clientData:clientData signature:data];
}

- (YKFKeyU2FRegisterResponse *)processRegisterData:(NSData *)data clientData:(NSString *)clientData {
    return [[YKFKeyU2FRegisterResponse alloc] initWithClientData:clientData registrationData:data];
}

@end
