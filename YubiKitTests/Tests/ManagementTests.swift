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

fileprivate let lockCode =      Data(hexEncodedString: "01020304050607080102030405060708")!
fileprivate let clearLockCode = Data(hexEncodedString: "00000000000000000000000000000000")!

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
                XCTAssert(deviceInfo.version.minor == 2 || deviceInfo.version.minor == 3 || deviceInfo.version.minor == 4 || deviceInfo.version.minor == 7)
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
                    print("""
YubiKey \(deviceInfo.formFactor) \(deviceInfo.version) (#\(deviceInfo.serialNumber))
Supported capabilities: \(String(describing: deviceInfo.configuration?.nfcSupportedMask))
Supported capabilities: \(String(describing: deviceInfo.configuration?.usbSupportedMask))
isConfigLocked: \(deviceInfo.isConfigurationLocked)
isFips: \(deviceInfo.isFips)
isSky: \(deviceInfo.isSky)
partNumber: \(String(describing: deviceInfo.partNumber))
isFipsCapable: \(deviceInfo.isFIPSCapable)
isFipsApproved: \(deviceInfo.isFIPSApproved)
pinComplexity: \(deviceInfo.pinComplexity)
resetBlocked: \(deviceInfo.isResetBlocked)
fpsVersion: \(String(describing: deviceInfo.fpsVersion))
stmVersion: \(String(describing: deviceInfo.stmVersion))
""")
                    completion()
                }
            }
        }
    }
    
    func testLockCode() throws {
        runYubiKitTest { connection, completion in
            connection.managementSessionAndDeviceInfo { session, deviceInfo in
                let config = deviceInfo.configuration!
                session.write(config, reboot: false, lockCode: nil, newLockCode: lockCode) { error in
                    guard error == nil else { XCTFail("Failed setting new lock code"); return }
                    print("✅ Lock code set to: \(lockCode.hexDescription)")
                    session.write(config, reboot: false, lockCode: nil) { error in
                        guard error != nil else { XCTFail("Successfully updated config although no lock code was supplied and it should have been enabled."); return }
                        print("✅ Failed updating device config (as expected) without using lock code.")
                        session.write(config, reboot: false, lockCode: lockCode) { error in
                            guard error == nil else { print("Failed to update device config even though lock code was supplied."); return }
                            print("✅ Succesfully updated device config using lock code.")
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func testZEnableNFCRestriction() {
        runYubiKitTest { connection, completion in
            connection.managementSessionAndDeviceInfo { session, deviceInfo in
                guard let config = deviceInfo.configuration else { completion(); return }
                config.isNFCRestricted = true
                session.write(config, reboot: false) { error in
                    XCTAssertNil(error)
                    session.getDeviceInfo { deviceInfo, error in
                        XCTAssertNil(error)
                        if let isNFCRestricted = deviceInfo?.configuration?.isNFCRestricted {
                            XCTAssertTrue(isNFCRestricted)
                        }
                        completion()
                    }
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
                session.write(deviceInfo.configuration!, reboot: false, lockCode: lockCode, newLockCode: clearLockCode) { error in
                    completion(session, deviceInfo)
                }
            }
        }
    }
}
