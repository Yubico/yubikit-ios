## FIDO2 Session

The `YKFFIDO2Session` provides access to the FIDO2 application on a YubiKey.

### Communicating with the FIDO2 application on the YubiKey

Communication with the FIDO2 application is done through the `YKFFIDO2Session` and the methods it expose. You obtain the session by calling `-(void)fido2Session:(YKFFIDO2SessionCallback _Nonnull)callback` on a `YKFConnectionProtocol`. The method is guaranteed to either return the session or an error, never both nor neither.

#### Swift

```swift
connection.fido2Session { (session, error) in
    guard let session = session else { return }
    session.getPinRetries { retries, error in
        // Display number of retries
    }
}
```

#### Objective-C

```objective-c
[connection fido2Session:^(YKFFIDO2Session * _Nullable session, NSError * _Nullable error) {
    if (session == nil) { /* Handle error */ return; }
    [session getPinRetriesWithCompletion:^(NSUInteger retries, NSError * _Nullable error) {
        // Display number of retries
    }];
}];
```

### Observing YubiKey FIDO2 state changes

Implement the `YKFFIDO2SessionKeyStateDelegate` protocol and set the delegate of the `YKFFIDO2Session` to observe changes to the YubiKeys state. This is needed for prompting the user to touch the key at certain points in the FIDO2 chain.

### Important Notes:

1. After PIN verification, YubiKit will automatically append the required PIN auth data to the FIDO2 requests when necessary. YubiKit does not cache any PIN. Instead it's using a temporary shared token, which was agreed between the key and YubiKit as defined by the CTAP2 specifications. This token is valid as long the session is opened and it's not persistent.

2. After verifying the PIN and executing the necessary requests with the key, the application can clear the shared token cache by calling `[clearUserVerification]` on the FIDO2 Service. This will also happen when the key is unplugged, taken away from the device, or when the session is closed programmatically.

3. After changing the PIN, a new PIN verification is required. 

### Additional resources

The YubiKit Demo application provides detailed demos on how to use the FIDO2 functionality of the library: 

- The `FIDO2 Demo` in the Other demos provides a self-contained demo for the requests discussed in this section and more details about the API. 

- The demo available in the FIDO2 tab of the application provides a complete example on how YubiKit can be used together with a WebAuthn server to register and authenticate. 

Read more about WebAuthn and FIDO2 on the [Yubico developer site](https://developers.yubico.com/WebAuthn/).
