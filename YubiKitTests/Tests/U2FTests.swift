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

let challenge = "D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc"
let appId = "https://demo.yubico.com"

class U2FTests: XCTestCase {

    func testRegister() throws {
        runYubiKitTest { connection, completion in
            connection.u2fTestSession { session in
                print("🔵 touch key")
                session.register(withChallenge: challenge, appId: appId) { response, error in
                    guard let response = response, let keyHandle = response.keyHandle else { XCTAssertTrue(false, "🔴 Failed to register U2F request: \(error!)"); return }
                    print("🔵 touch key")
                    session.sign(withChallenge: challenge, keyHandle: keyHandle, appId: appId) { response, error in
                        guard error == nil else { XCTAssertTrue(false, "🔴 Failed to sign U2F request: \(error!)"); return }
                        print("✅ U2F registration and sign successful")
                        completion()
                    }
                }
            }
        }
    }
}

extension YKFConnectionProtocol {
    func u2fTestSession(completion: @escaping (_ session: YKFU2FSession) -> Void) {
        self.u2fSession { session, error in
            guard let session = session else { XCTAssertTrue(false, "Failed to get U2F session"); return }
            completion(session)
        }
    }
}

/*
 Extract the keyhandle client side to make the tests self contained. This is normally
 done by the server.
*/
extension  YKFU2FRegisterResponse {
    var keyHandle: String? {
        let length = Int(registrationData[66])
        let data = registrationData[67..<67+length] as NSData
        return data.ykf_websafeBase64EncodedString()
    }
}
