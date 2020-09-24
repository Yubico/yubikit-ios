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

#import <ExternalAccessory/ExternalAccessory.h>
#import <UIKit/UIKit.h>

#import "YKFAccessoryConnection.h"
#import "YKFAccessoryConnection+Private.h"
#import "YKFAccessoryConnection+Debugging.h"

#import "YubiKitDeviceCapabilities.h"
#import "YKFAccessoryConnectionController.h"
#import "YKFAccessoryConnectionConfiguration.h"
#import "YKFKeyCommandConfiguration.h"
#import "YKFAccessoryDescription.h"
#import "YKFKVOObservation.h"
#import "YKFBlockMacros.h"
#import "YKFLogger.h"
#import "YKFDispatch.h"
#import "YKFAssert.h"

#import "YKFKeyRawCommandService+Private.h"
#import "YKFKeyOATHSession+Private.h"
#import "YKFKeyU2FService+Private.h"
#import "YKFKeyFIDO2Session+Private.h"
#import "YKFKeyService+Private.h"
#import "YKFAccessoryDescription+Private.h"

#import "EAAccessory+Testing.h"
#import "EASession+Testing.h"

#import "YKFKeySessionError.h"
#import "YKFKeySessionError+Private.h"

#pragma mark - Private Block Types

typedef void (^YKFAccessorySessionDispatchBlock)(void);

#pragma mark - Constants

NSString* const YKFAccessoryConnectionStatePropertyKey = @"sessionState";
NSString* const YKFAccessoryConnectionU2FServicePropertyKey = @"u2fService";
NSString* const YKFAccessoryConnectionFIDO2ServicePropertyKey = @"fido2Service";

static NSTimeInterval const YubiAccessorySessionStartDelay = 0.05; // seconds
static NSTimeInterval const YubiAccessorySessionStreamOpenDelay = 0.2; // seconds

#pragma mark - YKFAccessorySession

@interface YKFAccessoryConnection()<NSStreamDelegate, YKFKeyServiceDelegate>

// Dispatching

@property (nonatomic) NSOperationQueue *communicationQueue;
@property (nonatomic) dispatch_queue_t sharedDispatchQueue;

// Accessory

@property (nonatomic, readwrite) YKFAccessoryDescription *accessoryDescription;

@property (nonatomic) id<YKFEAAccessoryManagerProtocol> accessoryManager;
@property (nonatomic) id<YKFEAAccessoryProtocol> accessory;
@property (nonatomic) id<YKFEASessionProtocol> session;

@property (nonatomic) id<YKFKeyConnectionControllerProtocol> connectionController;

// Services

@property (nonatomic, assign, readwrite) YKFAccessoryConnectionState connectionState;

@property (nonatomic, readwrite) id<YKFKeyU2FServiceProtocol, YKFKeyServiceDelegate> u2fService;
@property (nonatomic, readwrite) id<YKFKeyFIDO2SessionProtocol, YKFKeyServiceDelegate> fido2Service;
@property (nonatomic, readwrite) id<YKFKeyOATHSessionProtocol, YKFKeyServiceDelegate> oathService;
@property (nonatomic, readwrite) id<YKFKeyRawCommandServiceProtocol, YKFKeyServiceDelegate> rawCommandService;

// Observation

@property (nonatomic, assign) BOOL observeAccessoryConnection;
@property (nonatomic, assign) BOOL observeApplicationState;

// Behaviour

@property (nonatomic) id<YKFAccessoryConnectionConfigurationProtocol> configuration;
@property (nonatomic) NSString *currentKeyProtocol; // The protocol used to create a communication session with the key.

// Flags

@property (nonatomic, assign) BOOL reconnectOnApplicationActive;

@end

@implementation YKFAccessoryConnection

- (instancetype)initWithAccessoryManager:(id<YKFEAAccessoryManagerProtocol>)accessoryManager configuration:(YKFAccessoryConnectionConfiguration *)configuration {
    YKFAssertAbortInit(accessoryManager);
    YKFAssertAbortInit(configuration);
    
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.accessoryManager = accessoryManager;
        
        [self setupCommunicationQueue];
    }
    return self;
}

- (void)oathSession:(OATHSession _Nonnull)callback {
    if (!self.oathService) {
        callback(nil, [YKFKeySessionError errorWithCode:YKFKeySessionErrorNoConnection]);
    }
    ykf_weak_self();
    [self.oathService selectOATHApplicationWithCompletion:^(YKFKeyOATHSelectApplicationResponse * _Nullable response, NSError * _Nullable error) {
        ykf_safe_strong_self();
        if (error != nil) {
            callback(nil, error);
        } else {
            callback(strongSelf.oathService, nil);
        }
    }];
}

