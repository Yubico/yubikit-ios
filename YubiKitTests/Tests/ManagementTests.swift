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

class ManagementTests: XCTestCase {
    func testDisableOATH() {
        runYubiKitTest { connection, completion in
            let transport: YKFManagementTransportType
            if connection as? YKFNFCConnection != nil {
                transport = .NFC
            } else {
                transport = .USB
            }
            connection.managementSessionAndConfiguration { session, response in
                guard let configuration = response.configuration else { XCTAssertTrue(false, "No configuration"); return }
                configuration.setEnabled(false, application: .OATH, overTransport: transport)
                session.write(configuration, reboot: false) { error in
                    guard error == nil else { XCTAssertTrue(false, "Error while writing configuration: \(error!)"); return }
                    connection.oathSession { session, error in
                        guard session == nil else { XCTAssertTrue(true, "Failed to disable OATH"); return }
                        connection.managementSession { session, error in
                            guard let session = session else { XCTAssertTrue(false, "Failed to get ManagementSession: \(error!)"); return }
                            configuration.setEnabled(true, application: .OATH, overTransport: transport)
                            session.write(configuration, reboot: false) { error in
                                guard error == nil else { XCTAssertTrue(true, "Failed to enable OATH: \(error!)"); return}
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testDisableU2F() {
        runYubiKitTest { connection, completion in
            let transport: YKFManagementTransportType
            if connection as? YKFNFCConnection != nil {
                transport = .NFC
            } else {
                transport = .USB
            }
            connection.managementSessionAndConfiguration { session, response in
                guard let configuration = response.configuration else { XCTAssertTrue(false, "No configuration"); return }
                configuration.setEnabled(false, application: .U2F, overTransport: transport)
                session.write(configuration, reboot: false) { error in
                    guard error == nil else { XCTAssertTrue(false, "Error while writing configuration: \(error!)"); return }
                    connection.u2fSession { session, error in
                        guard session == nil else { XCTAssertTrue(true, "Failed to disable U2F"); return }
                        connection.managementSession { session, error in
                            guard let session = session else { XCTAssertTrue(false, "Failed to get ManagementSession: \(error!)"); return }
                            configuration.setEnabled(true, application: .U2F, overTransport: transport)
                            session.write(configuration, reboot: false) { error in
                                guard error == nil else { XCTAssertTrue(true, "Failed to enable U2F: \(error!)"); return}
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testReadKeyVersion() {
        runYubiKitTest { connection, completion in
            connection.managementSessionAndConfiguration { session, response in
                print("🔴 Key responded with version \(response.version.major).\(response.version.minor).\(response.version.micro).")
                // Only assert major and minor version
                XCTAssertTrue((response.version.major == 5  && response.version.minor == 2), "Key responded with version \(response.version.major).\(response.version.minor).\(response.version.micro). Expected 5.2.*.")
                completion()
            }
        }
    }
}

extension YKFConnectionProtocol {
    func managementSessionAndConfiguration(completion: @escaping (_ session: YKFManagementSession,
                                                                  _ response: YKFManagementReadConfigurationResponse) -> Void) {
        self.managementSession { session, error in
            guard let session = session else { XCTAssertTrue(false, "Failed to get Management Session: \(error!)"); return }
            session.readConfiguration { response, error in
                guard let response = response else { XCTAssertTrue(false, "Failed to read Configuration: \(error!)"); return }
                completion(session, response)
            }
        }
    }
}
