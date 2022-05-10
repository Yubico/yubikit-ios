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

class OATHTests: XCTestCase {
    func testCreateAndCalculateAllTOTP() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                let url = URL(string: "otpauth://totp/Yubico:test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=test-create-and-calculate&algorithm=SHA1&digits=6&period=30")!
                let template = YKFOATHCredentialTemplate(url: url)!
                session.put(template, requiresTouch: false) { error in
                    guard error == nil else { XCTAssertTrue(false); return }
                    NSDate.swizzleDate() // Swizzle the date to always return the same date. This is needed to always get the same OTP from the key.
                    session.calculateAll { credentials, error in
                        NSDate.swizzleDate()
                        guard let credential = credentials?.first else { XCTAssertTrue(false); return }
                        XCTAssert(credential.credential.issuer == "test-create-and-calculate")
                        XCTAssert(credential.credential.accountName == "test@yubico.com")
                        XCTAssert(credential.code?.otp == "239396")
                        print("✅ create and calculate all OATH TOTP credential")
                        completion()
                    }
                }
            }
        }
    }
    
    func testCalculateLotsOfTOTP() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                for n in 0...19 {
                    session.storeRandomCredential(number: n)
                }
                session.calculateAll { credentials, error in
                    guard let credentials = credentials else { XCTFail("Error: \(error!)"); completion(); return }
                    print("✅ calculated \(credentials.count) credentials")
                    completion()
                }
            }
        }
    }
    
    func testCalculateAllTouchRequiredTOTP() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                let totpUrl = URL(string: "otpauth://totp/Yubico:test-totp@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=test-requires-touch&algorithm=SHA1&digits=6&counter=30")!
                let template = YKFOATHCredentialTemplate(url: totpUrl)!
                session.put(template, requiresTouch: true) { error in
                    guard error == nil else { XCTFail("Failed creating TOTP"); return }
                    session.calculateAll { credentials, error in
                        guard let credential = credentials?.first else { XCTFail("No credentials calculated"); return }
                        XCTAssert(credential.credential.issuer == "test-requires-touch")
                        XCTAssert(credential.credential.accountName == "test-totp@yubico.com")
                        XCTAssert(credential.credential.requiresTouch == true)
                        print("✅ create OATH TOTP credential that requires touch")
                        completion()
                    }
                }
            }
        }
    }

    func testCreateListAndCalculateTOTP() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                let url = URL(string: "otpauth://totp/Yubico:test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=test-create-and-calculate&algorithm=SHA1&digits=6&counter=30")!
                let template = YKFOATHCredentialTemplate(url: url)!
                session.put(template, requiresTouch: false) { error in
                    guard error == nil else { XCTAssertTrue(false); return }
                    session.listCredentials { credentials, error in
                        guard let credential = credentials?.first else { XCTAssertTrue(false); return }
//                        credential.notTruncated = true
                        XCTAssert(credential.issuer == "test-create-and-calculate")
                        XCTAssert(credential.accountName == "test@yubico.com")
                        session.calculate(credential, timestamp: Date(timeIntervalSince1970: 0)) { code, error in
                            XCTAssert(code?.otp == "239396")
                            print("✅ create, list and calculate OATH HOTP credential")
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func testCreateListAndCalculateHOTP() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                let url = URL(string: "otpauth://hotp/Yubico:test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=test-create-and-calculate&algorithm=SHA1&digits=6&counter=30")!
                let template = YKFOATHCredentialTemplate(url: url)!
                session.put(template, requiresTouch: false) { error in
                    guard error == nil else { XCTAssertTrue(false); return }
                    session.listCredentials { credentials, error in
                        guard let credential = credentials?.first else { XCTAssertTrue(false); return }
                        XCTAssert(credential.issuer == "test-create-and-calculate")
                        XCTAssert(credential.accountName == "test@yubico.com")
                        session.calculate(credential) { code, error in
                            XCTAssert(code?.otp == "726826")
                            print("✅ create, list and calculate OATH HOTP credential")
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func testCreateAndCalculateResponse() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                // Test data from rfc2202
                let keyData = Data([0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b]) as NSData
                let url = URL(string: "otpauth://totp/Yubico:test@yubico.com?secret=\(keyData.ykf_base32String())&issuer=test-create-and-calculate-response&algorithm=SHA1&digits=7&counter=30")!
                let template = YKFOATHCredentialTemplate(url: url)!
                session.put(template, requiresTouch: false) { error in
                    guard error == nil else { XCTFail("Failed putting credential on YubiKey with error: \(error!)"); completion(); return }
                    
                    let id = Data(YKFOATHCredentialUtils.key(from: template).utf8)
                    let challenge = Data("Hi There".utf8)
                    session.calculateResponse(forCredentialID: id, challenge: challenge) { data, error in
                        guard let data = data else { XCTFail("Failed calculating response with error: \(error!)"); completion(); return }
                        let expected = Data([0xb6, 0x17, 0x31, 0x86, 0x55, 0x05, 0x72, 0x64, 0xe2, 0x8b, 0xc0, 0xb6, 0xfb, 0x37, 0x8c, 0x8e, 0xf1, 0x46, 0xbe, 0x00])
                        XCTAssertEqual(data, expected)
                        completion()
                    }
                }
            }
        }
    }
    
    func testRenameCredential() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                let url = URL(string: "otpauth://totp/Yubico:test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=test-rename&algorithm=SHA1&digits=6&period=30")!
                let template = YKFOATHCredentialTemplate(url: url)!
                session.put(template, requiresTouch: false) { error in
                    guard error == nil else { XCTFail("Failed saving credential: \(error!)"); return }
                    session.listCredentials { credentials, error in
                        guard let credentials = credentials, let credential = credentials.first else {  XCTAssertTrue(false); return }
                        session.renameCredential(credential, newIssuer: "test-rename-renamed", newAccount: "renamed@yubico.com") { error in
                            session.listCredentials { credentials, error in
                                guard let credentials = credentials, let credential = credentials.first else {  XCTAssertTrue(false); return }
                                XCTAssert(credential.issuer == "test-rename-renamed")
                                XCTAssert(credential.accountName == "renamed@yubico.com")
                                print("✅ rename OATH credential")
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testUnlock() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSessionWithPassword { session in
                session.unlock(withPassword:"271828") { error in
                    guard error == nil else { XCTAssert(false); return }
                    session.listCredentials { credentials, error in
                        XCTAssert(error == nil)
                        print("✅ set OATH password and unlock")
                        completion()
                    }
                }
            }
        }
    }
    
    
    func testUnlockWithWrongCode() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSessionWithPassword { session in
                session.unlock(withPassword:"271844") { error in
                    guard error != nil else { XCTAssert(false); return }
                    // Reset OATH on test YubiKey so password is not set when we're done.
                    // We only do this here since this is the last test in the OATH test suite
                    // that will run during testing.
                    session.unlock(withPassword:"271828") { error in
                        session.reset() { error in
                            print("✅ set OATH password and try unlock with wrong password")
                            completion()
                        }
                    }
                }
            }
        }
    }

    func testSetPasswordWithoutUnlock() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSessionWithPassword { session in
                session.setPassword("77773") { error in
                    guard let error = error else { XCTFail("Password probably set without unlock."); return }
                    let errorCode = YKFOATHErrorCode(rawValue: UInt((error as NSError).code))
                    XCTAssertEqual(errorCode, .authenticationRequired)
                    print("✅ got authenticationRequired when trying to set password without unlock.")
                    completion()
                }
            }
        }
    }
    
    func testRemoveCode() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSessionWithPassword { session in
                session.unlock(withPassword:"271828") { error in
                    guard error == nil else { XCTAssert(false); return }
                    session.setPassword("") { error in
                        guard error == nil else { XCTAssertTrue(false); return }
                        connection.fido2Session { fidoSession, error in
                            guard error == nil else { XCTAssertTrue(false); return }
                            connection.oathSession { session, error in
                                guard let session = session else { XCTAssert(false); return }
                                session.listCredentials { credentials, error in
                                    XCTAssert(error == nil)
                                    print("✅ set and remove OATH password")
                                    completion()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testAuthFailAndThenAuthAgain() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSessionWithPassword { session in
                session.calculateAll { credentials, error in
                    guard let error = error else { XCTFail("Did not get auth error"); return }
                    let errorCode = YKFOATHErrorCode(rawValue: UInt((error as NSError).code))
                    XCTAssertEqual(errorCode, .authenticationRequired)
                    session.unlock(withPassword:"271828") { error in
                        guard error == nil else {  XCTFail("Failed to unlock: \(error!)"); return }
                        session.listCredentials { credentials, error in
                            XCTAssert(error == nil)
                            print("✅ set OATH password and unlock")
                            completion()
                        }
                    }
                }
            }
        }
    }

    // This test is here to remove any lingering password for the OATH application
    func testZeeLastOne() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                print("✅ last OATH test, reset application")
                completion()
            }
        }
    }
}

extension YKFOATHSession {
    func storeRandomCredential(number: Int) {
        let account = "test-\(number)@yubico.com"
        let issuer = "Account-\(number)"
        let secret = "UOA6FJYR76R\(number)BGDJKLYICL3MUR7QH"
        let url = URL(string: "otpauth://totp/Yubico:\(account)?secret=\(secret)&\(issuer)&algorithm=SHA1&digits=6&period=30")!
        let template = YKFOATHCredentialTemplate(url: url)!
        self.put(template, requiresTouch: false) { error in
            if error != nil { XCTFail("Error: \(error!)") }
        }
    }
}

extension YKFConnectionProtocol {
    func oathTestSession(completion: @escaping (_ session: YKFOATHSession) -> Void) {
        self.oathSession { session, error in
            guard let session = session else { XCTFail("Failed to get OATH session: \(error!)"); return }
            session.reset { error in
                guard error == nil else { XCTFail("Failed to reset OATH session: \(error!)"); return }
                completion(session)
            }
        }
    }
    
    func oathTestSessionWithPassword(password: String = "271828", completion: @escaping (_ session: YKFOATHSession) -> Void) {
        self.oathTestSession { session in
            session.setPassword(password) { error in
                guard error == nil else { XCTFail("Failed to set password '\(password)'"); return }
                self.fido2Session { fidoSession, error in
                    guard error == nil else { XCTFail("Failed to reset OATH by getting a FIDO2 session"); return }
                    self.oathSession { session, error in
                        guard let session = session else { XCTFail("Failed to get OATH session: \(error!)"); return }
                        completion(session)
                    }
                }
            }
        }
    }
}
