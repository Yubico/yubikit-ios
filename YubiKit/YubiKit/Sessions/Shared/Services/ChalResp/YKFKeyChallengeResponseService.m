//
//  YKFKeyChallengeResponseService.m
//  YubiKit
//
//  Created by Irina Makhalova on 12/18/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import "YKFKeyChallengeResponseService.h"
#import "YKFKeyRawCommandService.h"
#import "YKFSelectYubiKeyApplicationAPDU.h"
#import "YKFKeyChalRespSendRequest.h"
#import "YKFKeyChalRespRequest+Private.h"
#import "YKFKeySessionError.h"
#import "YKFKeySessionError+Private.h"
#import "YKFKeyAPDUError.h"
#import "YKFKeyService.h"
#import "YKFBlockMacros.h"
#import "YKFAssert.h"

@interface YKFKeyChallengeResponseService()

@property (nonatomic) id<YKFKeyRawCommandServiceProtocol> rawCommandService;

@end

@implementation YKFKeyChallengeResponseService

- (instancetype)initWithService:(id<YKFKeyRawCommandServiceProtocol>)rawCommandService {
    YKFAssertAbortInit(rawCommandService);
    
    self = [super init];
    if (self) {
        self.rawCommandService = rawCommandService;
    }
    return self;
}

- (void)sendChallenge:(nonnull NSData *)challenge slot:(YKFSlot)slot completion:(nonnull YKFKeyChallengeResponseServiceResponseBlock)completion {
    YKFKeyChalRespSendRequest *request = [[YKFKeyChalRespSendRequest alloc] initWithChallenge:challenge slot: slot];
    [self executeRequest:request completion:completion];
}

#pragma mark - execution of requests

- (void)executeRequest:(YKFKeyChalRespRequest *)request completion:(nonnull YKFKeyChallengeResponseServiceResponseBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    ykf_weak_self();
    [self selectYubiKeyApplicationWithCompletion:^(NSError *error) {
        ykf_safe_strong_self();
        if (error) {
            completion(nil, error);
            return;
        }
        [strongSelf executeRequestWithoutApplicationSelection:request completion:completion];
    }];

}

- (void)executeRequestWithoutApplicationSelection:(YKFKeyChalRespRequest *)request completion:(YKFKeyChallengeResponseServiceResponseBlock)completion {
    YKFParameterAssertReturn(request);
    YKFParameterAssertReturn(completion);

    ykf_weak_self();
    [self.rawCommandService executeCommand:request.apdu completion:^(NSData *response, NSError *error) {
        ykf_safe_strong_self();
        
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

- (void)selectYubiKeyApplicationWithCompletion:(void (^)(NSError *))completion {
    YKFAPDU *selectYubiKeyApplicationAPDU = [[YKFSelectYubiKeyApplicationAPDU alloc] init];
        
    ykf_weak_self();
    
    [self.rawCommandService executeCommand:selectYubiKeyApplicationAPDU completion:^(NSData *response, NSError *error) {

        ykf_safe_strong_self();
        
        NSError *returnedError = nil;
        
        if (error) {
            returnedError = error;
        } else {
            int statusCode = [YKFKeyService statusCodeFromKeyResponse: response];
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
