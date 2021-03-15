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

class PIVTests: XCTestCase {
    func testGenerateRSAKey() throws {
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                session.verifyPin("123456") { retries, error in
                    session.generateKey(in: .signature, type: .RSA1024) { publicKey, error in
                        XCTAssert(error == nil, "🔴 \(error!)")
                        XCTAssertNotNil(publicKey);
                        let attributes = SecKeyCopyAttributes(publicKey!) as! [String: Any]
                        XCTAssert(attributes[kSecAttrKeySizeInBits as String] as! Int == 1024)
                        XCTAssert(attributes[kSecAttrKeyType as String] as! String == kSecAttrKeyTypeRSA as String)
                        XCTAssert(attributes[kSecAttrKeyClass as String] as! String == kSecAttrKeyClassPublic as String)
                        print("✅ Generated 1024 RSA key")
                        completion()
                    }
                }
            }
        }
    }
    
    func testGenerateECCKey() throws {
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                session.verifyPin("123456") { retries, error in
                    session.generateKey(in: .signature, type: .ECCP256) { publicKey, error in
                        XCTAssert(error == nil, "🔴 \(error!)")
                        XCTAssertNotNil(publicKey);
                        let attributes = SecKeyCopyAttributes(publicKey!) as! [String: Any]
                        XCTAssert(attributes[kSecAttrKeySizeInBits as String] as! Int == 256)
                        XCTAssert(attributes[kSecAttrKeyType as String] as! String == kSecAttrKeyTypeEC as String)
                        XCTAssert(attributes[kSecAttrKeyClass as String] as! String == kSecAttrKeyClassPublic as String)
                        print("✅ Generated 256 ECC key")
                        completion()
                    }
                }
            }
        }
    }
    
    let exportedCert = "MIIBKzCB0qADAgECAhQTuU25u6oazORvKfTleabdQaDUGzAKBggqhkjOPQQDAjAWMRQwEgYDVQQDDAthbW9zLmJ1cnRvbjAeFw0yMTAzMTUxMzU5MjVaFw0yODA1MTcwMDAwMDBaMBYxFDASBgNVBAMMC2Ftb3MuYnVydG9uMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEofwN6S+atSZmzeLK7aSI+mJJwxh0oUBiCOngHLeToYeanrTGvCZQ2AK/R9esnqSxMyBUDp91UO4F6U4c6RTooTAKBggqhkjOPQQDAgNIADBFAiAnj/KUSpW7l5wnenQEbwWudK/7q3WtyrqdB0H1xc258wIhALDLImzu3S+0TT2/ggM95LLWE4Llfa2RQM71bnW6zqqn"

    func testPutAndReadCertificate() throws {
        let certData = Data(base64Encoded: exportedCert)! as CFData;
        let certificate = SecCertificateCreateWithData(nil, certData)!
        
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                session.put(certificate, in: .authentication) { error in
                    XCTAssertNil(error)
                    print("✅ Put certificate")
                    session.readCertificate(from: .authentication) { cert, error in
                        XCTAssertNil(error)
                        print("✅ Read certificate")
                        completion()
                    }
                }
            }
        }
    }
    
    func testPutAndDeleteCertificate() throws {
        let certData = Data(base64Encoded: exportedCert)! as CFData;
        let certificate = SecCertificateCreateWithData(nil, certData)!
        
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                session.put(certificate, in: .authentication) { error in
                    XCTAssertNil(error)
                    print("✅ Put certificate")
                    session.deleteCertificate(in: .authentication) { error in
                        XCTAssertNil(error)
                        print("✅ Delete certificate")
                        completion()
                    }
                }
            }
        }
    }
    
    func testAuthenticateWithDefaultManagementKey() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                let managementKey = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
                session.authenticate(withManagementKey: managementKey, keyType: .tripleDES()) { error in
                    XCTAssert(error == nil, "🔴 \(error!)")
                    print("✅ authenticated")
                    completion()
                }

            }
        }
    }
    
    func testSet3DESManagementKey() throws {
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                let newManagementKey = Data([0x3e, 0xc9, 0x50, 0xf1, 0xc1, 0x26, 0xb3, 0x14, 0xa8, 0x0e, 0xdd, 0x75, 0x26, 0x94, 0xc3, 0x28, 0x65, 0x6d, 0xb9, 0x6f, 0x1c, 0x65, 0xcc, 0x4f])
                session.setManagementKey(newManagementKey, type: .tripleDES(), requiresTouch: false) { error in
                    XCTAssert(error == nil, "🔴 \(error!)")
                    print("✅ management key (3DES) changed")
                    session.authenticate(withManagementKey: newManagementKey, keyType: .tripleDES()) { error in
                        XCTAssert(error == nil, "🔴 \(error!)")
                        print("✅ authenticated with new management key")
                        completion()
                    }
                }
            }
        }
    }
    
    func testSetAESManagementKey() throws {
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                if !session.features.aesKey.isSupported(bySession: session) {
                    print("Skipping AES management key test since it's not supported by this YubiKey.")
                    completion()
                    return
                }
                let aesManagementKey = Data([0xf7, 0xef, 0x78, 0x7b, 0x46, 0xaa, 0x50, 0xde, 0x06, 0x6b, 0xda, 0xde, 0x00, 0xae, 0xe1, 0x7f, 0xc2, 0xb7, 0x10, 0x37, 0x2b, 0x72, 0x2d, 0xe5])
                session.setManagementKey(aesManagementKey, type: .aes192(), requiresTouch: false) { error in
                    XCTAssert(error == nil, "🔴 \(error!)")
                    print("✅ management key (AES) changed")
                    session.authenticate(withManagementKey: aesManagementKey, keyType: .aes192()) { error in
                        XCTAssert(error == nil, "🔴 \(error!)")
                        print("✅ authenticated with new management key")
                        completion()
                    }
                }
            }
        }
    }
    
    func testAuthenticateWithWrongManagementKey() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                let managementKey = Data([0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01])
                session.authenticate(withManagementKey: managementKey, keyType: .tripleDES()) { error in
                    guard let error = error as NSError? else { XCTFail("🔴 Expected an error but got none"); completion(); return }
                    XCTAssert(error.code == 0x6982)
                    print("✅ got expected error: \(error)")
                    completion()
                }
            }
        }
    }
    
    func testVerifyPIN() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.verifyPin("123456") { retries, error in
                    XCTAssertNil(error)
                    print("✅ PIN verified \(retries) left")
                    completion()
                }
            }
        }
    }
    
    func testVerifyPINRetryCount() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.verifyPin("333333") { retries, error in
                    XCTAssertNotNil(error)
                    XCTAssert(retries == 2)
                    print("✅ PIN retry count \(retries)")
                    session.verifyPin("111111") { retries, error in
                        XCTAssertNotNil(error)
                        XCTAssert(retries == 1)
                        print("✅ PIN retry count \(retries)")
                        session.verifyPin("444444") { retries, error in
                            XCTAssertNotNil(error)
                            XCTAssert(retries == 0)
                            print("✅ PIN retry count \(retries)")
                            session.verifyPin("111111") { retries, error in
                                XCTAssertNotNil(error)
                                XCTAssert(retries == 0)
                                print("✅ PIN retry count \(retries)")
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testGetPinAttempts() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.getPinAttempts { retries, error in
                    XCTAssertNil(error)
                    XCTAssert(retries == 3)
                    print("✅ PIN attempts \(retries)")
                    session.verifyPin("666666") { retries, error in
                        session.getPinAttempts { retries, error in
                            XCTAssertNil(error)
                            XCTAssert(retries == 2)
                            print("✅ PIN attempts \(retries)")
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func testSetPinPukAttempts() throws {
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                session.verifyPin("123456") { _, error in
                    session.setPinAttempts(5, pukAttempts: 6) { error in
                        XCTAssertNil(error)
                        if session.features.metadata.isSupported(bySession: session) {
                            session.getPinMetadata { _, retries, _, error in
                                XCTAssert(retries == 5)
                                print("✅ Set PIN retry count \(retries)")
                                session.getPukMetadata { _, retries, _, error in
                                    XCTAssert(retries == 6)
                                    print("✅ Set PUK retry count \(retries)")
                                    completion()
                                }
                            }
                        } else {
                            session.getPinAttempts { retries, error in
                                XCTAssertNil(error)
                                XCTAssert(retries == 5)
                                print("✅ Set PIN retry count \(retries)")
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
        
    func testVersion() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                XCTAssertNotNil(session.version)
                XCTAssert(session.version.major == 5)
                XCTAssert(session.version.minor == 2 || session.version.minor == 3 || session.version.minor == 4)
                print("✅ Got version: \(session.version.major).\(session.version.minor).\(session.version.micro)")
                completion()
            }
        }
    }
    
    func testSerialNumber() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.getSerialNumber { serialNumber, error in
                    XCTAssertNil(error)
                    XCTAssertTrue(serialNumber > 0)
                    print("✅ Got serial number: \(serialNumber)")
                    completion()
                }
            }
        }
    }
    
    func testManagementKeyMetadata() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                if !session.features.metadata.isSupported(bySession: session) {
                    print("Skipping read metadata test since it's not supported by this YubiKey.")
                    completion()
                    return
                }
                session.getManagementKeyMetadata { metaData, error in
                    XCTAssertNil(error)
                    guard let metaData = metaData else { XCTAssert(false); return }
                    XCTAssert(metaData.isDefault == true)
                    XCTAssert(metaData.keyType.value == YKFPIVManagementKeyType.tripleDES().value)
                    XCTAssert(metaData.touchPolicy == .never)
                    print("✅ Default management key metadata")
                    completion()
                }
            }
        }
    }
    
    func testAESManagementKeyMetadata() throws {
        runYubiKitTest { connection, completion in
            connection.authenticatedPivTestSession { session in
                if !session.features.metadata.isSupported(bySession: session) {
                    print("Skipping read metadata test since it's not supported by this YubiKey.")
                    completion()
                    return
                }
                let aesManagementKey = Data([0xf7, 0xef, 0x78, 0x7b, 0x46, 0xaa, 0x50, 0xde, 0x06, 0x6b, 0xda, 0xde, 0x00, 0xae, 0xe1, 0x7f, 0xc2, 0xb7, 0x10, 0x37, 0x2b, 0x72, 0x2d, 0xe5])
                session.setManagementKey(aesManagementKey, type: .aes192(), requiresTouch: true) { error in
                    session.getManagementKeyMetadata { metaData, error in
                        XCTAssertNil(error)
                        guard let metaData = metaData else { XCTAssert(false); return }
                        XCTAssert(metaData.isDefault == false)
                        XCTAssert(metaData.keyType.value == YKFPIVManagementKeyType.aes192().value)
                        XCTAssert(metaData.touchPolicy == .always)
                        print("✅ AES management key metadata")
                        completion()
                    }
                }
            }
        }
    }
    
    func testPinMetadata() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                if !session.features.metadata.isSupported(bySession: session) {
                    print("Skipping read metadata test since it's not supported by this YubiKey.")
                    completion()
                    return
                }
                session.getPinMetadata { isDefault, retries, retriesLeft, error in
                    XCTAssert(isDefault == true)
                    XCTAssert(retries == 3)
                    XCTAssert(retriesLeft == 3)
                    print("✅ PIN metadata")
                    completion()
                }
            }
        }
    }
    
    func testPinMetadataRetries() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                if !session.features.metadata.isSupported(bySession: session) {
                    print("Skipping read metadata test since it's not supported by this YubiKey.")
                    completion()
                    return
                }
                session.verifyPin("112233") { retries, error in
                    XCTAssert(error != nil)
                    session.getPinMetadata { isDefault, retries, retriesLeft, error in
                        XCTAssert(isDefault == true)
                        XCTAssert(retries == 3)
                        XCTAssert(retriesLeft == 2)
                        print("✅ PIN metadata retry count")
                        completion()
                    }
                }
            }
        }
    }
    
    func testPukMetadata() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                if !session.features.metadata.isSupported(bySession: session) {
                    print("Skipping read metadata test since it's not supported by this YubiKey.")
                    completion()
                    return
                }
                session.getPukMetadata { isDefault, retries, retriesLeft, error in
                    XCTAssert(isDefault == true)
                    XCTAssert(retries == 3)
                    XCTAssert(retriesLeft == 3)
                    print("✅ PUK metadata")
                    completion()
                }
            }
        }
    }
    
    func testSetPin() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.setPin("654321", oldPin: "123456") { error in
                    XCTAssert(error == nil)
                    session.verifyPin("654321") { retries, error in
                        XCTAssert(error == nil)
                        print("✅ Changed pin")
                        completion()
                    }
                }
            }
        }
    }
    
    func testUnblockPin() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.blockPin() {
                    session.unblockPin("12345678", newPin: "222222") { error in
                        XCTAssert(error == nil)
                        session.verifyPin("222222") { retries, error in
                            XCTAssert(error == nil)
                            print("✅ Pin unblocked")
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func testSetPukAndUnblock() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                session.setPuk("87654321", oldPuk: "12345678") { error in
                    XCTAssert(error == nil)
                    session.blockPin() {
                        session.unblockPin("87654321", newPin: "222222") { error in
                            XCTAssert(error == nil)
                            session.verifyPin("222222") { retries, error in
                                XCTAssert(error == nil)
                                print("✅ New puk verified")
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
}

extension YKFPIVSession {
    func blockPin(completion: @escaping () -> Void) {
        blockPin(counter:0, completion: completion)
    }
    
    private func blockPin(counter: Int, completion: @escaping () -> Void) {
        self.verifyPin("") { retries, error in
            guard retries != -1 && error != nil else {
                XCTAssert(false, "Failed blocking pin with error: \(error!)")
                completion()
                return
            }
            if retries <= 0 || counter > 15 {
                print("pin blocked after \(counter + 1) tries")
                completion()
                return
            }
            self.blockPin(counter: counter + 1, completion: completion)
        }
    }
}

extension YKFConnectionProtocol {
    func pivTestSession(completion: @escaping (_ session: YKFPIVSession) -> Void) {
        self.pivSession { session, error in
            guard let session = session else { XCTAssertTrue(false, "🔴 Failed to get PIV session"); return }
//            completion(session)
//            return
            session.reset { error in
                guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset PIV application"); return }
                print("Reset PIV application")
                completion(session)
            }
        }
    }
    
    func authenticatedPivTestSession(completion: @escaping (_ session: YKFPIVSession) -> Void) {
        self.pivTestSession { session in
            let defaultManagementKey = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
            session.authenticate(withManagementKey: defaultManagementKey, keyType: .tripleDES()) { error in
                guard error == nil else { XCTAssertTrue(false, "🔴 Failed to authenticate PIV application"); return }
                completion(session)
            }
        }
    }
}
