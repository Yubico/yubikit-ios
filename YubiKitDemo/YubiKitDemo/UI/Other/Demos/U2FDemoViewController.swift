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

class U2FDemoViewController: OtherDemoRootViewController {

    // MARK: - Outlets
    
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var runDemoButton: UIButton!
    
    // MARK: - Actions
    
    enum DemoName {
        case GetInfo
        case EccDemo
        case EdDSADemo
        case Reset
        case PinVerify
        case PinSet
        case PinChange
    }
    
    private var selectedOperation: DemoName?

    @IBAction func runDemoButtonPressed(_ sender: Any) {
        
        logTextView.text = nil
        setDemoButton(enabled: false)
        
        YubiKitExternalLocalization.nfcScanAlertMessage = "Insert YubiKey or scan over the top edge of your iPhone";
        let keyConnected = YubiKitManager.shared.accessorySession.sessionState == .open

        if YubiKitDeviceCapabilities.supportsISO7816NFCTags && !keyConnected {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            YubiKitManager.shared.nfcSession.startIso7816Session()
        } else {
            logTextView.text = nil
            setDemoButton(enabled: false)

            DispatchQueue.global(qos: .default).async { [weak self] in
               guard let self = self else {
                   return
               }
               self.runDemo(keyService: YubiKitManager.shared.accessorySession.u2fService)
               self.setDemoButton(enabled: true)
           }
        }
    }
    
    private func runDemo(keyService: YKFKeyU2FServiceProtocol?) {
        let challenge = "D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc"
        let appId = "https://demo.yubico.com"

        executeRegisterRequestWith(keyService: keyService, challenge: challenge, appId: appId) { [weak self] (keyHandle) in
            guard let self = self else {
                return
            }
            guard let keyHandle = keyHandle else {
                self.log(message: "The Register request did not return a key handle.")
                self.finishDemo()
                return
            }
            
            self.log(message: "The Register request was successful with key handle: \(keyHandle)")
            
            self.executeSignRequestWith(keyService: keyService, keyHandle: keyHandle, challenge: challenge, appId: appId, completion: { [weak self] (success) in
                guard let self = self else {
                    return
                }
                self.finishDemo()

                guard success else {
                    self.log(message: "The Sign request did not return a signature.")
                    return
                }
                self.log(message: "The Sign request was successful.")
            })
        }
    }
    
    private func finishDemo() {

        // Stop the session to dismiss the Core NFC system UI.
        if #available(iOS 13.0, *) {
            YubiKitManager.shared.nfcSession.stopIso7816Session()
        }
        
        self.setDemoButton(enabled: true)
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

    // MARK: - Session State Updates
    override func accessorySessionStateDidChange() {
        let sessionState = YubiKitManager.shared.accessorySession.sessionState
        if sessionState == .closed {
            logTextView.text = nil
            setDemoButton(enabled: true)
        } else if sessionState == .open {
            if YubiKitDeviceCapabilities.supportsISO7816NFCTags {
                guard #available(iOS 13.0, *) else {
                    fatalError()
                }
            
                DispatchQueue.global(qos: .default).async { [weak self] in
                    // if NFC UI is visible we consider the button is pressed
                    // and we run demo as soon as 5ci connected
                    if (YubiKitManager.shared.nfcSession.iso7816SessionState != .closed) {
                        guard let self = self else {
                                return
                        }
                        YubiKitManager.shared.nfcSession.stopIso7816Session()
                        self.runDemo(keyService: YubiKitManager.shared.accessorySession.u2fService)
                    }
                }
            }
        }
    }

    @available(iOS 13.0, *)
    override func nfcSessionStateDidChange() {
        // Execute the request after the key(tag) is connected.
        switch YubiKitManager.shared.nfcSession.iso7816SessionState {
        case .open:
            DispatchQueue.global(qos: .default).async { [weak self] in
                guard let self = self else {
                    return
                }
                
                // NOTE: session can be closed during the execution of demo on background thread,
                // so we need to make sure that we handle case when service for nfcSession is nil
                self.runDemo(keyService: YubiKitManager.shared.nfcSession.u2fService)
            }
        case .closed:
            self.setDemoButton(enabled: true)
        default:
            break
        }
    }

    // MARK: - Helpers

    private func executeRegisterRequestWith(keyService: YKFKeyU2FServiceProtocol?, challenge: String, appId: String, completion: @escaping (String?) -> Void) {
        guard let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId) else {
            log(message: "Could not create the Register request.")
            completion(nil)
            return
        }
        guard let u2fService = keyService else {
            log(message: "The U2F service is not available (the session is closed or the key is not connected).")
            completion(nil)
            return
        }
        
        self.log(message: "Executing the Register request...")
        self.log(message: "(!)Touch the key when it's blinking slowly.")
        
        u2fService.execute(registerRequest) { (response, error) in
            guard error == nil else {
                self.log(message: "Error after executing the Register request: \(error!.localizedDescription)")
                completion(nil)
                return
            }
            guard let registrationData = response?.registrationData else {
                fatalError()
            }
            let keyHandle = U2FDataParser.keyHandleFrom(registrationData: registrationData)
            completion(keyHandle)
        }
    }
    
    private func executeSignRequestWith(keyService: YKFKeyU2FServiceProtocol?, keyHandle: String, challenge: String, appId: String, completion: @escaping (Bool) -> Void) {
        guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId) else {
            log(message: "Could not create the Sign request.")
            completion(false)
            return
        }
        guard let u2fService = keyService else {
            log(message: "The U2F service is not available (the session is closed or the key is not connected).")
            completion(false)
            return
        }
        
        self.log(message: "Executing the Sign request...")
        self.log(message: "(!)Touch the key when it's blinking slowly.")
        
        u2fService.execute(signRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error after executing the Sign request: \(error!.localizedDescription)")
                completion(false)
                return
            }
            guard response != nil else {
                fatalError()
            }
            completion(true)
        }
    }
    
    private func log(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            print(message)
            self.logTextView.insertText("\(message)\n\n")
            
            let bottom = self.logTextView.contentSize.height - self.logTextView.bounds.size.height
            if bottom > 0 {
                self.logTextView.setContentOffset(CGPoint(x:0, y:bottom), animated: true)
            }
        }
    }
}

// MARK: - Demo Helpers

/*
 Small demo helper for extracting the keyHandle from the registration data.
 This is for demo purposes only (to make the demo self-contained). The client should
 not parse this data in a regular scenario. The server will parse the data and send
 back the key handle when a signature is required for authentication.
 */
class U2FDataParser: NSObject {
    
    /*
     Registration raw message format id documented here:
     https://fidoalliance.org/specs/fido-u2f-v1.2-ps-20170411/fido-u2f-raw-message-formats-v1.2-ps-20170411.html
     */
    class func keyHandleFrom(registrationData: Data) -> String? {
        guard registrationData.count >= 66 else {
            return nil
        }
        let registrationDataBytes = [UInt8](registrationData)
        let keyHandleLength = Int(registrationDataBytes[66])
        guard registrationData.count > 67 + keyHandleLength else {
            return nil
        }
        
        let range: Range<Data.Index> = 67..<(67+keyHandleLength)
        let data = registrationData.subdata(in: range)
        
        return (data as NSData).ykf_websafeBase64EncodedString()
    }
}
