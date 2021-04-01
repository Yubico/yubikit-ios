## PIV Session

The `YKFPIVSession` provides access to the PIV application on a YubiKey. This allows the iOS application to enable or disable applications and transports on the YubiKey.

### Communicating with the PIV application on the YubiKey

Communication with the PIV application is done through the `YKFPIVSession` and the methods it exposes. You obtain the session by calling `(void)pivSession:(YKFPIVSessionCallback _Nonnull)callback;` on a `YKFConnectionProcotol`. The method is guaranteed to either return the session or an error, never both or neither.

#### Swift

```swift
connection.pivSession { session, error in
    guard let session = session else { /* handle error */ return }
    session.generateKey(in: .signature, type: .ECCP256) { publicKey, error in
        // Handle the response
    }
}
```

#### Objective-C

```objective-c
[connection pivSession:^(YKFPIVSession * session, NSError * error) {
    if (session == nil) { /* Handle error */ return; }
    [session generateKeyInSlot:YKFPIVSlotSignature type:YKFPIVKeyTypeECCP256 completion:^(NSData * publicKey, NSError * error) {
        // Handle the response
    }];
}];
```

Additional sample code for the `YKFPIVSession` can be found in the [full stack tests](../YubiKitTests/Tests/PIVTests.swift).
