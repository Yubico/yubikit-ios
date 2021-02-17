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
