//
//  YKFKeyMGMTService.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTService.h"
#import "YubiKitManager.h"
#import "YKFKeyRawCommandService.h"

#import "YKFKeyMGMTRequest.h"
#import "YKFKeyMGMTRequest+Private.h"

#import "YKFKeyMGMTReadConfigurationRequest.h"
#import "YKFKeyMGMTReadConfigurationResponse.h"
#import "YKFKeyMGMTReadConfigurationResponse+Private.h"

#import "YKFSelectMGMTApplicationAPDU.h"
#import "YKFKeyMGMTSelectApplicationResponse.h"
#import "YKFKeyMGMTSelectApplicationResponse+Private.h"

#import "YKFKeyMGMTWriteConfigurationRequest.h"


#import "YKFAssert.h"
#import "YKFKeyAPDUError.h"
#import "YKFKeyMGMTError.h"
#import "YKFKeySessionError.h"
#import "YKFKeySessionError+Private.h"

typedef void (^YKFKeyMGMTServiceResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);
typedef void (^YKFKeyMGMTServiceSelectCompletionBlock)(YKFKeyMGMTSelectApplicationResponse* _Nullable  result, NSError* _Nullable error);


@implementation YKFKeyMGMTService

- (void)readConfigurationWithCompletion:(YKFKeyMGMTServiceReadCompletionBlock)completion {
    YKFParameterAssertReturn(completion);
    
    id<YKFKeyRawCommandServiceProtocol> rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    if (rawCommandService == nil) {
        if (@available(iOS 13.0, *)) {
            rawCommandService = YubiKitManager.shared.nfcSession.rawCommandService;
        }
    }
    
    if (rawCommandService == nil) {
        completion(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorNoConnection]);
        return;
    }
    
    YKFKeyMGMTReadConfigurationRequest* request = [[YKFKeyMGMTReadConfigurationRequest alloc] init];
    
    [self selectManagementApplication:rawCommandService completion:^(YKFKeyMGMTSelectApplicationResponse *selectionResponse, NSError *error) {
        if (error) {
           completion(nil, error);
           return;
        }
        
        if (selectionResponse == nil) {
            completion(nil, [YKFKeyMGMTError errorWithCode:YKFKeyMGMTErrorCodeUnexpectedResponse]);
            return;
        }
                
        [self executeRequestWithoutApplicationSelection:rawCommandService request:request completion:^(NSData * _Nullable result, NSError * _Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            YKFKeyMGMTReadConfigurationResponse *response =
                [[YKFKeyMGMTReadConfigurationResponse alloc] initWithKeyResponseData:result version:selectionResponse.version];
           
           if (!response) {
                completion(nil, [YKFKeyMGMTError errorWithCode:YKFKeyMGMTErrorCodeUnexpectedResponse]);
                return;
            }
            
            completion(response, nil);
        }];
    }];
}

- (void) writeConfiguration:(YKFMGMTInterfaceConfiguration*) configuration reboot: (BOOL) reboot completion: (nonnull YKFKeyMGMTServiceWriteCompletionBlock) completion {
    YKFParameterAssertReturn(configuration);
    YKFParameterAssertReturn(configuration);
    
    YKFKeyMGMTWriteConfigurationRequest* request = [[YKFKeyMGMTWriteConfigurationRequest alloc]
                                                    initWithConfiguration: configuration
                                                    reboot: reboot];

    [self executeRequest: request completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        completion(error);
    }];
}

#pragma mark - execution of requests

- (void)executeRequest:(YKFKeyMGMTRequest *)request completion:(nonnull YKFKeyMGMTServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    id<YKFKeyRawCommandServiceProtocol> rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    if (rawCommandService == nil) {
        if (@available(iOS 13.0, *)) {
            rawCommandService = YubiKitManager.shared.nfcSession.rawCommandService;
        }
    }
    
    if (rawCommandService == nil) {
        completion(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorNoConnection]);
        return;
    }
    
    [self selectManagementApplication:rawCommandService completion:^(YKFKeyMGMTSelectApplicationResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        [self executeRequestWithoutApplicationSelection:rawCommandService request:request completion:completion];
    }];

}

- (void)executeRequestWithoutApplicationSelection:(id<YKFKeyRawCommandServiceProtocol>)rawCommandService
                                          request: (YKFKeyMGMTRequest *)request
                                       completion:(YKFKeyMGMTServiceResultCompletionBlock)completion {
    YKFParameterAssertReturn(rawCommandService);
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    [rawCommandService executeCommand:request.apdu completion:^(NSData *response, NSError *error) {
        
        if (error) {
            completion(nil, error);
        } else {
            int statusCode = [YKFKeyService statusCodeFromKeyResponse:response];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    completion([YKFKeyService dataFromKeyResponse:response], nil);
                    break;
                    
                default:
                    completion(nil, [YKFKeySessionError errorWithCode:statusCode]);
                    break;
            }
        }
    }];
}

#pragma mark - Application Selection

- (void)selectManagementApplication:(id<YKFKeyRawCommandServiceProtocol>)rawCommandService
                                              completion:(YKFKeyMGMTServiceSelectCompletionBlock)completion {
    YKFAPDU *selectApplicationAPDU = [[YKFSelectMGMTApplicationAPDU alloc] init];
            
    [rawCommandService executeCommand:selectApplicationAPDU completion:^(NSData *response, NSError *error) {

        NSError *returnedError = nil;
        
        if (error) {
            returnedError = error;
        } else {
            int statusCode = [YKFKeyService statusCodeFromKeyResponse: response];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    completion([[YKFKeyMGMTSelectApplicationResponse alloc] initWithKeyResponseData:[YKFKeyService dataFromKeyResponse:response]], nil);
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
