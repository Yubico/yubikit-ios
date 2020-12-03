// Copyright 2018-2020 Yubico AB
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
#import <objc/runtime.h>


void SwizzleClassMethod(Class class, SEL original, SEL new) {
    
    Method origMethod = class_getClassMethod(class, original);
    Method newMethod = class_getClassMethod(class, new);
    
    class = object_getClass((id)class);
    
    if(class_addMethod(class, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@implementation NSDate (Swizzling)

+ (void)swizzleDate {
    SwizzleClassMethod([NSDate class], @selector(date), @selector(alwaysSameDate));
}

+ (instancetype)alwaysSameDate {
    return [NSDate dateWithTimeIntervalSince1970:0];
}

@end
