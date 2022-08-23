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

#import <Foundation/Foundation.h>
#import <CryptoTokenKit/CryptoTokenKit.h>
#import "YKFSmartCardConnectionController.h"
#import "YKFAPDU+Private.h"
#import "YKFBlockMacros.h"
#import "YKFSessionError.h"
#import "YKFSessionError+Private.h"
#import "YKFAssert.h"

static NSTimeInterval const YKFSmartCardConnectionDefaultTimeout = 10.0;

@interface YKFSmartCardConnectionController()

@property (nonatomic, readwrite) TKSmartCard *smartCard;
@property (nonatomic) NSOperationQueue *communicationQueue;

@end

@implementation YKFSmartCardConnectionController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.communicationQueue = [[NSOperationQueue alloc] init];
        self.communicationQueue.maxConcurrentOperationCount = 1;
        dispatch_queue_attr_t dispatchQueueAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1);
        dispatch_queue_t dispatchQueue = dispatch_queue_create("com.yubico.SmartCard", dispatchQueueAttributes);
        self.communicationQueue.underlyingQueue = dispatchQueue;
    }
    return self;
}

+ (void)smartCardControllerWithSmartCard:(TKSmartCard *)smartCard                                                                                      completion:(YKFSmartCardConnectionControllerCompletionBlock _Nonnull)completion {
    YKFSmartCardConnectionController *controller = [YKFSmartCardConnectionController new];
    controller.smartCard = smartCard;
    [controller.smartCard beginSessionWithReply:^(BOOL success, NSError * _Nullable error) {
        if (error == nil) {
            completion(controller, nil);
        } else {
            completion(nil, error);
        }
    }];
}

- (void)endSession {
    [self.smartCard endSession];
}

- (void)cancelAllCommands {
    self.communicationQueue.suspended = YES;
    dispatch_suspend(self.communicationQueue.underlyingQueue);
    [self.communicationQueue cancelAllOperations];
    dispatch_resume(self.communicationQueue.underlyingQueue);
    self.communicationQueue.suspended = NO;
}

- (void)closeConnectionWithCompletion:(nonnull YKFConnectionControllerCompletionBlock)completion {
    completion();
}

- (void)dispatchBlockOnCommunicationQueue:(nonnull YKFConnectionControllerCommunicationQueueBlock)block {
    YKFParameterAssertReturn(block);
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    
    [operation addExecutionBlock:^{
        __strong NSBlockOperation *strongOperation = weakOperation;
        if (!strongOperation || strongOperation.isCancelled) {
            return;
        }
        block(strongOperation); // Execute the operation if it's still alive and not canceled.
    }];
    
    [self.communicationQueue addOperation:operation];;
}

- (void)execute:(nonnull YKFAPDU *)command completion:(nonnull YKFConnectionControllerCommandResponseBlock)completion {
    [self execute:command timeout:YKFSmartCardConnectionDefaultTimeout completion:completion];
}

- (void)execute:(nonnull YKFAPDU *)command timeout:(NSTimeInterval)timeout completion:(nonnull YKFConnectionControllerCommandResponseBlock)completion {
    
    ykf_weak_self();
    [self dispatchBlockOnCommunicationQueue:^(NSOperation *operation) {
        ykf_safe_strong_self();
        
        // Do not wait for the command to process if the operation was canceled.
        if (operation.isCancelled) {
            return;
        }
        
        // Verify that the smart card is still valid
        if (!strongSelf.smartCard.valid) {
            completion(nil, [YKFSessionError errorWithCode:YKFSessionErrorConnectionLost], 0);
            return;
        }
        
        __block NSError *executionError = nil;
        __block NSData *executionResult = nil;
        NSDate *commandStartDate = [NSDate date];
        dispatch_semaphore_t executionSemaphore = dispatch_semaphore_create(0);

        NSLog(@"Smart card will transmit: %@", [command apduData]);
        [strongSelf.smartCard transmitRequest:[command apduData] reply:^(NSData * _Nullable response, NSError * _Nullable error) {
            NSLog(@"Smart card transmitted with result: %@, %@", response, error);
            if (error) {
                executionError = error;
                dispatch_semaphore_signal(executionSemaphore);
                return;
            }
            
            executionResult = [response copy];
            dispatch_semaphore_signal(executionSemaphore);
        }];
        
        // Lock the async call to enforce the sequential execution using the library dispatch queue.
        dispatch_semaphore_wait(executionSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
        
        // Do not notify if the operation was canceled.
        if (operation.isCancelled) {
            return;
        }
        
        NSTimeInterval executionTime = [[NSDate date] timeIntervalSinceDate: commandStartDate];
        if (executionError) {
            completion(nil, executionError, executionTime);
        } else {
            YKFAssertReturn(executionResult, @"The command did not return any response data when error was not nil.");
            completion(executionResult, nil, executionTime);
        }
    }];
}
    
@end
