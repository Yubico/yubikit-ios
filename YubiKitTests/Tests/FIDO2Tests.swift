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
import Foundation

class FIDO2Tests: XCTestCase {
    
    func testResetOverNFC() {
        runYubiKitTest { connection, completion in
            if connection as? YKFNFCConnection != nil {
                connection.fido2Session { session, error in
                    guard let session = session else { XCTAssertTrue(false, "🔴 Failed to get FIDO2 session: \(error!)"); return }
                    session.reset { error in
                        guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset FIDO2 session: \(error!)"); return }
                        print("🟢 FIDO2 reset")
                        completion()
                    }
                }
            } else {
                print("🟢 Skipping FIDO2 reset over lightning")
                completion()
            }
        }
    }
    
    func testGetInformation() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.getInfoWithCompletion { response, error in
                    guard let response = response else { XCTAssertTrue(false, "🔴 Failed to get FIDO2 info: \(error!)"); return }
                    print("🟢 FIDO2 information:")
                    print("🟢 \(response.versions)")
                    print("🟢 \(response.extensions ?? [String]())")
                    print("🟢 \(response.aaguid)")
                    print("🟢 \(response.options ?? [AnyHashable: Any]())")
                    print("🟢 \(response.maxMsgSize)")
                    print("🟢 \(response.pinProtocols ?? [String]())")
                    completion()
                }
            }
        }
    }
    
    func testCreateECCNonRKCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response in
                    print("🟢 New FIDO2 credential: \(response)")
                    completion()
                }
            }
        }
    }
    
    func testCreateEdSANonRKCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: false]) { response in
                    print("🟢 Created new FIDO2 credential: \(response)")
                    completion()
                }
            }
        }
    }
    
    func testCreateECCNonRKCredentialAndAssert() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response in
                    print("🟢 Created new FIDO2 credential: \(response)")
                    session.assertCredential(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                        print("🟢 Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateEdDSANonRKCredentialAndAssert() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: false]) { response in
                    print("🟢 Created new FIDO2 credential: \(response)")
                    session.assertCredential(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                        print("🟢 Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateEdDSARKCredentialAndAssert() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: true]) { response in
                    print("🟢 Created new FIDO2 credential: \(response)")
                    session.assertCredential(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                        print("🟢 Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateEdDSARKCredentialAndAssertWithoutUP() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: true]) { response in
                    print("🟢 Created new FIDO2 credential: \(response)")
                    session.assertCredential(response: response, options: [YKFFIDO2OptionUP: false]) { response in
                        print("🟢 Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
}

extension YKFFIDO2Session {
    func addCredential(algorithm: Int, options: [String: Any]? = nil,  completion: @escaping (_ response: YKFFIDO2MakeCredentialResponse) -> Void) {
        let data = Data(repeating: 0, count: 32)
        let rp = YKFFIDO2PublicKeyCredentialRpEntity()
        rp.rpId = "yubikit-test.com"
        rp.rpName = "Yubico"
        let user = YKFFIDO2PublicKeyCredentialUserEntity()
        user.userId = data
        user.userName = "john.doe@yubikit-test.com"
        user.userDisplayName = "John Doe"
        let param = YKFFIDO2PublicKeyCredentialParam()
        param.alg = algorithm
        let pubKeyCredParams = [param]
        makeCredential(withClientDataHash: data, rp: rp, user: user, pubKeyCredParams: pubKeyCredParams, excludeList: nil, options: options) { response, error in
            guard let response = response else { XCTAssertTrue(false, "🔴 Failed making FIDO2 credential: \(error!)"); return }
            completion(response)
        }
    }
    
    func assertCredential(response: YKFFIDO2MakeCredentialResponse, options: [String: Any]? = nil,  completion: @escaping (_ response: YKFFIDO2GetAssertionResponse) -> Void) {
        let data = Data(repeating: 0, count: 32)
        let credentialDescriptor = YKFFIDO2PublicKeyCredentialDescriptor()
        credentialDescriptor.credentialId = response.authenticatorData!.credentialId!
        let credType = YKFFIDO2PublicKeyCredentialType()
        credType.name = "public-key"
        credentialDescriptor.credentialType = credType
        let allowList = [credentialDescriptor]
        getAssertionWithClientDataHash(data, rpId: "yubikit-test.com", allowList: allowList, options: options) { response, error in
            guard let response = response else { XCTAssertTrue(false, "🔴 Failed asserting FIDO2 credential: \(error!)"); return }
                completion(response)
        }
    }
}

extension YKFConnectionProtocol {
    func fido2TestSession(completion: @escaping (_ session: YKFFIDO2Session) -> Void) {
        self.fido2Session { session, error in
            guard let session = session else { XCTAssertTrue(false, "🔴 Failed to get FIDO2 session: \(error!)"); return }
            session.delegate = session
            completion(session)
        }
    }
}

var doneProcessing = true

extension YKFFIDO2Session: YKFFIDO2SessionKeyStateDelegate {
    public func keyStateChanged(_ keyState: YKFFIDO2SessionKeyState) {
        if keyState == .touchKey && doneProcessing {
            doneProcessing = false
            print("🔵 Touch key!")
        } else if keyState == .idle {
            doneProcessing = true
        }
    }
}
