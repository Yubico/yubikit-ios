// Copyright Yubico AB
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

#import <Foundation/Foundation.h>
#import "YKFSCPKeyParamsProtocol.h"
#import "YKFSCPKeyRef.h"
#import "YKFSCPStaticKeys.h"
#import "YKFSCP11KeyParams.h"

@implementation YKFSCP11KeyParams

- (instancetype)initWithKeyRef:(YKFSCPKeyRef *)keyRef
                     pkSdEcka:(SecKeyRef)pkSdEcka {
    if ((0xff & keyRef.kid) != 0x13) {
        @throw [NSException exceptionWithName:@"InvalidKIDException"
                                       reason:@"Invalid KID for SCP03"
                                     userInfo:nil];
    }
    self = [super init];
    if (self) {
        _keyRef = keyRef;
        _pkSdEcka = (SecKeyRef)CFRetain(pkSdEcka);
    }
    return self;
}

- (void)dealloc {
    if (_pkSdEcka) {
        CFRelease(_pkSdEcka);
    }
}

@end

