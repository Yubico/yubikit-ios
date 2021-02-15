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
    
    func testRenameCredential() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                let url = URL(string: "otpauth://totp/Yubico:test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=test-rename&algorithm=SHA1&digits=6&period=30")!
                let template = YKFOATHCredentialTemplate(url: url)!
                session.put(template, requiresTouch: false) { error in
                    guard error == nil else { XCTAssertTrue(false); return }
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
    
    func testSetCodeAndUnlock() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                session.setPassword("271828") { error in
                    guard error == nil else { XCTAssertTrue(false); return }
                    connection.fido2Session { fidoSession, error in
                        guard error == nil else { XCTAssertTrue(false); return }
                        connection.oathSession { session, error in
                            guard let session = session else { XCTAssert(false); return }
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
            }
        }
    }
    
    func testSetCodeAndUnlockWithWrongCode() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                session.setPassword("271828") { error in
                    guard error == nil else { XCTAssertTrue(false); return }
                    connection.fido2Session { fidoSession, error in
                        guard error == nil else { XCTAssertTrue(false); return }
                        connection.oathSession { session, error in
                            guard let session = session else { XCTAssert(false); return }
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
            }
        }
    }
    
    
    func testSetAndRemoveCode() throws {
        runYubiKitTest { connection, completion in
            connection.oathTestSession { session in
                session.setPassword("271828") { error in
                    guard error == nil else { XCTAssertTrue(false); return }
                    connection.fido2Session { fidoSession, error in
                        guard error == nil else { XCTAssertTrue(false); return }
                        connection.oathSession { session, error in
                            guard let session = session else { XCTAssertTrue(false); return }
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
            }
        }
    }
}

extension YKFConnectionProtocol {
    func oathTestSession(completion: @escaping (_ session: YKFOATHSession) -> Void) {
        self.oathSession { session, error in
            guard let session = session else { XCTAssertTrue(false, "Failed to get OATH session"); return }
            session.reset { error in
                guard error == nil else { XCTAssertTrue(false, "Failed to reset OATH"); return }
                completion(session)
            }
        }
    }
}
