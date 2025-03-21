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

#ifndef YKFSCPSessionKeys_h
#define YKFSCPSessionKeys_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKFSCPSessionKeys : NSObject

@property (nonatomic, strong, readonly) NSData *senc;
@property (nonatomic, strong, readonly) NSData *smac;
@property (nonatomic, strong, readonly) NSData *srmac;
@property (nonatomic, strong, readonly, nullable) NSData *dek;

- (instancetype)initWithSenc:(NSData *)senc smac:(NSData *)smac srmac:(NSData *)srmac dek:(nullable NSData *)dek;
- (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END
#endif /* YKFSCPSessionKeys_h */
