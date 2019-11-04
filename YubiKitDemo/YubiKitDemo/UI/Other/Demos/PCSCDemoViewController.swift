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
 loaded on slot 9c, using the PC/SC interface from YubiKit.
 
 Notes:
    1. The key should be connected to the device before executing this demo.
    2. Dispatch async on a background queue to not lock the calling thread (if main).
    3. This code requires a certificate to be added to the key on slot 9c:
        - The certificate to test with is provided in docassets/cert.der
        - Run: yubico-piv-tool -s9c -icert.der -KDER -averify -aimport-cert
 
 The PC/SC interface is part of YubiKit to facilitate the integration of the library
 in applications where this interface is a requirement. Unless necessary, it's recommended
 to use the Raw Command Service which provides a better interface for interacting with
 the key. An equivalent demo for how to use the Raw Command Service is provided
 in the RawCommandServiceDemoViewController.
 */
class PCSCDemoViewController: OtherDemoRootViewController {

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
    
    // MARK: - PCSC example
    
    private func runPIVDemo() {
        /*
         1. Establish the context.
         */
        
        var context: Int32 = 0
        var result: Int64 = 0
        
        result = YKFSCardEstablishContext(YKF_SCARD_SCOPE_USER, nil, nil, &context)
        
        if result != YKF_SCARD_S_SUCCESS {
            log(message: "Could not establish context.")
            return
        }
        
        /*
         2. Get the readers and check for key presence. There is only one in this case.
         */
        
        // Ask for the readers length.
        var readersLength: UInt32 = 0

        result = YKFSCardListReaders(context, nil, nil, &readersLength)
        if result != YKF_SCARD_S_SUCCESS || readersLength == 0 {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            
            if result == YKF_SCARD_E_NO_READERS_AVAILABLE {
                log(message: "Could not ask for readers length. The key is not connected (\(result): \(errorDescription)).")
            } else {
                log(message: "Could not ask for readers length (\(result): \(errorDescription)).")
            }
            
            YKFSCardReleaseContext(context)
            return
        }
        
        // Allocated the right buffer size and get the readers.
        let readers = UnsafeMutablePointer<Int8>.allocate(capacity: Int(readersLength))
        result = YKFSCardListReaders(context, nil, readers, &readersLength)
        
        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            
            if result == YKF_SCARD_E_NO_READERS_AVAILABLE {
                log(message: "Could not list readers. The key is not connected (\(result): \(errorDescription)).")
            } else {
                log(message: "Could not list readers (\(result): \(errorDescription)).")
            }
            
            YKFSCardReleaseContext(context)
            return
        }
        log(message: "Reader \(String(cString: readers)) connected.")
        
        readers.deallocate()
        
        // Get the status
        var readerState = YKF_SCARD_READERSTATE()
        readerState.currentState = YKF_SCARD_STATE_UNAWARE
        
        result = YKFSCardGetStatusChange(context, 0, &readerState, 1)
        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not get status change (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        }
        
        if (readerState.eventState & YKF_SCARD_STATE_PRESENT) != 0 {
            log(message: "The key is not connected.")
        }
        
        /*
         3.1 Connect to the key.
         */
        
        var card: Int32 = 0
        var activeProtocol: UInt32 = YKF_SCARD_PROTOCOL_T1
        
        result = YKFSCardConnect(context, readers, YKF_SCARD_SHARE_EXCLUSIVE, YKF_SCARD_PROTOCOL_T1, &card, &activeProtocol)
        
        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not connect to the key (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        }
        
        /*
         3.2 Get the key status.
         */
        
        var state: UInt32 = 0
        
        result = YKFSCardStatus(card, nil, nil, &state, nil, nil, nil) // nil can be used for unused properties.

        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not read the key status (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        }

        switch state {
        case YKF_SCARD_ABSENT:
            log(message: "The key is not connected to the device.")
        case YKF_SCARD_SWALLOWED:
            log(message: "The key is connected but the session is not opened.")
        case YKF_SCARD_SPECIFICMODE:
            log(message: "The key is connected and the session is opened.")
        default:
            log(message: "Unknown key state.")
        }

        if state != YKF_SCARD_SPECIFICMODE {
            YKFSCardReleaseContext(context)
            return
        }
        
        /*
         3.3 Get the key serial number.
         */
        
        // Ask for the serial number buffer size.
        var attributeLength: UInt32 = 0
        result = YKFSCardGetAttrib(card, YKF_SCARD_ATTR_VENDOR_IFD_SERIAL_NO, nil, &attributeLength)
        
        if result != YKF_SCARD_S_SUCCESS || attributeLength == 0 {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not ask for serial size (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        }
        
        // Allocated the right buffer size and get the serial number.
        let attribute = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(attributeLength))
        result = YKFSCardGetAttrib(card, YKF_SCARD_ATTR_VENDOR_IFD_SERIAL_NO, attribute, &attributeLength)
        
        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not read the key serial number (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        } else {
            let serialNumber = String(cString: attribute)
            log(message: "The key serial number is: \(serialNumber).")
        }

        attribute.deallocate()
        
