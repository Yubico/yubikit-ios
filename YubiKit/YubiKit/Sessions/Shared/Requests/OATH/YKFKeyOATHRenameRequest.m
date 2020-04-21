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

#import "YKFKeyOATHRenameRequest.h"
#import "YKFOATHRenameAPDU.h"
#import "YKFAssert.h"
#import "YKFKeyOATHRequest+Private.h"

@interface YKFKeyOATHRenameRequest()

@property (nonatomic, readwrite) YKFOATHCredential *credential;
@property (nonatomic, readwrite) NSString *issuer;
@property (nonatomic, readwrite) NSString *account;

@end

@implementation YKFKeyOATHRenameRequest

- (nullable instancetype)initWithCredential:(nonnull YKFOATHCredential*)credential issuer:(nonnull NSString *)issuer account:(nonnull NSString *)account {
    YKFAssertAbortInit(credential);
    
    self = [super init];
    if (self) {
        self.credential = credential;
        self.issuer = issuer;
        self.account = account;
        self.apdu = [[YKFOATHRenameAPDU alloc] initWithRequest:self];
    }
    return self;
}

@end
