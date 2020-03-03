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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKFKeyCommandConfiguration: NSObject

/// The expected avarage execution time for the command. The timeout between sending command to the device and receiving response
@property (nonatomic, assign) NSTimeInterval commandTime;

/// The timeout for a command.
@property (nonatomic, assign) NSTimeInterval commandTimeout;

/// The time to wait between data availabe checks.
@property (nonatomic, assign) NSTimeInterval commandProbeTime;

// Factory methods

+ (YKFKeyCommandConfiguration *)fastCommandCofiguration;
+ (YKFKeyCommandConfiguration *)defaultCommandCofiguration;
+ (YKFKeyCommandConfiguration *)longCommandCofiguration;

@end

NS_ASSUME_NONNULL_END
