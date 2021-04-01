
# YubiKit Connection Wrapper

This wrapper will simplify the use of the YubiKit SDK by giving the user an easy interface for retrieving either a
`YKFAccessoryConnection` or `YKFNFCConnection`. As the `YubiKeyConnection` is instantiated it will start the
accessory connection waiting for a YubiKey 5Ci to be inserted into the device. If `connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void)`
is called while a YubiKey 5Ci is connected to the device that connection will be returned by the callback block. If no accessory key
in present the `YubiKeyConnection` will start scanning for a NFC YubiKey. When a NFC connection is established that will be
returned by the callback.

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
