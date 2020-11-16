// Copyright 2018-2019 Yubico AB
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

import UIKit

class OtherDemoRootViewController: UIViewController, YKFManagerDelegate {
    
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
    
    var accessoryConnection: YKFAccessoryConnection?
    
    var nfcConnection: YKFNFCConnection? {
        didSet {
            if let connection = nfcConnection, let callback = connectionCallback {
                callback(connection)
            }
        }
    }
    
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?

    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            self.connectionCallback = completion
            if #available(iOS 13.0, *) {
                YubiKitManager.shared.startNFCConnection()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.accessorySession.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        YubiKitManager.shared.stopAccessoryConnection()
        if #available(iOS 13.0, *) {
            YubiKitManager.shared.stopNFCConnection()
        }
        YubiKitManager.shared.delegate = nil
    }
}
