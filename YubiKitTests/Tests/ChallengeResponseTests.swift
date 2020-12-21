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

class ChallengeResponseTests: XCTestCase {
    
    // OTP Challenge Response with f6d6475b48b94f0d849a6c19bf8cc7f0d62255a0 as a secret stored in slot #2 (long touch)
    func testChallengeResponse() {
        runYubiKitTest { connection, completion in
            connection.challengeResponseSession { session, error in
                guard let session = session else { XCTAssertTrue(false, "🔴 Failed to get Challenge Response session"); return }
                let data = Data([0x49, 0x50, 0x51, 0x52, 0x53, 0x54])
                session.sendChallenge(data, slot: .two) { result, error in
                    guard let result = result else { XCTAssertTrue(false, "🔴 \(error!)"); return }
                    let exptected = Data([0xd5, 0x49, 0xe8, 0x34, 0x82, 0x75, 0x98, 0xf6, 0xf1, 0x7b, 0xc4, 0xd3, 0xf3, 0x84, 0x65, 0xb1, 0x91, 0x00, 0x29, 0xf7])
                    XCTAssertEqual(result.hexDescription, exptected.hexDescription) // comparing the hex string representation results in better assert messages
                    print("🟢 Challenge Response successful")
                    completion()
                }
            }
        }
    }
}
