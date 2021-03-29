## HMAC-SHA1 challenge response session 

The `YKFChallengeResponseSession` provides a simple API for sending asynchronous request that exchanges challenge for response from a YubiKey.

This method also requires to provide a slot on YubiKey (1 or 2). By default all YubiKeys are programmed to have OTP secret on 1st slot (which requires short touch of YubiKey), but it can be swapped/programmed to use 2nd slot (requires long touch). One slot can be used to keep OTP secret or challenge-response secret and it's up to user which slot he would prefer to program for one feature or another.

In order to use the challenge response feature program your YubiKey with some secret. User needs to use  [YubiKey Manager](https://www.yubico.com/products/services-software/download/yubikey-manager/). This is a required one-time operation before using the session.

### Communicating with the challenge response session

The  `YKFChallengeResponseSession` is obtained by calling `- (void)challengeResponseSession:(YKFChallengeResponseSessionCallback _Nonnull)callback` on a `YKFConnectionProtocol`.  The method is guaranteed to either return the session or an error, never both nor neither. Once the connection returns a session the `YKFChallengeResponseSession` exposes the necessary methods to execute the challenge response command.

##### Swift

```swift
connection.challengeResponseSession { session, error in
    guard let session = session else { /* Handle error */; return }
    session.sendChallenge(data, slot: .one) { response, error in
        // Handle response
    }
}
```

##### Objective-C

```objective-c
 #import <YubiKit/YubiKit.h>

[connection challengeResponseSession:^(YKFChallengeResponseSession * _Nullable session, NSError * _Nullable error) {
    if (session == nil) { /* Handle error */ return; }
    [session sendChallenge:data slot:YKFSlotTwo completion:^(NSData * _Nullable response, NSError * _Nullable error) {
        // Handle response
    }];
}];
```

### Additional resources
Read more about the Yubico OTP protocol on the [Yubico developer site](https://developers.yubico.com/OTP/OTPs_Explained.html).
