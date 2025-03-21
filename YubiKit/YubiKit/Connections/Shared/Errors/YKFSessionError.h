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

/*!
 @constant
    YKFSessionErrorDomain
 @abstract
    Domain for errors generated by a communication session with a key.
 */
extern NSString* const YKFSessionErrorDomain;

typedef NS_ENUM(NSUInteger, YKFSessionErrorCode) {
    
    /*! When the key didn't repond to an issued command. In such a scenario the key may not be properly connected
     to the device or the communication with the key is somehow broken along the SDK-IAP2-Firmware path. In such
     a scenario replugging or checking if the key is properly connected may solve the issue.
     */
    YKFSessionErrorReadTimeoutCode = 0x000001,
    
    /*! When the library cannot write/send a command to the key. In such a scenario the key may not be properly connected
     to the device or the communication with the key is somehow broken along the SDK-IAP2-Firmware path. In such
     a scenario replugging or checking if the key is properly connected may solve the issue.
     */
    YKFSessionErrorWriteTimeoutCode = 0x000002,
    
    /*! When the key expects the user to confirm the presence by touching the key. The user didn't touch the key
     for 15 seconds so the operation was canceled.
     */
    YKFSessionErrorTouchTimeoutCode = 0x000003,
    
    /*! A request to the key cannot be performed because the key is performing another operation.
     @discussion
        This should not be an issue when using only YubiKit because YubiKit will execute the requests sequentially. This issue
        may happen when the key is performing an operation on behalf of another application or if the user is generating an OTP
        which is independent of YubiKit. The key operations are usually fast so a recovery solution is to try again in a few seconds.
     */
    YKFSessionErrorKeyBusyCode = 0x000004,

    /*! A certain key application is missing or it was disabled using a configuration tool like YubiKey Manager. In such a scenario
     the functionality of the key should be enabled before trying again the request.
     */
    YKFSessionErrorMissingApplicationCode = 0x000005,
    
    /*! A request to the key cannot be performed because the connection was lost
     (e.g. Tag was lost when key was taken away from NFC reader)
     */
    YKFSessionErrorConnectionLost = 0x000006,
    
    /*! A request to the key cannot be performed because the connection was not found
     */
    YKFSessionErrorNoConnection = 0x000007,
    
    /*! A request to the key returned an unexpected result
     */
    YKFSessionErrorUnexpectedStatusCode = 0x000007,
    
    /*! Invalid session state. This can be caused by another session connecting to the Yubkey or stale stored state.
     */
    YKFSessionErrorInvalidSessionStateStatusCode = 0x000008,
    
    /*! Unexpected result. This is caused when the YubiKey returns unexpected data.
     */
    YKFSessionErrorUnexpectedResult = 0x000009
};

/*!
 @class
    YKFSessionError
 @abstract
    Error type returned by the YKFAccessorySession.
 */
@interface YKFSessionError : NSError

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
