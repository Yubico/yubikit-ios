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
        YubiKitManager.shared.startSmartCardConnection()
        let connectionExpectation = expectation(description: "Get a YubiKey Connection")
        let firstConnection = YubiKeyConnectionTester()
        Thread.sleep(forTimeInterval: 0.5)
        firstConnection.connection { first, error in
            print("✅ got first connection")
            let secondConnection = YubiKeyConnectionTester()
            secondConnection.connection { second, error in
                print("✅ got second connection")
                connectionExpectation.fulfill();
            }
        }
        waitForExpectations(timeout: 10.0) { error in
            // If we get an error then the expectation has timed out and we need to stop all connections
            if error != nil {
                YubiKitManager.shared.stopAccessoryConnection()
                YubiKitManager.shared.stopSmartCardConnection()
                YubiKitManager.shared.stopNFCConnection()
                Thread.sleep(forTimeInterval: 5.0) // In case it was a NFC connection wait for the modal to dismiss
            }
        }
    }
    
    func testNFCTimeOutError() throws {
        let connectionExpectation = expectation(description: "Get a YubiKey Connection")
        let connectionTester = YubiKeyConnectionTester()
        YubiKitManager.shared.startAccessoryConnection() // We need to start the accessory connection so we can skip this test if a 5Ci key is inserted
        YubiKitManager.shared.startSmartCardConnection()

        Thread.sleep(forTimeInterval: 0.5)
        print("👉 Wait for NFC modal to dismiss (this will take a long time)!")
        
        connectionTester.nfcConnectionErrorCallback = { error in
            XCTAssert((error as NSError).code == 201)
            print("✅ got expected NFC timeout error (201)")
            connectionExpectation.fulfill();
        }
        
        connectionTester.connection { connection, error in
            print("YubiKey 5Ci connected. Skip test.")
            connectionExpectation.fulfill()
            return
        }
        
        waitForExpectations(timeout: 120.0) { error in
            // If we get an error then the expectation has timed out and we need to stop all connections
            if error != nil {
                YubiKitManager.shared.stopNFCConnection()
                Thread.sleep(forTimeInterval: 5.0) // In case it was a NFC connection wait for the modal to dismiss
            }
        }
    }
    
    func testNFCUserCancelError() throws {
        let connectionExpectation = expectation(description: "Got a YubiKey failed to connect to NFC error")
        let connectionTester = YubiKeyConnectionTester()
        YubiKitManager.shared.startAccessoryConnection() // We need to start the accessory connection so we can skip this test if a 5Ci key is inserted
        YubiKitManager.shared.startSmartCardConnection()
        Thread.sleep(forTimeInterval: 0.5)
        
        connectionTester.nfcConnectionErrorCallback = { error in
            XCTAssert((error as NSError).code == 200)
            print("✅ got expected user canceled NFC error (200)")
            connectionExpectation.fulfill();
        }
        
        print("👉  Press cancel in NFC modal!")
        connectionTester.connection { connection, error in
            print("YubiKey connected. Skip test.")
            connectionExpectation.fulfill()
            return
        }
        
        waitForExpectations(timeout: 20.0) { error in
            // If we get an error then the expectation has timed out and we need to stop all connections
            if error != nil {
                YubiKitManager.shared.stopNFCConnection()
                Thread.sleep(forTimeInterval: 5.0) // In case it was a NFC connection wait for the modal to dismiss
            }
        }
    }
}

class YubiKeyConnectionTester: NSObject {
    
    var accessoryConnection: YKFAccessoryConnection?
    var smartCardConnection: YKFSmartCardConnection?
    var nfcConnection: YKFNFCConnection?
    var connectionCallback: ((_ connection: YKFConnectionProtocol, _ error: Error?) -> Void)?
    var errorCallback: ((_ error: Error) -> Void)?
    var nfcConnectionErrorCallback: ((_ error: Error) -> Void)?

    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
    }
    
    func connection(completion: @escaping (_ connection: YKFConnectionProtocol, _ error: Error?) -> Void) {
        if let connection = accessoryConnection {
            completion(connection, nil)
        } else if let connection = smartCardConnection {
            completion(connection, nil)
        } else if let connection = nfcConnection {
            completion(connection, nil)
        } else {
            connectionCallback = completion
            if NFCNDEFReaderSession.readingAvailable {
                YubiKitManager.shared.startNFCConnection()
            }
        }
    }
}

extension YubiKeyConnectionTester: YKFManagerDelegate {
    func didFailConnectingNFC(_ error: Error) {
        if let callback = nfcConnectionErrorCallback {
            callback(error)
        }
    }
    
    func didReceiveConnectionError(_ error: Error) {
        if let callback = errorCallback {
            callback(error)
        }
    }
    
    func didConnectNFC(_ connection: YKFNFCConnection) {
        nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection, nil)
        }
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        if let callback = connectionCallback {
            callback(connection, error)
        }
        nfcConnection = nil
    }
    
    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
        if let callback = connectionCallback {
            callback(connection, nil)
        }
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        if let callback = connectionCallback {
            callback(connection, error)
        }
        accessoryConnection = nil
    }
    
    func didConnectSmartCard(_ connection: YKFSmartCardConnection) {
        smartCardConnection = connection
        if let callback = connectionCallback {
            callback(connection, nil)
        }
    }
    
    func didDisconnectSmartCard(_ connection: YKFSmartCardConnection, error: Error?) {
        if let callback = connectionCallback {
            callback(connection, error)
        }
        smartCardConnection = nil
    }
}
