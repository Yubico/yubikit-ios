// Copyright 2018-2022 Yubico AB
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

#ifndef YKFSmartCardConnectionController_h
#define YKFSmartCardConnectionController_h

#import "YKFConnectionControllerProtocol.h"

@class TKSmartCard;

@interface YKFSmartCardConnectionController: NSObject<YKFConnectionControllerProtocol>

typedef void (^YKFSmartCardConnectionControllerCompletionBlock)(YKFSmartCardConnectionController *_Nullable, NSError* _Nullable);
+ (void)smartCardControllerWithSmartCard:(TKSmartCard *_Nonnull)smartCard                                                                                      completion:(YKFSmartCardConnectionControllerCompletionBlock _Nonnull)completion;

- (void)endSession;

@end


#endif /* YKFSmartCardConnectionController_h */
