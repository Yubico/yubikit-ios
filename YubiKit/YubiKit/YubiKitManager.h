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
#import <UIKit/UIKit.h>

#import "YKFNFCConnection.h"
#import "YKFAccessoryConnection.h"

/*!
 @protocol YubiKitManagerProtocol
 
 @abstract
    Provides the main access point interface for YubiKit.
 */

@protocol YKFManagerDelegate <NSObject>

- (void)didConnectNFC:(id<YKFNFCConnectionProtocol>_Nonnull)connection;
- (void)didDisconnectNFC:(id<YKFNFCConnectionProtocol>_Nonnull)connection error:(NSError *_Nullable)error;

- (void)didConnectAccessory:(YKFAccessoryConnection *_Nonnull)connection;
- (void)didDisconnectAccessory:(YKFAccessoryConnection *_Nonnull)connection error:(NSError *_Nullable)error;

@end


@protocol YubiKitManagerProtocol

@property(nonatomic, weak) id<YKFManagerDelegate> _Nullable delegate;

- (void)startNFCConnection API_AVAILABLE(ios(13.0));
- (void)stopNFCConnection API_AVAILABLE(ios(13.0));

- (void)startAccessoryConnection;
- (void)stopAccessoryConnection;

/*!
 @property nfcReaderSession
 
 @abstract
    Returns the shared instance of YKFNFCSession to interact with the NFC reader.
 */
@property (nonatomic, readonly, nonnull) id<YKFNFCConnectionProtocol> nfcSession NS_AVAILABLE_IOS(11.0);

/*!
 @property accessorySession
 
 @abstract
    Returns the shared instance of YKFAccessorySession to interact with a MFi accessory YubiKey.
 */
@property (nonatomic, readonly, nonnull) YKFAccessoryConnection *accessorySession;

@end


/*!
 @class YubiKitManager
 
 @abstract
    Provides the main access point for YubiKit.
 */
@interface YubiKitManager : NSObject<YubiKitManagerProtocol>

/*!
 @property shared
 
 @abstract
    YubiKitManager is a singleton and should be accessed only by using the shared instance provided by this property.
 */
@property (class, nonatomic, readonly, nonnull) id<YubiKitManagerProtocol> shared;

/*
 Not available: use the shared property from YubiKitManager to retreive the shared single instance.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
