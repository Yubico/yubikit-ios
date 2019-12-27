//
//  YKFKeyChalRespSendRequest.m
//  YubiKit
//
//  Created by Irina Makhalova on 12/26/19.
//  Copyright © 2019 Yubico. All rights reserved.
//

#import "YKFKeyChalRespSendRequest.h"
#import "YKFKeyChalRespRequest+Private.h"
#import "YKFHMAC1ChallengeResponseAPDU.h"
#import "YKFAssert.h"

@interface YKFKeyChalRespSendRequest()

@property (nonatomic, readwrite) NSData *challenge;
@property (nonatomic, readwrite) YKFSlot slot;
@end

@implementation YKFKeyChalRespSendRequest

- (nullable instancetype)initWithChallenge:(nonnull NSData*)challenge slot:(YKFSlot) slot {
    YKFAssertAbortInit(challenge);
    
    self = [super init];
    if (self) {
        self.challenge = challenge;
        self.slot = slot;
        self.apdu = [[YKFHMAC1ChallengeResponseAPDU alloc] initWithRequest:self];
    }
    return self;
}

@end
