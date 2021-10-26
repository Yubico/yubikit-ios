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
            connection.managementSessionAndDeviceInfo { session, deviceInfo in
                guard let configuration = deviceInfo.configuration else { XCTAssertTrue(false, "No configuration"); return }
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
                                print("✅ disabled and enabled OATH")
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
            connection.managementSessionAndDeviceInfo { session, deviceInfo in
                guard let configuration = deviceInfo.configuration else { XCTAssertTrue(false, "No configuration"); return }
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
                                print("✅ disabled and enabled U2F")
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
            connection.managementSessionAndDeviceInfo { session, deviceInfo in
                // Only assert major and minor version
                XCTAssert(deviceInfo.version.major == 5)
                XCTAssert(deviceInfo.version.minor == 2 || deviceInfo.version.minor == 3 || deviceInfo.version.minor == 4)
                print("✅ Got version: \(deviceInfo.version)")
                completion()
            }
        }
    }
    
    func testDeviceInfo() {
        runYubiKitTest { connection, completion in
            connection.managementSession { session, error in
                guard let session = session else { XCTFail("Failed to get Management Session"); return }
                session.getDeviceInfo { deviceInfo, error in
                    guard let deviceInfo = deviceInfo else { XCTFail("Failed to get DeviceInfo: \(error!)"); return }
                    print("✅ Got device info:")
                    print("     is locked: \(deviceInfo.isConfigurationLocked)")
                    print("     serial number: \(deviceInfo.serialNumber)")
                    print("     form factor: \(deviceInfo.formFactor.rawValue)")
                    print("     firmware version: \(deviceInfo.version)")
                    completion()
                }
            }
        }
    }
}

extension YKFConnectionProtocol {
    func managementSessionAndDeviceInfo(completion: @escaping (_ session: YKFManagementSession,
                                                                  _ response: YKFManagementDeviceInfo) -> Void) {
        self.managementSession { session, error in
            guard let session = session else { XCTAssertTrue(false, "Failed to get Management Session: \(error!)"); return }
            session.getDeviceInfo { deviceInfo, error in
                guard let deviceInfo = deviceInfo else { XCTAssertTrue(false, "Failed to read device info: \(error!)"); return }
                completion(session, deviceInfo)
            }
        }
    }
}
