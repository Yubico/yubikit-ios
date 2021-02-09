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

#import <Foundation/Foundation.h>
#import "YKFSession.h"
#import "YKFVersion.h"

@class YKFOATHCode,
       YKFOATHCredential,
       YKFOATHCredentialWithCode,
       YKFOATHCredentialTemplate,
       YKFOATHSelectApplicationResponse;

/**
 * ---------------------------------------------------------------------------------------------------------------------
 * @name OATH Service Response Blocks
 * ---------------------------------------------------------------------------------------------------------------------
 */

/*!
 @abstract
    Response block used by OATH requests which do not provide a result for the request.
 
 @param error
    In case of a failed request this parameter contains the error. If the request was successful
    this parameter is nil.
 */
typedef void (^YKFOATHSessionCompletionBlock)
    (NSError* _Nullable error);

/*!
 @abstract
    Response block for [executeCalculateRequest:completion:] which provides the result for the execution
    of the Calculate request.
 
 @param code
    The code if the request was successful. In case of error this parameter is nil.

 @param error
    In case of a failed request this parameter contains the error. If the request was successful this
    parameter is nil.
 */
typedef void (^YKFOATHSessionCalculateCompletionBlock)
    (YKFOATHCode* _Nullable code, NSError* _Nullable error);

/*!
 @abstract
    Response block for [executeListRequest:completion:] which provides the result for the execution
    of the List request.
 
 @param credentials
    An array containing all the credentials. In case of error this parameter is nil.
 
 @param error
    In case of a failed request this parameter contains the error. If the request was successful this
    parameter is nil.
 */
typedef void (^YKFOATHSessionListCompletionBlock)
    (NSArray<YKFOATHCredential*>* _Nullable credentials, NSError* _Nullable error);

/*!
 @abstract
    Response block for [executeCalculateAllRequest:completion:] which provides the result for the execution
    of the Calculate All request.
 
 @param credentials
    The requested calculated credentials if it was successful. In case of error this parameter is nil.
 
 @param error
    In case of a failed request this parameter contains the error. If the request was successful this
    parameter is nil.
 */
typedef void (^YKFOATHSessionCalculateAllCompletionBlock)
    (NSArray<YKFOATHCredentialWithCode*>* _Nullable credentials, NSError* _Nullable error);

/*!
 @abstract
    Response block for [selectOATHApplicationWithCompletion:] which provides the result for the execution
    of the Calculate All request.
 
 @param response
    The response of the request when it was successful. In case of error this parameter is nil.
 
 @param error
    In case of a failed request this parameter contains the error. If the request was successful this
    parameter is nil.
 */
typedef void (^YKFOATHSelectApplicationCompletionBlock)
    (YKFOATHSelectApplicationResponse* _Nullable response, NSError* _Nullable error);

/**
 * ---------------------------------------------------------------------------------------------------------------------
 * @name OATH Service Protocol
 * ---------------------------------------------------------------------------------------------------------------------
 */

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract
    Defines the interface for YKFOATHService.
 */
@protocol YKFOATHSessionProtocol<NSObject>

@property (nonatomic, readonly) YKFVersion* version;

