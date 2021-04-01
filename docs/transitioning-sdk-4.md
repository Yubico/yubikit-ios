# Transitioning to version 4 of the YubiKit SDK

## **Background**

Version 4 of the SDK is a breaking release where a lot of the APIs of the SDK has been changed. There are two reasons behind these changes. First the old APIs where in need of an overhaul to simplify integration and remove unnecessary complexity. Secondly we wanted the different SDKs for Android and iOS to align better when it came to naming conventions and concepts. We do want to stress however that the iOS SDK is still foremost an iOS SDK.

## **Major changes**

The most visible change is the naming of the different layers of connections between the SDK and the YubiKey. Previously the raw connection between the YubiKey and the SDK was called `YKFAccessorySession` and `YKFNFCSession`. On top of this we had several `Services`, e.g `YKFKeyFIDO2Service` and `YKFKeyOATHService`. To follow the more widely accepted definition of connection and session we decided to rename the sessions to `YKFAccessoryConnection` and `YKFNFCConnection`. The `Services` are now `Sessions` since they hold a state of information exchange i.e which application is selected on the YubiKey and if applicable current authentication state.

Besides the naming changes there are three parts of the SDK that has seen major changes for the version 4 release.

The first is that we've moved away from the Key Value Observation pattern for monitoring changes to the YubiKey connection in favour of a simple delegate protocol. This should be more familiar to most iOS developers and more in line with Apples more modern APIs.

The second is that instead of the different sessions being properties on the connection, sessions are now obtained via a block based method. Previously a session didn't have any initial state and the corresponding application on the YubiKey was selected when the first command was sent to the YubiKey. Sessions returned by the new SDK already has the correct application selected, hence the need for an asynchronous call. The previous SDK also handled switching between different session types automagically. This worked most of the time but not always and added lots of complexity and could fool the integrator into believing there where several application selected simultaneously on the YubiKey. Instead of trying to fake several active Sessions to the YubiKey the new SDK will simply invalidate any old session as soon as a new type of session is requested.

The last major change is the removal of most of the Request and Response classes. These were used to wrap the properties needed for a specific command. Instead the method on the Session takes the properties as arguments and simply returns the result.

## **Adopting the new SDK in your app**

The naming changes is simply just renaming the class types to the new naming convention. The removed layer of request and response classes is also straight forward, just removing the now redundant layer of code. Parameter naming has been kept in most cases so it’s an easy task.

The part that could pose some difficulty is the move from KVO to a delegate pattern for monitoring the state changes of the YubiKey connection. You can ease the use of the connection delegate by a simple wrapper exposing a callback that will give you an accessory connection if a YubiKey 5ci is connected via the Lightning port, or if no YubiKey is connected start the NFC Scanning for a NFC YubiKey. The code will look like this:

```swift
class YubiKeyConnection: NSObject {
    
    var accessoryConnection: YKFAccessoryConnection?
    var nfcConnection: YKFNFCConnection?
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    
    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.startAccessoryConnection()
    }
    
    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }
}

extension YubiKeyConnection: YKFManagerDelegate {
    func didConnectNFC(_ connection: YKFNFCConnection) {
       nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection)
        }
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
    }
    
    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        accessoryConnection = nil
    }
}
```

And using this wrapper is very simple:

```swift
let yubiKeyConnection = YubiKeyConnection()
yubiKeyConnection.connection { connection in
    connection.managementSession { session, error in
    guard let session = session else { /* handle error */; return }
    session.readConfiguration { configuration, error in
        …
    }
}
```

A stop-gap solution if your code depends heavily on KVO is to wrap the new delegate protocol in a class exposing similar KVO paths as the old SDK did. This can be achieved with the following code:

```swift
class YubiKitKVOWrapper: NSObject, YKFManagerDelegate {
    
    @objc dynamic var accessoryConnection: YKFAccessoryConnection?
    @objc dynamic var nfcConnection: YKFNFCConnection?

    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.startAccessoryConnection()
    }
    
    func didConnectNFC(_ connection: YKFNFCConnection) {
        nfcConnection = connection
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
    }
    
    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        accessoryConnection = nil
    }
}
```
