//
//  YKFKeyChallengeResponseService.m
//  YubiKit
//
//  Created by Irina Makhalova on 12/18/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import "YKFKeyChallengeResponseSession.h"
#import "YubiKitManager.h"
#import "YKFSelectYubiKeyApplicationAPDU.h"
#import "YKFKeyChalRespSendRequest.h"
#import "YKFKeyChalRespRequest+Private.h"

#import "YKFAssert.h"
#import "YKFKeyChallengeResponseError.h"
#import "YKFKeySessionError.h"
#import "YKFKeySessionError+Private.h"
#import "YKFKeyAPDUError.h"

#import "YKFKeySession.h"
#import "YKFBlockMacros.h"

@interface YKFKeyChallengeResponseSession()

@end

@implementation YKFKeyChallengeResponseSession

- (void)sendChallenge:(nonnull NSData *)challenge slot:(YKFSlot)slot completion:(nonnull YKFKeyChallengeResponseSessionResponseBlock)completion {
    YKFKeyChalRespSendRequest *request = [[YKFKeyChalRespSendRequest alloc] initWithChallenge:challenge slot: slot];
    [self executeRequest:request completion:completion];
}

#pragma mark - execution of requests

- (void)executeRequest:(YKFKeyChalRespRequest *)request completion:(nonnull YKFKeyChallengeResponseSessionResponseBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    id<YKFKeyRawCommandSessionProtocol> rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService;
    if (rawCommandService == nil) {
        if (@available(iOS 13.0, *)) {
            rawCommandService = YubiKitManager.shared.nfcSession.rawCommandService;
        }
    }
    
    if (rawCommandService == nil) {
        completion(nil, [YKFKeyChallengeResponseError errorWithCode:YKFKeyChallengeResponseErrorCodeNoConnection]);
        return;
    }
       
    [self selectYubiKeyApplication:rawCommandService completion:^(NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        [self executeRequestWithoutApplicationSelection:rawCommandService request:request completion:completion];
    }];

}

- (void)executeRequestWithoutApplicationSelection:(id<YKFKeyRawCommandSessionProtocol>)rawCommandService
                                          request: (YKFKeyChalRespRequest *)request
                                       completion:(YKFKeyChallengeResponseSessionResponseBlock)completion {
    YKFParameterAssertReturn(rawCommandService);
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    [rawCommandService executeCommand:request.apdu configuration:[YKFKeyCommandConfiguration fastCommandCofiguration] completion:^(NSData *response, NSError *error) {
        
        if (error) {
            completion(nil, error);
        } else {
            int statusCode = [YKFKeySession statusCodeFromKeyResponse:response];
            switch (statusCode) {
                case YKFKeyAPDUErrorCodeNoError:
                    if (response.length > 2) {
                        completion([YKFKeySession dataFromKeyResponse:response], nil);
                    } else {
                        completion(nil, [YKFKeyChallengeResponseError errorWithCode:YKFKeyChallengeResponseErrorCodeEmptyResponse]);
                    }
                    break;
                    
                default:
                    completion(nil, [YKFKeySessionError errorWithCode:statusCode]);
                    break;
            }
        }
    }];
}

#pragma mark - Application Selection

- (void)selectYubiKeyApplication:(id<YKFKeyRawCommandSessionProtocol>)rawCommandService
                                              completion:(void (^)(NSError *))completion {
    YKFAPDU *selectYubiKeyApplicationAPDU = [[YKFSelectYubiKeyApplicationAPDU alloc] init];
            
    [rawCommandService executeCommand:selectYubiKeyApplicationAPDU configuration:[YKFKeyCommandConfiguration fastCommandCofiguration] completion:^(NSData *response, NSError *error) {

        NSError *returnedError = nil;
        
        if (error) {
            returnedError = error;
        } else {
            int statusCode = [YKFKeySession statusCodeFromKeyResponse: response];
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

@end
