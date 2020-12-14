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

import SwiftUI

class CredentialsProvider: NSObject, ObservableObject, YKFManagerDelegate {
    
    @Published var credentials = [Credential]()

    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.startAccessoryConnection()
    }
    
    var nfcConnection: YKFNFCConnection?

    func didConnectNFC(_ connection: YKFNFCConnection) {
        nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection)
        }
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
        session = nil
    }
    
    var accessoryConnection: YKFAccessoryConnection?

    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
        refresh()
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        accessoryConnection = nil
        session = nil
        credentials.removeAll()
    }
    
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    
    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }
    
    var session: YKFKeyOATHSession?

    func session(completion: @escaping (_ session: YKFKeyOATHSession?, _ error: Error?) -> Void) {
        if let session = session {
            completion(session, nil)
            return
        }
        connection { connection in
            connection.oathSession { session, error in
                self.session = session
                completion(session, error)
            }
        }
    }
    
    func refresh() {
        session { session, error in
            guard let session = session else { print("Error: \(error!)"); return }
            session.calculateAll { calculatedCredentials, error in
                YubiKitManager.shared.stopNFCConnection()
                guard let calculatedCredentials = calculatedCredentials else { print("Error: \(error!)"); return }
                DispatchQueue.main.async {
                    self.credentials = calculatedCredentials.map { Credential(issuer: $0.credential.issuer, accountName: $0.credential.accountName, otp: $0.code?.otp) }
                }
            }
        }
    }
    
    func add(credential: Credential) {
        session { session, error in
            guard let session = session else { print("Error: \(error!)"); return }
            let secret = NSData.ykf_data(withBase32String: "asecretsecret")!
            let credentialTemplate = YKFOATHCredentialTemplate(totpWith: .SHA512, secret: secret, issuer: credential.issuer, accountName: credential.accountName)
            session.put(credentialTemplate, requiresTouch: false) { error in
                guard error == nil else { print("Error: \(error!)"); return }
                self.refresh()
            }
        }
    }
    
    func delete(credential: Credential) {
        session { session, error in
            guard let session = session else { print("Error: \(error!)"); return }
            let oathCredential = YKFOATHCredential()
            oathCredential.accountName = credential.accountName
            oathCredential.issuer = credential.issuer
            session.delete(oathCredential) { error in
                YubiKitManager.shared.stopNFCConnection()
                guard error == nil else { print("Error: \(error!)"); return }
                if let index = self.credentials.firstIndex(of: credential) {
                    DispatchQueue.main.async {
                        self.credentials.remove(at: index)
                    }
                }
            }
        }
    }
}


extension CredentialsProvider {
    static func previewCredentialsProvider() -> CredentialsProvider {
        let provider = CredentialsProvider()
        provider.credentials = Credential.previewCredentials()
        return provider
    }
}
