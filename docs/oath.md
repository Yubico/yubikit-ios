
## OATH Session

The `YKFOATHSession` provides access to the OATH application on a YubiKey, for managing and using OATH TOTP and OATH HOTP credentials (as specified in RFC 6238 and RFC 4226).

### Communicating with the OATH application on the YubiKey

Communication with the OATH application is done through the `YKFOATHSession` and the methods it expose. You obtain the session by calling `- (void)oathSession:(YKFOATHSessionCallback _Nonnull)callback` on a `YKFConnectionProtocol`. The method is guaranteed to either return the session or an error, never both nor neither.

#### Swift

```swift
connection.oathSession { session, error in
    guard let session = session else { /* Handle error */ return }
    session.listCredentials { credentials, error in
        // Do something with the array of credentials
    }
}
```

#### Objective-C

```objective-c
[connection oathSession:^(YKFOATHSession * _Nullable session, NSError * _Nullable error) {
    if (session == nil) { /* Handle error */ return; }
    [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential *> * _Nullable credentials, NSError * _Nullable error) {
        // Do something with the array of credentials
    }];
}];
```

### Additional resources
Read more about OATH on the [Yubico developer site](https://developers.yubico.com/OATH/).


