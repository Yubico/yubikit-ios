## Using the HMAC-SHA1 challenge response Service 

This service usage is not coming as part of list of serviced provided by YubiKitManager singleton, but it's using  `YKFKeyRawCommandService` in implementation to communicate with YubiKey. How to implement such services yourself using  `YKFKeyRawCommandService`  read [here](../docs/raw.md)

The `YKFKeyChallengeResponseService` provides a simple API for sending asynchronous request that exchanges challenge for response from YubiKey.

This method also requires to provide a slot on YubiKey (1 or 2). By default all YubiKeys are programmed to have OTP secret on 1st slot (which requires short touch of YubiKey), but it can be swapped/programmed to use 2nd slot (requires long touch). One slot can be used to keep OTP secret or challenge-response secret and it's up to user which slot he would prefer to program for one feature or another.

### Prerequisite

In order to use challenge-response feature program your YubiKey with some secret. User needs to use  [YubiKey Manager](https://www.yubico.com/products/services-software/download/yubikey-manager/). This is required one-time operation before usage of this service.

##### Objective-C

```objective-c
 #import <YubiKit/YubiKit.h>
  
 ...

 YKFKeyChallengeResponseService *service = [[YKFKeyChallengeResponseService alloc] init];
 // exchange challenge for response (async operation)
[service sendChallenge:data slot:YKFSlot1 completion:^(NSData *response, NSError *error) {
    if (error) {
        // Handle the error
        return;
    }
    // Use the response from the key
}];
```    
	
##### Swift

```swift
let service = YKFKeyChallengeResponseService()
    // Asynchronous command execution. The sendChallenge() can be called from any thread.    
service.sendChallenge(data, slot:.one) { (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    assert(response != nil, "The response cannot be nil at this point.")
    // Use the response from the key
}
```    

If method is invoked when there is no connection with YubiKey than method `sendChallenge` will return an error. So it's delegated to user of APIs to make sure that YubiKey is plugged in or tapped over NFC reader when prompted. This can be reached by observing state properties of sessions that has been started by user: the `sessionState` property of `YKFAccessorySession` ( or `iso7816SessionState` property of `NFCSession`). If state is open it means that connection has been established.
The example of such observer can be found in the Examples/Observers project group of YubiKitDemo project.