- (void)dealloc {
    self.observeAccessoryConnection = NO;
    self.observeApplicationState = NO;
}

#pragma mark - Private properties

- (BOOL)isKeyConnected {
    for (EAAccessory *connectedAccessory in self.accessoryManager.connectedAccessories) {
        if ([self shouldAcceptAccessory:connectedAccessory]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Session start/stop

- (void)start {
    YKFAssertReturn(YubiKitDeviceCapabilities.supportsMFIAccessoryKey, @"Cannot start the key session on an unsupported device.");
    YKFLogInfo(@"Accessory session start requested.");
    
#ifdef DEBUG
    [self checkApplicationConfiguration];
#endif
    
    if (self.connectionState != YKFAccessoryConnectionStateClosed) {
        YKFLogInfo(@"Accessory session start ignored. The session is already started.");
        return;
    }
    
    self.observeAccessoryConnection = YES;
    self.observeApplicationState = YES;

    [self connectToExistingKey]; // If a key is already plugged, connect to it.
}

- (BOOL)startSynchronous {
    YKFAssertOffMainThread();
    
    YKFAssertReturnValue(YubiKitDeviceCapabilities.supportsMFIAccessoryKey, @"Cannot start the accessory session on an unsupported device.", NO);
    YKFAssertReturnValue(self.isKeyConnected, @"Cannot start the session if the key is not connected.", NO);
    
    if (self.connectionState == YKFAccessoryConnectionStateOpen) {
        return YES;
    }
    
    dispatch_semaphore_t openSemaphore = dispatch_semaphore_create(0);
    
    YKFKVOObservation *observation = [[YKFKVOObservation alloc] initWithTarget:self keyPath:YKFAccessoryConnectionStatePropertyKey callback:^(id oldValue, id newValue) {
        YKFAccessoryConnectionState newState = ((NSNumber *)newValue).unsignedLongValue;
        if (newState == YKFAccessoryConnectionStateOpen) {
            dispatch_semaphore_signal(openSemaphore);
        }
    }];
    YKFAssertReturnValue(observation, @"Could not observe the session state.", NO);
    
    [self start];
    
    YKFKeyCommandConfiguration *configuration = [YKFKeyCommandConfiguration defaultCommandCofiguration];
    dispatch_semaphore_wait(openSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(configuration.commandTimeout * NSEC_PER_SEC)));
    
    observation = nil;
    
    // There was an error when opening the session
    if (self.connectionState != YKFAccessoryConnectionStateOpen) {
        return NO;
    }
    
    return YES;
}

- (void)stop {
    YKFLogInfo(@"Accessory session stop requested.");
    
    if (self.connectionState != YKFAccessoryConnectionStateOpen) {
        YKFLogInfo(@"Accessory session stop ignored. The session is already stopped.");
        return;
    }

    self.observeAccessoryConnection = NO;
    self.observeApplicationState = NO;

    [self closeSession];
}

- (BOOL)stopSynchronous {
    YKFAssertOffMainThread();
    YKFAssertReturnValue(self.isKeyConnected, @"Cannot stop the session if the key is not connected.", NO);
    
    if (self.connectionState == YKFAccessoryConnectionStateClosed) {
        return YES;
    }
        
    dispatch_semaphore_t closeSemaphore = dispatch_semaphore_create(0);
    
    YKFKVOObservation *observation = [[YKFKVOObservation alloc] initWithTarget:self keyPath:YKFAccessoryConnectionStatePropertyKey callback:^(id oldValue, id newValue) {
        YKFAccessoryConnectionState newState = ((NSNumber *)newValue).unsignedLongValue;
        if (newState == YKFAccessoryConnectionStateClosed) {
            dispatch_semaphore_signal(closeSemaphore);
        }
    }];
    YKFAssertReturnValue(observation, @"Could not observe the session state.", NO);
    
    [self stop];
    
    YKFKeyCommandConfiguration *configuration = [YKFKeyCommandConfiguration defaultCommandCofiguration];
    dispatch_semaphore_wait(closeSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(configuration.commandTimeout * NSEC_PER_SEC)));
    
    observation = nil;
    
    // There was an error when closing the session
    if (self.connectionState != YKFAccessoryConnectionStateClosed) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Notification subscription

- (void)setObserveApplicationState:(BOOL)observeApplicationState {
    if (_observeApplicationState == observeApplicationState) {
        return;
    }
    _observeApplicationState = observeApplicationState;
    if (_observeApplicationState) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (void)setObserveAccessoryConnection:(BOOL)observeAccessoryConnection {
    if (_observeAccessoryConnection == observeAccessoryConnection) {
        return;
    }
    _observeAccessoryConnection = observeAccessoryConnection;
    if (_observeAccessoryConnection) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidConnect:)
                                                     name:EAAccessoryDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidDisconnect:)
                                                     name:EAAccessoryDidDisconnectNotification object:nil];
        
        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
        
        [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    }
}

