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

#import "YKFKeyChallengeResponseSession+Private.h"
#import "YKFKeyRawCommandSession+Private.h"

@interface YKFKeyChallengeResponseSession()

@end

@implementation YKFKeyChallengeResponseSession

+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyChallengeResponseSessionCompletion _Nonnull)completion {
    
   YKFKeyChallengeResponseSession *session = [[YKFKeyChallengeResponseSession alloc] initWithConnectionController:connectionController];

    [session selectYubiKeyApplication:^(NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(session, nil);
        }
    }];
}

- (void)sendChallenge:(nonnull NSData *)challenge slot:(YKFSlot)slot completion:(nonnull YKFKeyChallengeResponseSessionResponseBlock)completion {
    YKFKeyChalRespSendRequest *request = [[YKFKeyChalRespSendRequest alloc] initWithChallenge:challenge slot: slot];
    [self executeRequest:request completion:completion];
}

#pragma mark - execution of requests

- (void)executeRequest:(YKFKeyChalRespRequest *)request
            completion:(YKFKeyChallengeResponseSessionResponseBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    [self executeCommand:request.apdu configuration:[YKFKeyCommandConfiguration fastCommandCofiguration] completion:^(NSData *response, NSError *error) {
        
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

- (void)selectYubiKeyApplication:(void (^)(NSError *))completion {
    YKFAPDU *selectYubiKeyApplicationAPDU = [[YKFSelectYubiKeyApplicationAPDU alloc] init];
    
    [self executeCommand:selectYubiKeyApplicationAPDU configuration:[YKFKeyCommandConfiguration fastCommandCofiguration] completion:^(NSData *response, NSError *error) {

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
