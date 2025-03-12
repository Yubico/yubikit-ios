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

#ifndef YKFSCPStaticKeys_h
#define YKFSCPStaticKeys_h

#import <Foundation/Foundation.h>
#import "YKFSCPSessionKeys.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFSCPStaticKeys : NSObject

@property (nonatomic, strong, readonly) NSData *enc;
@property (nonatomic, strong, readonly) NSData *mac;
@property (nonatomic, strong, readonly, nullable) NSData *dek;

- (instancetype)initWithEnc:(NSData *)enc mac:(NSData *)mac dek:(nullable NSData *)dek;
- (YKFSCPSessionKeys *)deriveWithContext:(NSData *)context;
+ (instancetype)defaultKeys;
+ (NSData *)deriveKeyWithKey:(NSData *)key t:(int8_t)t context:(NSData *)context l:(int16_t)l error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

#endif /* YKFSCPStaticKeys_h */