- (void)connectToExistingKey {
    for (EAAccessory *connectedAccessory in self.accessoryManager.connectedAccessories) {
        if (![self shouldAcceptAccessory:connectedAccessory]) {
            continue;
        }
        
        NSDictionary *userInfo = @{EAAccessoryKey: connectedAccessory};
        NSNotification *notification = [[NSNotification alloc] initWithName:EAAccessoryDidConnectNotification object:self userInfo:userInfo];
        [self accessoryDidConnect:notification];
        break;
    }
}

#pragma mark - Session state

- (void)setConnectionState:(YKFAccessoryConnectionState)sessionState {
    // Avoid updating the state if the same to not trigger unnecessary KVO notifications.
    if (sessionState == _connectionState) {
        return;
    }
    _connectionState = sessionState;
}

#pragma mark - Shared communication queue

- (void)setupCommunicationQueue {
    // Create a sequential queue because the YubiKey accepts sequential commands.
    
    self.communicationQueue = [[NSOperationQueue alloc] init];
    self.communicationQueue.maxConcurrentOperationCount = 1;
    
    dispatch_queue_attr_t dispatchQueueAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1);
    self.sharedDispatchQueue = dispatch_queue_create("com.yubico.YKCOMACC", dispatchQueueAttributes);
    
    self.communicationQueue.underlyingQueue = self.sharedDispatchQueue;
}

- (void)dispatchOnSharedQueueBlock:(YKFAccessorySessionDispatchBlock)block delay:(NSTimeInterval)delay {
    YKFParameterAssertReturn(block);
    YKFParameterAssertReturn(self.sharedDispatchQueue);
    
    if (delay > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), self.sharedDispatchQueue, block);
    } else {
        dispatch_async(self.sharedDispatchQueue, block);
    }
}

- (void)dispatchOnSharedQueueBlock:(YKFAccessorySessionDispatchBlock)block {
    [self dispatchOnSharedQueueBlock:block delay:0];
}

#pragma mark - Accessory connection

- (void)accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *accessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    if (![self shouldAcceptAccessory:accessory]) {
        return;
    }
    
    self.currentKeyProtocol = [self.configuration keyProtocolForAccessory:accessory];
    YKFAssertReturn(self.currentKeyProtocol != nil, @"Could not find a valid protocol for the accessory.");
    
    YKFLogInfo(@"The YubiKey is connected to the iOS device.");
    
    self.accessory = accessory;
    self.accessoryDescription = [[YKFAccessoryDescription alloc] initWithAccessory:self.accessory];
    if (!self.accessoryDescription) {
        // If a key description could not be fetched, do not start the session.
        return;
    }
    
    self.connectionState = YKFAccessoryConnectionStateOpening;
    
    ykf_weak_self();
    [self dispatchOnSharedQueueBlock:^{
        ykf_safe_strong_self();
        BOOL success = [strongSelf openSession];
        if (!success) {
            strongSelf.connectionState = YKFAccessoryConnectionStateClosed;
            return;
        }
        
        [strongSelf dispatchOnSharedQueueBlock:^{
            strongSelf.connectionState = YKFAccessoryConnectionStateOpen;
        } delay:YubiAccessorySessionStreamOpenDelay]; // Add a small delay to allow the streams to open.
    }
    delay:YubiAccessorySessionStartDelay]; // Add a small delay to allow the Key to initialize after connected.
}

- (void)accessoryDidDisconnect:(id)notification {
    if (!self.accessory) { return; }
    
    // Framework bug workaround
    EAAccessory *accessory = [notification isKindOfClass:[EAAccessory class]] ? (EAAccessory*)notification : [[notification userInfo] objectForKey:EAAccessoryKey];
    
    if (accessory.connectionID != self.accessory.connectionID) {
        return;
    }
    
    YKFLogInfo(@"The YubiKey is disconnected from the iOS device.");
    
    self.accessory = nil;
    self.accessoryDescription = nil;
    
    // Close session will dispatch the cleanup of streams on the dispatch queue.
    [self closeSession];
}

