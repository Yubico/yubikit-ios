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
#import "YKFKeyU2FRequest+Private.h"
#import "YKFKeyU2FSignRequest.h"
#import "YKFKeyU2FSignResponse.h"
#import "YKFKeyU2FRegisterRequest.h"
#import "YKFKeyU2FRegisterResponse.h"

#import "YKFKeyU2FRegisterResponse+Private.h"
#import "YKFKeyU2FSignResponse+Private.h"
#import "YKFAPDU+Private.h"

#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

typedef void (^YKFKeyU2FServiceResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);

NSString* const YKFKeyU2FServiceProtocolKeyStatePropertyKey = @"keyState";

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

- (void)executeRegisterRequest:(YKFKeyU2FRegisterRequest *)request completion:(YKFKeyU2FSessionRegisterCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);
    
    ykf_weak_self();
    [self executeU2FRequest:request completion:^(NSData *result, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyU2FRegisterResponse *registerResponse = [strongSelf processRegisterData:result request:request];
        completion(registerResponse, nil);
    }];
}

#pragma mark - U2F Sign

- (void)executeSignRequest:(YKFKeyU2FSignRequest *)request completion:(YKFKeyU2FSessionSignCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    ykf_weak_self();
    [self executeU2FRequest:request completion:^(NSData *result, NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyU2FSignResponse *signResponse = [strongSelf processSignData:result request:request];
        completion(signResponse, nil);
    }];
}

#pragma mark - Request Execution

- (void)executeU2FRequest:(YKFKeyU2FRequest *)request completion:(YKFKeyU2FServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);
    
    ykf_weak_self();
    [self.smartCardInterface executeCommand:request.apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        ykf_safe_strong_self();
        
        if (data) {
            [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
            completion(data, nil);
            return;
        }
        
        switch (error.code) {
            case YKFKeyAPDUErrorCodeConditionNotSatisfied: {
                [strongSelf handleTouchRequired:request completion:completion];
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

- (void)handleTouchRequired:(YKFKeyU2FRequest *)request completion:(YKFKeyU2FServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    if (![request shouldRetry]) {
        YKFKeySessionError *timeoutError = [YKFKeySessionError errorWithCode:YKFKeySessionErrorTouchTimeoutCode];
        completion(nil, timeoutError);
        
        [self updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
        return;
    }
    
    [self updateKeyState:YKFKeyU2FSessionKeyStateTouchKey];    
    request.retries += 1;
    
    ykf_weak_self();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, request.retryTimeInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ykf_safe_strong_self();
        [strongSelf executeU2FRequest:request completion:completion];
    });
}

#pragma mark - Key responses

- (YKFKeyU2FSignResponse *)processSignData:(NSData *)data request:(YKFKeyU2FSignRequest *)request {
    return [[YKFKeyU2FSignResponse alloc] initWithKeyHandle:request.keyHandle clientData:request.clientData signature:data];
}

- (YKFKeyU2FRegisterResponse *)processRegisterData:(NSData *)data request:(YKFKeyU2FRegisterRequest *)request {
    return [[YKFKeyU2FRegisterResponse alloc] initWithClientData:request.clientData registrationData:data];
}

@end
