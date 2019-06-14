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

    private let swCodeSuccess: UInt16 = 0x9000
    
    // MARK: - Outlets
    
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var runDemoButton: UIButton!
    
    // MARK: - Actions
    
    @IBAction func runDemoButtonPressed(_ sender: Any) {
        logTextView.text = nil
        setDemoButton(enabled: false)
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else {
                return
            }
            self.runPIVDemo()
            self.setDemoButton(enabled: true)
        }
    }
    
    private func setDemoButton(enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.runDemoButton.isEnabled = enabled
            self.runDemoButton.backgroundColor = enabled ? NamedColor.yubicoGreenColor : UIColor.lightGray
        }
    }
    
    // MARK: - Raw Command Service Example
    
    private func runPIVDemo() {
        
        let keySession = YubiKitManager.shared.keySession
        
        /*
         1. Check if the key is connected.
         */
        let keyConnected = keySession.isKeyConnected
        guard keyConnected else {
            log(message: "The key is not plugged in.")
            return
        }
        
        /*
         2. Start the session.
         */
        let sessionStarted = keySession.startSessionSync()
        guard sessionStarted else {
            log(message: "Could not connect to the key.")
            return
        }
        
        /*
         3. Show serial number.
         */
        let serialNumber = keySession.keyDescription!.serialNumber
        log(message: "The key serial number is: \(serialNumber).")
        
        /*
         4. Select the PIV application.
         */
        let selectPIVCommand = Data([0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08])
        guard let selectPIVApdu = YKFAPDU(data: selectPIVCommand) else {
            return
        }
        
        keySession.rawCommandService?.executeSyncCommand(selectPIVApdu, completion: { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error when executing command: \(error!.localizedDescription)")
                return
            }
        
            let responseParser = RawDemoResponseParser(response: response!)
            let statusCode = responseParser.statusCode
            
            if statusCode == self.swCodeSuccess {
                self.log(message: "PIV application selected.")
            } else {
                self.log(message: "PIV application selection failed. SW returned by the key: \(statusCode).")
            }
        })
        
        
        /*
         5. Verify against the PIV application from the key (PIN is default 123456).
         */
        let verifyCommand = Data([0x00, 0x20, 0x00, 0x80, 0x08, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff])
        guard let verifyApdu = YKFAPDU(data: verifyCommand) else {
            return
        }
        
        keySession.rawCommandService?.executeSyncCommand(verifyApdu, completion: { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error when executing command: \(error!.localizedDescription)")
                return
            }
            
            let responseParser = RawDemoResponseParser(response: response!)
            let statusCode = responseParser.statusCode
            
            if statusCode == self.swCodeSuccess {
                self.log(message: "PIN verification successful.")
            } else {
                self.log(message: "PIN verification failed. SW returned by the key: \(statusCode).")
            }
        })
    
        /*
         6.1 Read the certificate stored on the PIV application in slot 9C.

         Note: Reading a certificate is not something which requires verification since the certificate
         is something which is ment to public. Only adding a new certificate requires verification.
         */

        // Helpers for reading the data in chunks when the key sends a large amount of data.
        var readBuffer = Data()
        var sendRemaining = true

        var readCommand = Data([0x00, 0xCB, 0x3F, 0xFF, 0x05, 0x5C, 0x03, 0x5F, 0xC1, 0x0A])
        var readApdu = YKFAPDU(data: readCommand)
        guard readApdu != nil else {
            return
        }
        
        while sendRemaining {
            var statusCode: UInt16 = 0x00
            var responseData: Data? = nil
            
            keySession.rawCommandService?.executeSyncCommand(readApdu!, completion: { [weak self] (response, error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.log(message: "Error when executing command: \(error!.localizedDescription)")
                    return
                }
                
                let responseParser = RawDemoResponseParser(response: response!)
                
                statusCode = responseParser.statusCode
                responseData = responseParser.responseData
            })

            if responseData != nil {
                readBuffer.append(responseData!)
            }
            
            if statusCode == swCodeSuccess {
                log(message: "Reading certificate successful.")
                sendRemaining = false
            } else if statusCode >> 8 == 0x61 {
                // PIV application send remaining APDU
                readCommand = Data([0x00, 0xC0, 0x00, 0x00])
                readApdu = YKFAPDU(data: readCommand)
                log(message: "Fetching more data from the key...")
            } else {
                log(message: "Could not read the certificate. SW returned by the key: \(statusCode).")
                sendRemaining = false
            }
        }

        if readBuffer.count == 0 {
            log(message: "Could not read the certificate from the slot. The slot seems to be empty.")
            return
        }

        /*
         6.2 Parse the certificate object.
         */

        guard let certificate = RawDemoSecCertificate(keyData: readBuffer) else {
            log(message: "Could not create a certificate with the data returned from the YubiKey.")
            return
        }

        /*
         6.3 Use the certificate to verify a signature.
         */

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
            log(message: "Could not create a data object from the supplied signature Base64 encoded string.")
            return
        }
        let signedData = signedString.data(using: String.Encoding.utf8)!

        let signatureIsValid = certificate.verify(data: signedData, signature: signatureData!)
        log(message:signatureIsValid ? "Signature is valid." : "Signature is not valid.")

        /*
         7. Close the session.
         */
        
        // Temporary disable the observation to not wipe the logs after the session was closed.
        observeSessionStateUpdates = false
        keySession.stopSessionSync()
        observeSessionStateUpdates = true
    }
    
    // MARK: - Session State Updates
    
    override func keySessionStateDidChange() {
        let sessionState = YubiKitManager.shared.keySession.sessionState
        if sessionState == .closed {
            logTextView.text = nil
            setDemoButton(enabled: true)
        }
    }
    
    // MARK: - Logging Helpers
    
    private func log(message: String) {
        DispatchQueue.main.async { [weak self] in
            print(message)
            self?.logTextView.insertText("\(message)\n")
        }
    }
}
