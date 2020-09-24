//
//  YKFKeyMGMTSession.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyMGMTSession.h"
#import "YubiKitManager.h"
#import "YKFKeyRawCommandSession.h"

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

typedef void (^YKFKeyMGMTSessionResultCompletionBlock)(NSData* _Nullable  result, NSError* _Nullable error);
typedef void (^YKFKeyMGMTSessionSelectCompletionBlock)(YKFKeyMGMTSelectApplicationResponse* _Nullable  result, NSError* _Nullable error);


@implementation YKFKeyMGMTSession

- (void)readConfigurationWithCompletion:(YKFKeyMGMTSessionReadCompletionBlock)completion {
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

- (void) writeConfiguration:(YKFMGMTInterfaceConfiguration*) configuration reboot: (BOOL) reboot completion: (nonnull YKFKeyMGMTSessionWriteCompletionBlock) completion {
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

- (void)executeRequest:(YKFKeyMGMTRequest *)request completion:(nonnull YKFKeyMGMTSessionResultCompletionBlock)completion {
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
    
    [self selectManagementApplication:rawCommandService completion:^(YKFKeyMGMTSelectApplicationResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        [self executeRequestWithoutApplicationSelection:rawCommandService request:request completion:completion];
    }];

}

- (void)executeRequestWithoutApplicationSelection:(id<YKFKeyRawCommandSessionProtocol>)rawCommandService
                                          request: (YKFKeyMGMTRequest *)request
                                       completion:(YKFKeyMGMTSessionResultCompletionBlock)completion {
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
                                              completion:(YKFKeyMGMTSessionSelectCompletionBlock)completion {
    YKFAPDU *selectApplicationAPDU = [[YKFSelectMGMTApplicationAPDU alloc] init];
            
    [rawCommandService executeCommand:selectApplicationAPDU completion:^(NSData *response, NSError *error) {

        NSError *returnedError = nil;
        
        if (error) {
            returnedError = error;
        } else {
            int statusCode = [YKFKeySession statusCodeFromKeyResponse: response];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    completion([[YKFKeyMGMTSelectApplicationResponse alloc] initWithKeyResponseData:[YKFKeySession dataFromKeyResponse:response]], nil);
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
