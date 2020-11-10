// Copyright 2018-2019 Yubico AB
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

import UIKit

/*
 This demo shows how to read a certificate from the key PIV application,
 loaded on slot 9c, using the Raw Command Service from YubiKit.
 
 Notes:
    1. The key should be connected to the device before executing this demo.
    2. Dispatch async on a backgroud queue to not lock the calling thread (if main).
    3. This code requires a certificate to be added to the key on slot 9c:
        - The certificate to test with is provided in docassets/cert.der
        - Run: yubico-piv-tool -s9c -icert.der -KDER -averify -aimport-cert
 
 This is the preffered way of executing raw commands against the key and it should
 be used instead of the PC/SC interface when possible.
 */
class RawCommandServiceDemoViewController: OtherDemoRootViewController {
    
    // MARK: - Outlets
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var runDemoButton: UIButton!
    
    // MARK: - Actions
    @IBAction func runDemoButtonPressed(_ sender: Any) {
        self.connection { connection in
            self.log(message: "Connection: \(connection)")
            connection.rawCommandSession { session, error in
                guard let session = session else {
                    if let error = error {
                        self.log(error: error)
                    } else {
                        fatalError()
                    }
                    return
                }
                // 1. Select PIV application
                let selectPIVAPDU = YKFAPDU(data: Data([0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08]))!
                session.executeCommand(selectPIVAPDU) { response, error in
                    guard error == nil else {
                        self.log(error: error!)
                        return
                    }
                    
                    let responseParser = RawDemoResponseParser(response: response!)
                    let statusCode = responseParser.statusCode
                    
                    if statusCode == 0x9000 {
                        self.log(message: "PIV application selected.")
                    } else {
                        self.log(error: "PIV application selection failed. SW returned by the key: \(statusCode).")
                    }
                    
                    // 2. Verify against the PIV application from the key (PIN is default 123456).
                    let verifyApdu = YKFAPDU(data: Data([0x00, 0x20, 0x00, 0x80, 0x08, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff]))!

                    session.executeCommand(verifyApdu) { response, error in
                        guard error == nil else {
                            self.log(error: error!)
                            return
                        }
                        
                        let responseParser = RawDemoResponseParser(response: response!)
                        let statusCode = responseParser.statusCode
                        
                        if statusCode == 0x9000 {
                            self.log(message: "PIN verification successful.")
                        } else {
                            self.log(error: "PIN verification failed. SW returned by the key: \(statusCode).")
                        }
                        
                        // 3. Read the certificate stored on the PIV application in slot 9C.
                        let readBuffer = Data()
                        let readApdu = YKFAPDU(data: Data([0x00, 0xCB, 0x3F, 0xFF, 0x05, 0x5C, 0x03, 0x5F, 0xC1, 0x0A]))!
                        self.readCertificate(session: session, readBuffer: readBuffer, readAPDU: readApdu) { data in
                            guard let data = data else {
                                self.log(error: "Failed to read certificate")
                                return
                            }
                            
                            if data.count == 0 {
                                self.log(error: "Could not read the certificate from the slot. The slot seems to be empty.")
                                return
                            }
                            
                            // 4. Parse the certificate data
                            guard let certificate = RawDemoSecCertificate(keyData: data) else {
                                self.log(error: "Could not create a certificate with the data returned from the YubiKey.")
                                return
                            }

                            // 5. Use the certificate to verify a signature.
                            // The data which was signed with the private key of the stored certificate.
                            let signedString = "yk certificate test"
                            let signedStringB64Signature = """
                                                           XKDV/7sBSYEOEYcTL+C3PErOQ46Ql8y0MJDzh6OT7g3hvI/zi/UfHNls+CRrm8rjE0\
                                                           UtwqpniBU5lhMQxoICcUemg3c3BZeFl4QaKsuNfcPQ4Q0cPFT35vr5aMwj9EHcLlzS\
                                                           iYT20lVNpk8m48LBMGu0r8KGTz1GD1lzxxLJe/ZHbkTJTSCrbRBORpq8kGgB33Eukr\
                                                           7T6eCeobYKQYS7f5Ky8AYtTUbR11vdLAPCsngJaBHnVMabKsBlZ782fqBxaaAPzECR\
                                                           F5SUpeBpLeqrJ3FYC6m+oyuXG/fpVJQzCHDTIWpXKSvYiebvFQ9OYiBDrN+KCF6n/j\
                                                           07IDatH/5WnQ==
                                                           """
                            let signatureData = Data(base64Encoded: signedStringB64Signature)
                            if signatureData == nil {
                                self.log(error: "Could not create a data object from the supplied signature Base64 encoded string.")
                                return
                            }
                            let signedData = signedString.data(using: String.Encoding.utf8)!

                            let signatureIsValid = certificate.verify(data: signedData, signature: signatureData!)
                            self.log(message:signatureIsValid ? "Signature is valid." : "Signature is not valid.")
                            if #available(iOS 13.0, *) {
                                YubiKitManager.shared.stopNFCConnection()
                            }
                        }
                    }
                 }
            }
        }
    }
    
    func readCertificate(session: YKFKeyRawCommandSessionProtocol, readBuffer: Data, readAPDU: YKFAPDU, completion:  @escaping ((_ data: Data?) -> Void))  {
        
        session.executeCommand(readAPDU) { response, error in
            guard error == nil else {
                self.log(message: "Error when executing command: \(error!.localizedDescription)")
                return
            }
            var mutableReadBuffer = readBuffer
            let responseParser = RawDemoResponseParser(response: response!)
            let statusCode = responseParser.statusCode
            let responseData = responseParser.responseData
            if let responseData = responseData {
                mutableReadBuffer.append(responseData)
            }
            
            if statusCode == 0x9000 {
                self.log(message: "Reading certificate successful.")
                completion(mutableReadBuffer)
            } else if statusCode >> 8 == 0x61 {
                // PIV application send remaining APDU
                let readRemainingApdu = YKFAPDU(data: Data([0x00, 0xC0, 0x00, 0x00]))!
                self.log(message: "Fetching more data from the key...")
                self.readCertificate(session: session, readBuffer: mutableReadBuffer, readAPDU: readRemainingApdu, completion: completion)
            } else {
                self.log(error: "Could not read the certificate. SW returned by the key: \(statusCode).")
                completion(nil)
            }
        }
    }
    
    // MARK: - Logging Helpers
    private func log(message: String) {
        DispatchQueue.main.async { [weak self] in
            print(message)
            self?.logTextView.insertText("\(message)\n")
        }
    }
    
    private func log(error: Error) {
        self.log(error: "Error when executing command: \(error.localizedDescription)")
    }
    
    private func log(error: String) {
        self.log(message: error)
        if #available(iOS 13.0, *) {
            YubiKitManager.shared.stopNFCConnection()
        }
    }
}
