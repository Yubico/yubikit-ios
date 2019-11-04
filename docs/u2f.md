
## U2F operations with the YubiKey 5Ci

The *Universal Second Factor* or U2F protocol is a simple yet powerful way of providing strong authentication for users. The goal of this documentation is not to provide a full explanation of U2F but to explain how to use U2F with YubiKit and the YubiKey 5Ci. For a more detailed explanation of U2F you are encouraged to access the resources from Yubico [developer website](https://developers.yubico.com). For a general overview of U2F consult this [introduction article](https://developers.yubico.com/U2F/) from Yubico developers website.

U2F provides two major operations: **registration** and **authentication** (which is often referred as *signing*). To provide strong security these operations need to be performed in an isolated and secure environment, such as the YubiKey. The YubiKey has a secure element inside, a special hardware module that guarantees that no secrets can be extracted from the device. YubiKit provides the ability to communicate with the YubiKey 5Ci which can perform these operations. 

The U2F operations can be logically separated in 3 steps:

1. The application is requesting from the authentication server some information which is required by the YubiKey to perform the operation. 
2. The application is sending that information to the YubiKey and waits for a result.
3. The application sends the result to the authentication server to be validated.

Steps 1 and 3 are custom to each application. This usually involves some HTTPS calls to the server infrastructure used by the application to get and send data back. The second step is where the application is using YubiKit and the YubiKey.

***Hint: Use the demo application and search for relevant code while reading this guide and consult also the code level documentation for a more detailed explanation.***

YubiKit is exposing a simple and easy to use API for U2F operations which hides the complexity of managing the logic of interacting with an external accessory on iOS and communicating U2F specific binary data to the key. The U2F operations are accessible via the `YKFKeyU2FService`, a shared single instance which becomes available in `YubiKitManager.accessorySession` when the session with the key is started. 

To enable the `YKFAccessorySession` to receive events and connect to the YubiKey 5Ci, it needs to be explicitly started. This allows the host application to have a granular control on when the application should listen and connect to the key. When the application no longer requires the presence of the key (e.g. the user successfully authenticated and moved to the main UI of the app), the session can be stopped by calling `stopSession`.

---

**Notes:**

1. In the YubiKit Demo application the session is started at launch and remains active throughout the lifetime of the application to demo the U2F functionality. Usually the session should be started when an authentication UI is displayed and stopped when it goes away. In this way YubiKit does not retain unnecessary resources.

2. Before starting the key session, the application should verify if the iOS version is supported by the library by looking at the `supportsMFIAccessoryKey` property on `YubiKitDeviceCapabilities`

---

An important property of the `YKFAccessorySession` is the `sessionState` which can be used to check the state of the session. This property can be observed using KVO. Observe this property to see when the key is connected or disconnected and take appropriate actions to update the UI and to send requests to the key. Because the KVO code can be verbose, a complete example on how to observe this property is provided in the Demo application and not here. When the host application prefers a delegate pattern to observe this property, the YubiKit Demo application provides an example on how to isolate the KVO observation into a separate class and use a delegate to update about changes. The example can be found in the `Examples/Observers` project group.

The session was designed to provide a list of *services*. A service usually maps a major capability of the key, in this case U2F. Over the same session the application can talk to different functionalities provided by the key. The `YKFKeyU2FService` will communicate with the U2F functionality from the key. The U2F service lifecycle is fully controlled by the key session and it must not be created by the host application. The lifecycle of the U2F service is dependent on the session state. When the session is opened and it can communicate with the key, the U2F service become available. If the session is closed the U2F service is `nil`.

After the key session was started and a key was connected the session state becomes *open* so the application can start sending requests to the key.

To send an U2F registration request to the key call `executeRegisterRequest:completion:` on the U2F service. This method takes as a parameter the request object of type `YKFKeyU2FRegisterRequest` which packs a list of all required parameters by the key to perform the registration. `YKFKeyU2FRegisterRequest` contains all the required code level documentation and external links to understand its properties. The `completion` parameter is a block/closure which will be called asynchronously when the operation with the key has ended. The operation with the key is executed on a background execution queue and the `completion` block will be called from that queue. Consider this when planning to update things which require to be executed on the main thread, like the UI updates.

##### Swift
	
```swift
// The challenge and appId are received from the authentication server.
let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId)
	
YubiKitManager.shared.accessorySession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    // The response should not be nil at this point. Send back the response to the authentication server.
}
```

##### Objective-C

```objective-c
// The challenge and appId are received from the authentication server.
YKFKeyU2FRegisterRequest *registerRequest = [[YKFKeyU2FRegisterRequest alloc] initWithChallenge:challenge appId:appId];
    
[YubiKitManager.shared.u2fService executeRegisterRequest:registerRequest completion:^(YKFKeyU2FRegisterResponse *response, NSError *error) {
    if (error) {
        // Handle the error
        return;
    }
    // The response should not be nil at this point. Send back the response to the authentication server.
}];
```

To send an U2F sign request to the key call `executeSignRequest:completion:` on the U2F service. This method takes as a parameter the request object of type `YKFKeyU2FSignRequest` which packs a list of all required parameters by the key to perform the signing. `YKFKeyU2FSignRequest` contains all the required code level documentation and external links to understand its properties. The `completion` parameter is a block/closure which will be called asynchronously when the operation with the key has ended. The operation with the key is executed on a background execution queue and the `completion` block will be called from that queue. Consider this when planning to update things which require to be executed on the main thread, like the UI updates.

##### Swift

```swift
// The challenge, keyHandle and appId are received from the authentication server.
let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId)
	
YubiKitManager.shared.accessorySession.u2fService!.execute(signRequest) { [weak self] (response, error) in
    guard error == nil else {
        // Handle the error here.
        return
    }
    // Response should not be nil at this point. Send back the response to the authentication server.
}
```

##### Objective-C

```objective-c
// The challenge, keyHandle and appId are received from the authentication server.
YKFKeyU2FSignRequest *signRequest = [[YKFKeyU2FSignRequest alloc] initWithChallenge:challenge keyHandle:keyHandle appId:appId];
    
[YubiKitManager.shared.u2fService executeSignRequest:signRequest completion:^(YKFKeyU2FSignResponse *response, NSError *error) {
    if (error) {
        // Handle the error
        return;
    } 
    // The response should not be nil at this point. Send back the response to the authentication server.
}];
```