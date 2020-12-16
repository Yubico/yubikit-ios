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

extension XCTestCase {
    func runYubiKitTest(completion: @escaping (_ connection: YKFConnectionProtocol, _ completion: @escaping () -> Void) -> Void) {
        let connectionExpectation = expectation(description: "Get a YubiKey Connection")
        let connection = YubiKeyConnection()
        connection.connection { connection in
            let testCompletion = {
                if connection as? YKFNFCConnection != nil {
                    YubiKitManager.shared.stopNFCConnection()
                    Thread.sleep(forTimeInterval: 4.0) // Approximate time it takes for the NFC modal to dismiss
                } else {
                    YubiKitManager.shared.stopAccessoryConnection()
                }
                connectionExpectation.fulfill();
            }
            completion(connection, testCompletion)
        }
        waitForExpectations(timeout: 20.0) { error in
            // If we get an error then the expectation has timed out and we need to stop all connections
            if error != nil {
                YubiKitManager.shared.stopAccessoryConnection()
                YubiKitManager.shared.stopNFCConnection()
                Thread.sleep(forTimeInterval: 5.0) // In case it was a NFC connection wait for the modal to dismiss
            }
        }
    }
}
