

## U2F Session

The `YKFU2FSession` provides access to the U2F application on a YubiKey.

### Communicating with the U2F application on the YubiKey

Communication with the U2F application is done through the `YKFU2FSession` and the methods it expose. You obtain the session by calling `- (void)u2fSession:(YKFU2FSessionCallback _Nonnull)callback` on a `YKFConnectionProtocol`. The method is guaranteed to either return the session or an error, never both nor neither.

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
Read more about U2F on the [Yubico developer site](https://developers.yubico.com/U2F/).
