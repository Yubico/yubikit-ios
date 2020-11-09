//
//  YKFKeyManagementSession.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyManagementSession.h"
#import "YubiKitManager.h"
#import "YKFKeyRawCommandSession.h"

#import "YKFKeyManagementRequest.h"
#import "YKFKeyManagementRequest+Private.h"

#import "YKFKeyManagementReadConfigurationRequest.h"
#import "YKFKeyManagementReadConfigurationResponse.h"
#import "YKFKeyManagementReadConfigurationResponse+Private.h"

#import "YKFSelectManagementApplicationAPDU.h"
#import "YKFKeyManagementSelectApplicationResponse.h"
#import "YKFKeyManagementSelectApplicationResponse+Private.h"

#import "YKFKeyManagementWriteConfigurationRequest.h"


#import "YKFAssert.h"
#import "YKFKeyAPDUError.h"
#import "YKFKeyManagementError.h"
#import "YKFKeySessionError.h"
#import "YKFKeySessionError+Private.h"

#import "YKFKeyManagementSession+Private.h"
#import "YKFKeyRawCommandSession+Private.h"

typedef void (^YKFKeyManagementSessionResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);
typedef void (^YKFKeyManagementSessionSelectCompletionBlock)(YKFKeyManagementSelectApplicationResponse* _Nullable  result, NSError* _Nullable error);

@interface YKFKeyManagementSession()

@property (nonatomic, readwrite) YKFKeyVersion *version;

@end

@implementation YKFKeyManagementSession



+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyManagementSessionCompletion _Nonnull)completion {
    
    YKFKeyManagementSession *session = [[YKFKeyManagementSession alloc] initWithConnectionController:connectionController];
    
    [session selectManagementApplication:^(YKFKeyManagementSelectApplicationResponse * _Nullable result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            session.version = result.version;
            completion(session, nil);
        }
    }];
}

- (void)readConfigurationWithCompletion:(YKFKeyManagementSessionReadCompletionBlock)completion {
    YKFParameterAssertReturn(completion);

    YKFKeyManagementReadConfigurationRequest* request = [[YKFKeyManagementReadConfigurationRequest alloc] init];
    
    [self executeRequest:request completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyManagementReadConfigurationResponse *response =
        [[YKFKeyManagementReadConfigurationResponse alloc] initWithKeyResponseData:result version:self.version];
        
        if (!response) {
            completion(nil, [YKFKeyManagementError errorWithCode:YKFKeyManagementErrorCodeUnexpectedResponse]);
            return;
        }
        
        completion(response, nil);
    }];
}

- (void) writeConfiguration:(YKFManagementInterfaceConfiguration*) configuration reboot: (BOOL) reboot completion: (nonnull YKFKeyManagementSessionWriteCompletionBlock) completion {
    YKFParameterAssertReturn(configuration);
    YKFParameterAssertReturn(configuration);
    
    YKFKeyManagementWriteConfigurationRequest* request = [[YKFKeyManagementWriteConfigurationRequest alloc]
                                                    initWithConfiguration: configuration
                                                    reboot: reboot];

    [self executeRequest: request completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        completion(error);
    }];
}

#pragma mark - execution of requests

- (void)executeRequest:(YKFKeyManagementRequest *)request
            completion:(YKFKeyManagementSessionResultCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    [self executeCommand:request.apdu completion:^(NSData *response, NSError *error) {
        
        if (error) {
            completion(nil, error);
        } else {
            int statusCode = [YKFKeySession statusCodeFromKeyResponse:response];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    completion([YKFKeySession dataFromKeyResponse:response], nil);
                    break;
                    
                default:
                    completion(nil, [YKFKeySessionError errorWithCode:statusCode]);
                    break;
            }
        }
    }];
}

#pragma mark - Application Selection

- (void)selectManagementApplication:(YKFKeyManagementSessionSelectCompletionBlock)completion {
    YKFAPDU *selectApplicationAPDU = [[YKFSelectManagementApplicationAPDU alloc] init];
            
    [self executeCommand:selectApplicationAPDU completion:^(NSData *response, NSError *error) {

        NSError *returnedError = nil;
        
        if (error) {
            returnedError = error;
        } else {
            int statusCode = [YKFKeySession statusCodeFromKeyResponse: response];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    completion([[YKFKeyManagementSelectApplicationResponse alloc] initWithKeyResponseData:[YKFKeySession dataFromKeyResponse:response]], nil);
                    break;
                    
                case YKFKeyAPDUErrorCodeInsNotSupported:
                case YKFKeyAPDUErrorCodeMissingFile:
                    returnedError = [YKFKeySessionError errorWithCode:YKFKeySessionErrorMissingApplicationCode];
                    break;
                    
                default:
                    returnedError = [YKFKeySessionError errorWithCode:statusCode];
            }
        }
        
        if (returnedError != nil) {
            completion(nil, returnedError);
        }
    }];
}

@end
