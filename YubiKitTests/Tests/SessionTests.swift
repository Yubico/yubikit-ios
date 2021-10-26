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

class SessionTests: XCTestCase {
    
    func testDispatchAfterCommands() throws {
        runYubiKitTest { connection, completion in
            connection.oathSession { session, error in
                guard let session = session else { completion(); XCTFail("Failed to get session: \(error!)"); return }
                session.calculateAll { credentials, error in
                    print("Finished calculating first set of credentials...")
                }
                session.calculateAll { credentials, error in
                    print("Finished calculating second set of credentials...")
                }
                session.calculateAll { credentials, error in
                    print("Finished calculating third set of credentials...")
                }
                session.calculateAll { credentials, error in
                    print("Finished calculating fourth set of credentials...")
                }
                session.dispatchAfterCurrentCommands {
                    print("✅ Block enqueued after fourth set executed...")
                }
                session.calculateAll { credentials, error in
                    print("Finished calculating fifth set of credentials...")
                }
                session.dispatchAfterCurrentCommands {
                    print("✅ Block enqueued after fifth set executed...")
                    completion()
                }
            }
        }
    }

    func testOATHSession() throws {
        runYubiKitTest { connection, completion in
            connection.oathSession { session, error in
                assert(session != nil)
                completion()
            }
        }
    }
    
    func testFIDO2Session() throws {
        runYubiKitTest { connection, completion in
            connection.fido2Session { session, error in
                assert(session != nil)
                completion()
            }
        }
    }
    
    func testPIVSession() throws {
        runYubiKitTest { connection, completion in
            connection.pivSession { session, error in
                assert(session != nil)
                completion()
            }
        }
    }

    func testManagementSession() throws {
        runYubiKitTest { connection, completion in
            connection.managementSession { session, error in
                assert(session != nil)
                completion()
            }
        }
    }
}
