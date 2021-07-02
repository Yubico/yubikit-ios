// Copyright 2018-2020 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest

class ConnectionTests: XCTestCase {

    func testConnectionDelegate() throws {
        YubiKitManager.shared.startAccessoryConnection()
        let connectionExpectation = expectation(description: "Get a YubiKey Connection")
        let firstConnection = YubiKeyConnectionTester()
        Thread.sleep(forTimeInterval: 0.5)
        firstConnection.connection { first in
            print("✅ got first connection")
            let secondConnection = YubiKeyConnectionTester()
            secondConnection.connection { second in
                print("✅ got second connection")
                connectionExpectation.fulfill();
            }
        }
        waitForExpectations(timeout: 10.0) { error in
            // If we get an error then the expectation has timed out and we need to stop all connections
            if error != nil {
                YubiKitManager.shared.stopAccessoryConnection()
                YubiKitManager.shared.stopNFCConnection()
                Thread.sleep(forTimeInterval: 5.0) // In case it was a NFC connection wait for the modal to dismiss
            }
        }
    }
}


class YubiKeyConnectionTester: NSObject {
    
    var accessoryConnection: YKFAccessoryConnection?
    var nfcConnection: YKFNFCConnection?
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    
    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
    }
    
    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else if let connection = nfcConnection {
            completion(connection)
        } else {
            connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }
}

extension YubiKeyConnectionTester: YKFManagerDelegate {
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
