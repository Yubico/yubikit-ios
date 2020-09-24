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
#import "YKFSelectU2FApplicationAPDU.h"
#import "YKFAccessoryConnectionController.h"
#import "YKFKeyU2FError.h"
#import "YKFKeyAPDUError.h"
#import "YKFKeyCommandConfiguration.h"
#import "YKFBlockMacros.h"
#import "YKFAssert.h"

#import "YKFKeySessionError+Private.h"
#import "YKFKeyU2FSession+Private.h"
#import "YKFKeyU2FRequest+Private.h"
#import "YKFKeyU2FRegisterResponse+Private.h"
#import "YKFKeyU2FSignResponse+Private.h"
#import "YKFKeySession+Private.h"
#import "YKFAPDU+Private.h"

typedef void (^YKFKeyU2FServiceResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);

NSString* const YKFKeyU2FServiceProtocolKeyStatePropertyKey = @"keyState";

@interface YKFKeyU2FSession()

@property (nonatomic, assign, readwrite) YKFKeyU2FSessionKeyState keyState;
@property (nonatomic) id<YKFKeyConnectionControllerProtocol> connectionController;

@end

@implementation YKFKeyU2FSession

- (instancetype)initWithConnectionController:(id<YKFKeyConnectionControllerProtocol>)connectionController {
    YKFAssertAbortInit(connectionController);
    
    self = [super init];
    if (self) {
        self.connectionController = connectionController;
    }
    return self;
}

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

#pragma mark - Application Selection

- (void)selectU2FApplicationWithCompletion:(void (^)(NSError *))completion {
    YKFAPDU *selectU2FApplicationAPDU = [[YKFSelectU2FApplicationAPDU alloc] init];
    
    ykf_weak_self();
    [self.connectionController execute:selectU2FApplicationAPDU
                         configuration:[YKFKeyCommandConfiguration fastCommandCofiguration]
                            completion:^(NSData *result, NSError *error, NSTimeInterval executionTime) {
        ykf_safe_strong_self();
        NSError *returnedError = nil;
        
        if (error) {
            returnedError = error;
        } else {
            int statusCode = [YKFKeySession statusCodeFromKeyResponse: result];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    break;
                    
                case YKFKeyAPDUErrorCodeMissingFile:
                    returnedError = [YKFKeySessionError errorWithCode:YKFKeySessionErrorMissingApplicationCode];
                    break;
                    
                default:
                    returnedError = [YKFKeySessionError errorWithCode:statusCode];
            }
        }
        
        completion(returnedError);
    }];
}

#pragma mark - Request Execution

- (void)executeU2FRequest:(YKFKeyU2FRequest *)request completion:(YKFKeyU2FServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);
    
    [self.delegate keyService:self willExecuteRequest:request];
    
    [self updateKeyState:YKFKeyU2FSessionKeyStateProcessingRequest];
    
    ykf_weak_self();
    [self selectU2FApplicationWithCompletion:^(NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
            completion(nil, error);
            return;
        }
        [strongSelf executeU2FRequestWithoutApplicationSelection:request completion:completion];
    }];
}

- (void)executeU2FRequestWithoutApplicationSelection:(YKFKeyU2FRequest *)request completion:(YKFKeyU2FServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);
    
    ykf_weak_self();
    YKFKeyConnectionControllerCommandResponseBlock block = ^(NSData *result, NSError *error, NSTimeInterval executionTime) {
        ykf_safe_strong_self();
        if (error) {
            [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
            completion(nil, error);
            return;
        }
        int statusCode = [YKFKeySession statusCodeFromKeyResponse: result];
        
        switch (statusCode) {
            case YKFKeyAPDUErrorCodeConditionNotSatisfied: {
                [strongSelf handleTouchRequired:request completion:completion];
            }
            break;
                
            case YKFKeyAPDUErrorCodeNoError: {
                [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
                completion(result, nil);
            }
            break;
                
            case YKFKeyAPDUErrorCodeWrongData: {
                [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
                YKFKeySessionError *connectionError = [YKFKeyU2FError errorWithCode:YKFKeyU2FErrorCodeU2FSigningUnavailable];
                completion(nil, connectionError);
            }
            break;
                
            case YKFKeyAPDUErrorCodeInsNotSupported: {
                [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
                completion(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorMissingApplicationCode]);
            }
            break;
                
            // Errors - The status code is the error. The key doesn't send any other information.
            default: {
                [strongSelf updateKeyState:YYKFKeyU2FSessionKeyStateIdle];
                YKFKeySessionError *connectionError = [YKFKeySessionError errorWithCode:statusCode];
                completion(nil, connectionError);
            }
            break;
        }
    };
    [self.connectionController execute:request.apdu completion:block];
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
    [self.connectionController dispatchOnSequentialQueue:^{
        ykf_safe_strong_self();
        [strongSelf executeU2FRequestWithoutApplicationSelection:request completion:completion];
    }
    delay:request.retryTimeInterval];
}

#pragma mark - Key responses

- (YKFKeyU2FSignResponse *)processSignData:(NSData *)data request:(YKFKeyU2FSignRequest *)request {
    NSData *signature = [YKFKeySession dataFromKeyResponse:data];
    return [[YKFKeyU2FSignResponse alloc] initWithKeyHandle:request.keyHandle clientData:request.clientData signature:signature];
}

- (YKFKeyU2FRegisterResponse *)processRegisterData:(NSData *)data request:(YKFKeyU2FRegisterRequest *)request {
    NSData *registrationData = [YKFKeySession dataFromKeyResponse:data];
    return [[YKFKeyU2FRegisterResponse alloc] initWithClientData:request.clientData registrationData:registrationData];
}

@end
