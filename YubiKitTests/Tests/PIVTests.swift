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
                session.verifyPin("123456") { error in
                    XCTAssertNil(error)
                    completion()
                }
            }
        }
    }
}

extension YKFConnectionProtocol {
    func pivTestSession(completion: @escaping (_ session: YKFPIVSession) -> Void) {
        self.pivSession { session, error in
            guard let session = session else { XCTAssertTrue(false, "Failed to get OATH session"); return }
            completion(session)
        }
    }
}
