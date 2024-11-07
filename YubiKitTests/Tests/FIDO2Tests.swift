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
    
    // Resetting the FIDO2 over lightning requires the user to remove and then insert the key again. This would make the FIDO2 test
    // not that usable so we only test features that requires a reset on the NFC key.
    func testResetOverNFC() {
        runYubiKitTest { connection, completion in
            if connection as? YKFNFCConnection != nil {
                connection.fido2TestSession { session in
                    session.reset { error in
                        guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset FIDO2 session: \(error!)"); return }
                        print("✅ FIDO2 reset")
                        completion()
                    }
                }
            } else {
                print("✅ Skipping FIDO2 testResetOverNFC() over lightning")
                completion()
            }
        }
    }
    
    
    func testWrongPinOverNFC() {
        runYubiKitTest { connection, completion in
            if connection as? YKFNFCConnection != nil {
                connection.fido2TestSession { session in
                    session.setPin("123456") { _ in
                        session.verifyPin("234567") { error in
                            if let error = error {
                                XCTAssertTrue((error as NSError).code == 49, "🔴 Unexpected error: \(error)")
                            } else {
                                XCTFail("🔴 Failed to get an error although wrong pin was entered")
                            }
                            session.reset { error in
                                guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset FIDO2 session: \(error!)"); return }
                                print("✅ FIDO2 reset")
                                completion()
                            }
                        }
                    }
                }
            } else {
                print("✅ Skipping FIDO2 testWrongPinOverNFC() over lightning")
                completion()
            }
        }
    }
    
    func testCreateAndAssertWithPinOverNFC() {
        runYubiKitTest { connection, completion in
            if connection as? YKFNFCConnection != nil {
                connection.fido2TestSession { session in
                    session.setPin("123456") { _ in
                        session.verifyPin("123456") { error in
                            session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response, _ in
                                print("✅ Created new FIDO2 credential: \(response)")
                                session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                                    // https://www.w3.org/TR/webauthn/#authenticator-data
                                    XCTAssertTrue(response.authData.bytes[32] & 0b00000100 != 0, "🔴 Got auth data indicating we never verified pin")
                                    print("✅ Asserted FIDO2 credential: \(response.authData)")
                                    session.reset { error in
                                        guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset FIDO2 session: \(error!)"); return }
                                        print("✅ FIDO2 reset")
                                        completion()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                print("✅ Skipping FIDO2 testCreateAndAssertWithPinOverNFC() over lightning")
                completion()
            }
        }
    }
    
    func testAssertWithoutProvidingPinOverNFC() {
        runYubiKitTest { connection, completion in
            if connection as? YKFNFCConnection != nil {
                connection.fido2TestSession { session in
                    session.setPin("123456") { _ in
                        session.verifyPin("123456") { error in
                            session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response, _ in
                                session.clearUserVerification()
                                session.getAssertion(response: response, options: [YKFFIDO2OptionUP: true]) { response, error in
                                    if let response = response {
                                        // https://www.w3.org/TR/webauthn/#authenticator-data
                                        XCTAssertTrue(response.authData.bytes[32] & 0b00000100 == 0, "🔴 Got auth data indicating we verified pin when we never did.")
                                    } else {
                                        XCTFail("🔴 Got unexpected error: \(error!)")
                                    }
                                    session.reset { error in
                                        guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset FIDO2 session: \(error!)"); return }
                                        print("✅ FIDO2 reset")
                                        completion()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                print("✅ Skipping FIDO2 testAssertWithoutProvidingPinOverNFC() over lightning")
                completion()
            }
        }
    }
    
    func testAddWithoutProvidingPinOverNFC() {
        runYubiKitTest { connection, completion in
            if connection as? YKFNFCConnection != nil {
                connection.fido2TestSession { session in
                    session.setPin("123456") { _ in
                        session.addCredential(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response, _, error in
                            if let error = error {
                                XCTAssertTrue((error as NSError).code == 54, "🔴 Unexpected error: \(error)")
                            } else {
                                XCTFail("🔴 Failed to get an error although no pin was supplied")
                            }
                            session.reset { error in
                                guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset FIDO2 session: \(error!)"); return }
                                print("✅ FIDO2 reset")
                                completion()
                            }
                        }
                    }
                }
            } else {
                print("✅ Skipping FIDO2 testAddWithoutProvidingPinOverNFC() over lightning")
                completion()
            }
        }
    }
    
    func testGetInformation() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.getInfoWithCompletion { response, error in
                    guard let response = response else { XCTAssertTrue(false, "🔴 Failed to get FIDO2 info: \(error!)"); return }
                    print("🟢 \(response.versions)")
                    print("🟢 \(response.extensions ?? [String]())")
                    print("🟢 \(response.aaguid)")
                    print("🟢 \(response.options ?? [AnyHashable: Any]())")
                    print("🟢 \(response.maxMsgSize)")
                    print("🟢 \(response.pinProtocols ?? [String]())")
                    print("✅ Got FIDO2 information")
                    completion()
                }
            }
        }
    }
    
    func testCreateECCNonRKCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response, _ in
                    print("✅ New FIDO2 credential: \(response)")
                    completion()
                }
            }
        }
    }
    
    func testCreateEdSANonRKCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: false]) { response, _ in
                    print("✅ Created new FIDO2 credential: \(response)")
                    completion()
                }
            }
        }
    }
    
    func testCreateECCNonRKCredentialAndAssert() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false]) { response, _ in
                    print("✅ Created new FIDO2 credential: \(response)")
                    session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                        print("✅ Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateEdDSANonRKCredentialAndAssert() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: false]) { response, _ in
                    print("✅ Created new FIDO2 credential: \(response)")
                    session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                        print("✅ Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateEdDSARKCredentialAndAssert() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: true]) { response, _ in
                    print("✅ Created new FIDO2 credential: \(response)")
                    session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                        print("✅ Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateEdDSARKCredentialAndAssertWithoutUP() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: true]) { response, _ in
                    print("✅ Created new FIDO2 credential: \(response)")
                    session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: false]) { response in
                        print("✅ Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreateSignExtensionCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                let createExtensions = ["sign" : ["generateKey": ["algorithms": [-65539]]]]
                session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: false, YKFFIDO2OptionUV: false], extensions: createExtensions) { response, extensionResponse in
                    print(response.authenticatorData)
                    print("✅ Created new FIDO2 credential: \(response), \(extensionResponse)")
                    
                    let credentialId = (response.authenticatorData!.credentialId! as NSData).ykf_websafeBase64EncodedString()
                    let sign = (extensionResponse!["sign"] as! [String: Any])
                    let generatedKey = sign["generatedKey"] as! [String: Any]
                    let keyHandle = generatedKey["keyHandle"] as! String
                    let assertExtensions = ["sign" : ["sign" : ["phData" : "Mp80eo3FdxJ2hLtD7HHQO5hhzjyDD57Kdvuqi_weTGE", "keyHandleByCredential" : [credentialId: keyHandle]]]]
                    session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true, YKFFIDO2OptionUV: false], extensions: assertExtensions) { response in
                        print("✅ Asserted FIDO2 credential: \(response)")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCreatePRFSecretExtensionCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.verifyPin("123456") { error in
                    if let error { XCTFail("verifyPin failed with: \(error)"); return }
                    let createExtensions = ["prf" : []]
                    session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmES256, options: [YKFFIDO2OptionRK: true], extensions: createExtensions) { response, _ in
                        print(response.authenticatorData)
                        print("✅ Created new FIDO2 credential: \(response)")
                        
                        let assertExtensions = ["prf" : ["eval" : ["first" : "abba", "second" : "bebe"]]]
                        session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true], extensions: assertExtensions) { response in
                            print("✅ Asserted FIDO2 credential: \(response)")
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func testCreateLargeBlobExtensionCredential() {
        runYubiKitTest { connection, completion in
            connection.fido2TestSession { session in
                session.verifyPin("123456") { error in
                    if let error { XCTFail("verifyPin failed with: \(error)"); return }
                    //                    let extensions = ["largeBlobKey" : ["support": "required"]]
                    //                    session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: true], extensions: extensions) { response in
                    session.addCredentialAndAssert(algorithm: YKFFIDO2PublicKeyAlgorithmEdDSA, options: [YKFFIDO2OptionRK: true]) { response, _ in
                        print("✅ Created new FIDO2 credential: \(response)")
                        session.getAssertionAndAssert(response: response, options: [YKFFIDO2OptionUP: true]) { response in
                            print("✅ Asserted FIDO2 credential: \(response)")
                            completion()
                        }
                    }
                }
            }
        }
    }
}

extension YKFFIDO2Session {
    func addCredentialAndAssert(algorithm: Int, options: [String: Any]? = nil, extensions: [String: Any]? = nil, completion: @escaping (_ response: YKFFIDO2MakeCredentialResponse, _ clientExtensionResults: [AnyHashable: Any]?) -> Void) {
        addCredential(algorithm: algorithm, options: options, extensions: extensions) { response, clientExtensionResults, error in
            if let clientExtensionResults {
                let jsonData = try! JSONSerialization.data(withJSONObject: clientExtensionResults)
                let jsonString = String(data: jsonData, encoding: .utf8)
                print(jsonString as Any)
            }
            guard let response = response else { XCTAssertTrue(false, "🔴 Failed making FIDO2 credential: \(error!)"); return }
            completion(response, clientExtensionResults)
        }
    }
    
    
    func addCredential(algorithm: Int, options: [String: Any]? = nil, extensions: [String: Any]? = nil, completion: @escaping YKFFIDO2SessionMakeCredentialCompletionBlock) {
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
        makeCredential(withClientDataHash: data, rp: rp, user: user, pubKeyCredParams: pubKeyCredParams, excludeList: nil, options: options, extensions: extensions, completion: completion)
    }
    
    func getAssertionAndAssert(response: YKFFIDO2MakeCredentialResponse, options: [String: Any]? = nil, extensions: [String: Any]? = nil,  completion: @escaping (_ response: YKFFIDO2GetAssertionResponse) -> Void) {
        getAssertion(response: response, options: options, extensions: extensions) { response, error in
            guard let response = response else { XCTAssertTrue(false, "🔴 Failed asserting FIDO2 credential: \(error!)"); return }
            completion(response)
        }
    }
    
    func getAssertion(response: YKFFIDO2MakeCredentialResponse, options: [String: Any]? = nil, extensions: [String: Any]? = nil, completion: @escaping YKFFIDO2SessionGetAssertionCompletionBlock) {
        let data = Data(repeating: 0, count: 32)
        let credentialDescriptor = YKFFIDO2PublicKeyCredentialDescriptor()
        credentialDescriptor.credentialId = response.authenticatorData!.credentialId!
        let credType = YKFFIDO2PublicKeyCredentialType()
        credType.name = "public-key"
        credentialDescriptor.credentialType = credType
        let allowList = [credentialDescriptor]
        getAssertionWithClientDataHash(data, rpId: "yubikit-test.com", allowList: allowList, options: options, extensions: extensions, completion: completion)
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