#pragma mark - Application Notifications

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self closeSession];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.connectionState == YKFAccessoryConnectionStateClosed) {
        return;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithName:@"CloseSessionTask" expirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        YKFLogVerbose(@"Background task expired.");
    }];
    
    if (self.connectionState == YKFAccessoryConnectionStateOpen || self.connectionState == YKFAccessoryConnectionStateOpening) {
        self.reconnectOnApplicationActive = YES;
        [self closeSession];
    }
    
    // Dispatch a subsequent operation which will wait for closing.
    dispatch_async(self.sharedDispatchQueue, ^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        YKFLogVerbose(@"Background task ended.");
    });
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.reconnectOnApplicationActive) {
        [self connectToExistingKey];
    }
}

#pragma mark - Session

- (BOOL)openSession {
    YKFAssertOffMainThread();
    YKFAssertReturnValue(self.currentKeyProtocol != nil, @"No known protocol to connect to the key.", NO);

    self.session = [[EASession alloc] initWithAccessory:self.accessory forProtocol:self.currentKeyProtocol];
    
    if (self.session) {
        self.reconnectOnApplicationActive = NO;
        self.connectionController = [[YKFAccessoryConnectionController alloc] initWithSession:self.session operationQueue:self.communicationQueue];
        self.session.outputStream.delegate = self;
        
        /*
         Setup services after the connection is created
         */
        
        YKFKeyU2FService *u2fService = [[YKFKeyU2FService alloc] initWithConnectionController:self.connectionController];
        u2fService.delegate = self;
        self.u2fService = u2fService;
        
        YKFKeyFIDO2Session *fido2Service = [[YKFKeyFIDO2Session alloc] initWithConnectionController:self.connectionController];
        fido2Service.delegate = self;
        self.fido2Service = fido2Service;
        
        YKFKeyOATHSession *oathService = [[YKFKeyOATHSession alloc] initWithConnectionController:self.connectionController];
        oathService.delegate = self;
        self.oathService = oathService;
        
        YKFKeyRawCommandService *rawCommandService = [[YKFKeyRawCommandService alloc] initWithConnectionController:self.connectionController];
        rawCommandService.delegate = self;
        self.rawCommandService = rawCommandService;
        
        YKFLogInfo(@"Session opened.");
    } else {
        YKFLogInfo(@"Session opening failed.");
    }
    return self.session != nil;
}

- (void)closeSession {
    if (!self.session) {
        return;
    }
    if (self.connectionState == YKFAccessoryConnectionStateClosed || self.connectionState == YKFAccessoryConnectionStateClosing) {
        return;
    }
    
    self.connectionState = YKFAccessoryConnectionStateClosing;
        
    ykf_weak_self();
    [self.connectionController closeConnectionWithCompletion:^{
        ykf_safe_strong_self();
        
        // Clean services first
        strongSelf.u2fService = nil;
        strongSelf.fido2Service = nil;
        strongSelf.oathService = nil;
        strongSelf.rawCommandService = nil;
        
        strongSelf.connectionController = nil;
        strongSelf.session = nil;
        
        strongSelf.connectionState = YKFAccessoryConnectionStateClosed;
        YKFLogInfo(@"Session closed.");
    }];
}

#pragma mark - Commands

- (void)cancelCommands {
    [self.connectionController cancelAllCommands];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (eventCode != NSStreamEventErrorOccurred && eventCode != NSStreamEventEndEncountered) {
        return;
    }
    
    // Stream was closed as a part of a normal session shutdown
    if (self.connectionState != YKFAccessoryConnectionStateOpen) {
        return;
    }
    
    // Stream  was dropped or externally closed -> close the session to avoid lingering
    YKFLogInfo(@"The communication with the key was closed by the system.");
    [self closeSession];
    
    __block UIApplicationState applicationState = UIApplicationStateActive;
    ykf_dispatch_block_sync_main(^{
        applicationState = [UIApplication sharedApplication].applicationState;
    });
    
    // If the connection was lost in inactive or backgroud states -> mark it for reconnecting again when the application becomes active.
    if (applicationState != UIApplicationStateActive) {
        self.reconnectOnApplicationActive = YES;
    }
}

#pragma mark - YKFKeyServiceDelegate

- (void)keyService:(YKFKeyService *)service willExecuteRequest:(YKFKeyRequest *)request {
    [self.u2fService keyService:service willExecuteRequest:request];
    [self.fido2Service keyService:service willExecuteRequest:request];
    [self.oathService keyService:service willExecuteRequest:request];
    [self.rawCommandService keyService:service willExecuteRequest:request];
}

#pragma mark - Helpers

- (BOOL)shouldAcceptAccessory:(EAAccessory*)accessory {
    YKFParameterAssertReturnValue(accessory, NO);
    return [self.configuration allowsAccessory:accessory];
}

@end