/*!
 @method putCredentialTemplate:completion:
 
 @abstract
    Sends to the key an OATH Put request to add a new credential. The request is performed asynchronously
    on a background execution queue.
 
 @param credentialTemplate
    The new credential to add.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note:
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)putCredentialTemplate:(YKFOATHCredentialTemplate *)credentialTemplate requiresTouch:(BOOL)requiresTouch completion:(YKFOATHSessionCompletionBlock)completion;

/*!
 @method deleteCredential:completion:
 
 @abstract
    Sends to the key an OATH Delete request to remove an existing credential. The request is performed
    asynchronously on a background execution queue.
 
 @param credential
    The request which contains the required information to remove a credential.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)deleteCredential:(YKFOATHCredential *)credential completion:(YKFOATHSessionCompletionBlock)completion;

/*!
 @method renameCredential:newIssuer:newAccount:completion:
 
 @abstract
    Sends to the key an OATH Rename request to update issuer and account on an existing credential. The request is performed
    asynchronously on a background execution queue. This operation is available on Yubikeys from version 5.3.1.
 
 @param credential
    The credential to rename.
 
 @param newIssuer
    The new issuer name.
 
 @param newAccount
    The new account name.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)renameCredential:(YKFOATHCredential *)credential
               newIssuer:(NSString*)newIssuer
              newAccount:(NSString*)newAccount
              completion:(YKFOATHSessionCompletionBlock)completion;

/*!
 @method calculateCredential:completion:
 
 @abstract
    Sends to the key an OATH Calculate request to calculate an existing credential. The request is performed
    asynchronously on a background execution queue.
 
 @param credential
    The credential to calculate.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)calculateCredential:(YKFOATHCredential *)credential completion:(YKFOATHSessionCalculateCompletionBlock)completion;

/*!
 @method calculateAllWithCompletion:
 
 @abstract
    Sends to the key an OATH Calculate All request to calculate all stored credentials on the key.
    The request is performed asynchronously on a background execution queue.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)calculateAllWithCompletion:(YKFOATHSessionCalculateAllCompletionBlock)completion;

/*!
 @method listCredentialsWithCompletion:
 
 @abstract
    Sends to the key an OATH List request to enumerate all stored credentials on the key.
    The request is performed asynchronously on a background execution queue.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)listCredentialsWithCompletion:(YKFOATHSessionListCompletionBlock)completion;

/*!
 @method resetWithCompletion:
 
 @abstract
    Sends to the key an OATH Reset request to reset the OATH application to its default state. This request
    will remove all stored credentials and the authentication, if set. The request is performed asynchronously
    on a background execution queue.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)resetWithCompletion:(YKFOATHSessionCompletionBlock)completion;

/*!
 @method setPassword:completion:
 
 @abstract
    Sends to the key an OATH Set Code request to set a PIN on the key OATH application. The request
    is performed asynchronously on a background execution queue.
 
 @param password
    The password to set on the OATH application. The password can be an empty string. If the
    password is an empty string, the authentication will be removed.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)setPassword:(NSString *)password completion:(YKFOATHSessionCompletionBlock)completion;

/*!
 @method unlockWithPassword:completion:
 
 @abstract
    Sends to the key an OATH Validate request to authentificate against the OATH application. This request maps
    to the VALIDATE command from YOATH protocol: https://developers.yubico.com/OATH/YKOATH_Protocol.html
    After authentification all subsequent requests can be performed until the key application is deselected,
    as the result of performing another type of request (e.g. U2F) or by unplugging the key from the device.
    The method is performed asynchronously on a background execution queue.
 
 @param password
    The password to authenticate the OATH application.
 
 @param completion
    The response block which is executed after the request was processed by the key. The completion block
    will be executed on a background thread. If the intention is to update the UI, dispatch the results
    on the main thread to avoid an UIKit assertion.
 
 @note
    This method is thread safe and can be invoked from any thread (main or a background thread).
 */
- (void)unlockWithPassword:(NSString *)password completion:(YKFOATHSessionCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END

/**
 * ---------------------------------------------------------------------------------------------------------------------
 * @name OATH Service
 * ---------------------------------------------------------------------------------------------------------------------
 */

NS_ASSUME_NONNULL_BEGIN

/*!
 @class YKFOATHService
 
 @abstract
    Provides the interface for executing OATH requests with the key.
@discussion
    The OATH service is mantained by the key session which controls its lifecycle. The application must not
    create one. It has to use only the single shared instance from YKFAccessorySession and sync its usage with
    the session state.
 */
@interface YKFOATHSession: NSObject<YKFOATHSessionProtocol>

/*
 Not available: use only the instance from the YKFAccessorySession.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

