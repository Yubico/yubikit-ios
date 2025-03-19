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

class SCPTests: XCTestCase {
    func testSCP03() throws {
        runYubiKitTest { connection, completion in
            let defaultKey = Data([0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f])
            let scp03KeyParams = YKFSCP03KeyParams(keyRef: YKFSCPKeyRef(kid: 0x01, kvn: 0xff), staticKeys: YKFSCPStaticKeys(enc: defaultKey, mac: defaultKey, dek: defaultKey))
            connection.oathSession() { session, error in
                guard let session else { XCTFail("Failed to get a OATH session"); completion(); return }
                session.reset { error in
                    guard error == nil else { XCTFail("Failed to reset: \(error!)"); completion(); return }
                    connection.oathSession(scp03KeyParams) { scp03Session, error in
                        guard let scp03Session else { XCTFail("Failed to reset: \(error!)"); completion(); return }
                        print("✅ scp03 setup completed")
                        scp03Session.listCredentials(completion: { credentials, error in
                            guard let credentials else { XCTFail("Failed to list credentials: \(error!)"); completion(); return }
                            XCTAssertEqual(credentials.count, 0)
                            completion()
                        })
                    }
                }
            }
        }
    }
}