        /*
         4. Create a reusable buffer. CCID should not return a data buffer longer than 256(max response length) + 2 bytes(SW)
         */
        let transmitRecvBufferMaxSize: UInt32 = 258;
        let transmitRecvBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(transmitRecvBufferMaxSize))
        var transmitRecvBufferLength: UInt32 = transmitRecvBufferMaxSize
        
        /*
         5. Select the PIV application.
         */
        
        let selectPIVCommand: [UInt8] = [0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08]
        
        result = YKFSCardTransmit(card, nil, selectPIVCommand, UInt32(selectPIVCommand.count), nil, transmitRecvBuffer, &transmitRecvBufferLength)
        
        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not select the PIV application (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        } else {
            let responseData = Data(bytes:transmitRecvBuffer, count: Int(transmitRecvBufferLength))

            let responseParser = RawDemoResponseParser(response: responseData)
            let statusCode = responseParser.statusCode

            if statusCode == swCodeSuccess {
                log(message: "PIV application selected.")
            } else {
                log(message: "PIV application selection failed. SW returned by the key: \(statusCode).")
                
                YKFSCardReleaseContext(context)
                return
            }
        }
        
        /*
         6. Verify against the PIV application from the key (PIN is default 123456).
         */
        
        transmitRecvBufferLength = transmitRecvBufferMaxSize // reset length
        let verifyCommand: [UInt8] = [0x00, 0x20, 0x00, 0x80, 0x08, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff]
        
        result = YKFSCardTransmit(card, nil, verifyCommand, UInt32(verifyCommand.count), nil, transmitRecvBuffer, &transmitRecvBufferLength)
        
        if result != YKF_SCARD_S_SUCCESS {
            let errorDescription = String(cString: YKFPCSCStringifyError(result))
            log(message: "Could not verify PIN (\(result): \(errorDescription)).")
            
            YKFSCardReleaseContext(context)
            return
        }
        
        let responseData = Data(bytes:transmitRecvBuffer, count: Int(transmitRecvBufferLength))
        
        let responseParser = RawDemoResponseParser(response: responseData)
        let statusCode = responseParser.statusCode
        
        if statusCode == swCodeSuccess {
            log(message: "PIN verification successful.")
        } else {
            log(message: "PIN verification failed. SW returned by the key: \(statusCode).")
            
            YKFSCardReleaseContext(context)
            return
        }
        
        /*
         7.1 Read the certificate stored on the PIV application in slot 9C.
         
         Note: Reading a certificate is not something which requires verification since the certificate
         is something which is ment to public. Only adding a new certificate requires verification.
         */
        
        // Helpers for reading the data in chunks when the key sends a large amount of data.
        var readBuffer = Data()
        var sendRemaining = true
        
        transmitRecvBufferLength = transmitRecvBufferMaxSize // reset length
        var readCommand: [UInt8] = [0x00, 0xCB, 0x3F, 0xFF, 0x05, 0x5C, 0x03, 0x5F, 0xC1, 0x0A]
        
        while sendRemaining {
            result = YKFSCardTransmit(card, nil, readCommand, UInt32(readCommand.count), nil, transmitRecvBuffer, &transmitRecvBufferLength)
            
            if result != YKF_SCARD_S_SUCCESS {
                log(message: "Could not read the certificate.")
                
                YKFSCardReleaseContext(context)
                transmitRecvBuffer.deallocate()
                return
            }
            
            let responseData = Data(bytes:transmitRecvBuffer, count: Int(transmitRecvBufferLength))
            let responseParser = RawDemoResponseParser(response: responseData)
            
            let statusCode = responseParser.statusCode
            if let responseWithoutStatus = responseParser.responseData {
                readBuffer.append(responseWithoutStatus)
            }
            
            if statusCode >> 8 == 0x61 {
                // If status code is 0x61XX a send remaining message should be sent to the key to fetch the remaining data.
                readCommand = [0x00, 0xC0, 0x00, 0x00] // PIV application send remaining APDU
                log(message: "Fetching more data from the key...")
            }
            else if statusCode == swCodeSuccess {
                log(message: "Read certificate successful.")
                sendRemaining = false
            } else {
                log(message: "Could not read the certificate. SW returned by the key: \(statusCode).")
                sendRemaining = false
                
                YKFSCardReleaseContext(context)
                transmitRecvBuffer.deallocate()
                return
            }
        }
        
        if readBuffer.count == 0 {
            log(message: "Could not read the certificate from the slot. The slot seems to be empty.")
            
            YKFSCardReleaseContext(context)
            transmitRecvBuffer.deallocate()
            return
        }
        
        /*
         7.2 Parse the certificate object.
         */
        
        guard let certificate = RawDemoSecCertificate(keyData: readBuffer) else {
            log(message: "Could not create a certificate with the data returned from the key.")
            
            YKFSCardReleaseContext(context)
            transmitRecvBuffer.deallocate()
            return
        }
        
        /*
         7.3 Use the certificate to verify a signature.
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
            
            YKFSCardReleaseContext(context)
            transmitRecvBuffer.deallocate()
            return
        }
        
        let signedData = signedString.data(using: String.Encoding.utf8)!
        
        let signatureIsValid = certificate.verify(data: signedData, signature: signatureData!)
        log(message:signatureIsValid ? "Signature is valid." : "Signature is not valid.")
        
        /*
         8. Disconnect from the card.
         */
        
        // Temporary disable the observation to not wipe the logs after the card was disconnected.
        observeSessionStateUpdates = false
        
        result = YKFSCardDisconnect(card, YKF_SCARD_LEAVE_CARD)
        
        if result != YKF_SCARD_S_SUCCESS {
            log(message:"Could not disconnect from the key.")
        }
        
        observeSessionStateUpdates = true
        
        /*
         9. Clear buffers and release the context.
         */
        
        transmitRecvBuffer.deallocate()
        YKFSCardReleaseContext(context)
    }
    
    // MARK: - Session State Updates
    
    override func accessorySessionStateDidChange() {
        let sessionState = YubiKitManager.shared.accessorySession.sessionState        
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
