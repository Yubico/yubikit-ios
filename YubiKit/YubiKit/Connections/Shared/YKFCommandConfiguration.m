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

#import "YKFCommandConfiguration.h"

@implementation YKFCommandConfiguration

+ (YKFCommandConfiguration *)fastCommandCofiguration {
    YKFCommandConfiguration *configuration = [[YKFCommandConfiguration alloc] init];
    
    configuration.commandTime = 0.0;
    configuration.commandTimeout = 5;
    configuration.commandProbeTime = 0.05;
    
    return configuration;
}

+ (YKFCommandConfiguration *)defaultCommandCofiguration {
    YKFCommandConfiguration *configuration = [[YKFCommandConfiguration alloc] init];

    configuration.commandTime = 0.002;
    configuration.commandTimeout = 10;
    configuration.commandProbeTime = 0.05;
    
    return configuration;
}

+ (YKFCommandConfiguration *)longCommandCofiguration {
    YKFCommandConfiguration *configuration = [[YKFCommandConfiguration alloc] init];
    
    configuration.commandTime = 0.2;
    configuration.commandTimeout = 30;
    configuration.commandProbeTime = 0.05;
    
    return configuration;
}

@end
