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
    func testAuthenticateWithDefaultManagementKey() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                let managementKey = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
                session.authenticate(with: YKFPIVManagementKeyType.tripleDES(), managementKey: managementKey) { error in
                    XCTAssert(error == nil, "🔴 \(error!)")
                    print("✅ authenticated")
                    completion()
                }

            }
        }
    }
    
    func testAuthenticateWithWrongManagementKey() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
                let managementKey = Data([0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01])
                session.authenticate(with: YKFPIVManagementKeyType.tripleDES(), managementKey: managementKey) { error in
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
    
    func testPinMetadata() throws {
        runYubiKitTest { connection, completion in
            connection.pivTestSession { session in
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
                session.blockPin(counter: 0) {
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
                    session.blockPin(counter: 0) {
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
    func blockPin(counter: Int, completion: @escaping () -> Void) {
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
            session.reset { error in
                guard error == nil else { XCTAssertTrue(false, "🔴 Failed to reset PIV application"); return }
                print("Reset PIV application")
                completion(session)
            }
        }
    }
}
