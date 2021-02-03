
## Management Session

The `YKFManagementSession` provides access to the management application on a YubiKey. This allows the iOS application to enable or disable applications and transports on the YubiKey.

### Communicating with the management application on the YubiKey

Communication with the management application is done through the `YKFManagementSession` and the methods it expose. You obtain the session by calling `(void)managementSession:(ManagementSession _Nonnull)callback;` on the `YKFConnection`. The method is guaranteed to either return the session or an error, never both nor neither.

#### Swift

```swift
connection.managementSession { session, error in
    guard let session = session else { /* handle error */ return }
    session.readConfiguration { response, error in
        // Handle the response
    }
}
```

#### Objective-C

```objective-c
[connection managementSession:^(YKFManagementSession * _Nullable session, NSError * _Nullable error) {
    if (session == nil) { /* Handle error */ return; }
    [session readConfigurationWithCompletion:^(YKFManagementReadConfigurationResponse * _Nullable response, NSError * _Nullable error) {
       // Handle the response
    }];
}];
```
