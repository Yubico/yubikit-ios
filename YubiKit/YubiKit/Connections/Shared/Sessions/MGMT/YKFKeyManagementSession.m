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

typedef void (^YKFKeyManagementSessionResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);
typedef void (^YKFKeyManagementSessionSelectCompletionBlock)(YKFKeyManagementSelectApplicationResponse* _Nullable  result, NSError* _Nullable error);


@implementation YKFKeyManagementSession

- (void)readConfigurationWithCompletion:(YKFKeyManagementSessionReadCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    id<YKFKeyRawCommandSessionProtocol> rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    if (rawCommandService == nil) {
        if (@available(iOS 13.0, *)) {
            rawCommandService = YubiKitManager.shared.nfcSession.rawCommandService;
        }
    }
    
    if (rawCommandService == nil) {
        completion(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorNoConnection]);
        return;
    }
    
    YKFKeyManagementReadConfigurationRequest* request = [[YKFKeyManagementReadConfigurationRequest alloc] init];
    
    [self selectManagementApplication:rawCommandService completion:^(YKFKeyManagementSelectApplicationResponse *selectionResponse, NSError *error) {
        if (error) {
           completion(nil, error);
           return;
        }
        
        if (selectionResponse == nil) {
            completion(nil, [YKFKeyManagementError errorWithCode:YKFKeyManagementErrorCodeUnexpectedResponse]);
            return;
        }
                
        [self executeRequestWithoutApplicationSelection:rawCommandService request:request completion:^(NSData * _Nullable result, NSError * _Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            YKFKeyManagementReadConfigurationResponse *response =
                [[YKFKeyManagementReadConfigurationResponse alloc] initWithKeyResponseData:result version:selectionResponse.version];
           
           if (!response) {
                completion(nil, [YKFKeyManagementError errorWithCode:YKFKeyManagementErrorCodeUnexpectedResponse]);
                return;
            }
            
            completion(response, nil);
        }];
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

- (void)executeRequest:(YKFKeyManagementRequest *)request completion:(nonnull YKFKeyManagementSessionResultCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    id<YKFKeyRawCommandSessionProtocol> rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    if (rawCommandService == nil) {
        if (@available(iOS 13.0, *)) {
            rawCommandService = YubiKitManager.shared.nfcSession.rawCommandService;
        }
    }
    
    if (rawCommandService == nil) {
        completion(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorNoConnection]);
        return;
    }
    
    [self selectManagementApplication:rawCommandService completion:^(YKFKeyManagementSelectApplicationResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        [self executeRequestWithoutApplicationSelection:rawCommandService request:request completion:completion];
    }];

}

- (void)executeRequestWithoutApplicationSelection:(id<YKFKeyRawCommandSessionProtocol>)rawCommandService
                                          request: (YKFKeyManagementRequest *)request
                                       completion:(YKFKeyManagementSessionResultCompletionBlock)completion {
    YKFParameterAssertReturn(rawCommandService);
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    [rawCommandService executeCommand:request.apdu completion:^(NSData *response, NSError *error) {
        
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

- (void)selectManagementApplication:(id<YKFKeyRawCommandSessionProtocol>)rawCommandService
                                              completion:(YKFKeyManagementSessionSelectCompletionBlock)completion {
    YKFAPDU *selectApplicationAPDU = [[YKFSelectManagementApplicationAPDU alloc] init];
            
    [rawCommandService executeCommand:selectApplicationAPDU completion:^(NSData *response, NSError *error) {

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
