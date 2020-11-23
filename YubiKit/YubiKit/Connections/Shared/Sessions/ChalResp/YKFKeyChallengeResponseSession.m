//
//  YKFKeyChallengeResponseService.m
//  YubiKit
//
//  Created by Irina Makhalova on 12/18/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import "YKFKeyChallengeResponseSession.h"
#import "YubiKitManager.h"
#import "YKFKeyChalRespSendRequest.h"
#import "YKFKeyChalRespRequest+Private.h"
#import "YKFKeyChallengeResponseError.h"
#import "YKFKeyChallengeResponseSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFKeyChallengeResponseError.h"
#import "YKFKeySessionError+Private.h"
#import "YKFSelectApplicationAPDU.h"

@interface YKFKeyChallengeResponseSession()

@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

@end

@implementation YKFKeyChallengeResponseSession

+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyChallengeResponseSessionCompletion _Nonnull)completion {
    
    YKFKeyChallengeResponseSession *session = [YKFKeyChallengeResponseSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameChalResp];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(session, nil);
        }
    }];
}

- (void)sendChallenge:(nonnull NSData *)challenge slot:(YKFSlot)slot completion:(nonnull YKFKeyChallengeResponseSessionResponseBlock)completion {
    YKFKeyChalRespSendRequest *request = [[YKFKeyChalRespSendRequest alloc] initWithChallenge:challenge slot: slot];
    [self.smartCardInterface executeCommand:request.apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else if (data.length == 0) {
            completion(nil, [YKFKeyChallengeResponseError errorWithCode:YKFKeyChallengeResponseErrorCodeEmptyResponse]);
        } else {
            completion(data, nil);
        }
    }];
}

- (void)clearSessionState {
    ;
}

@end
