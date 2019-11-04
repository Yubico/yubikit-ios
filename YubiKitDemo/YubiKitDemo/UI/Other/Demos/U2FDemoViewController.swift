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
    
    @IBAction func runDemoButtonPressed(_ sender: Any) {
        let challenge = "D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc"
        let appId = "https://demo.yubico.com"
        
        logTextView.text = nil
        setDemoButton(enabled: false)
        
        executeRegisterRequestWith(challenge: challenge, appId: appId) { [weak self] (keyHandle) in
            guard let self = self else {
                return
            }
            guard let keyHandle = keyHandle else {
                self.log(message: "The Register request did not return a key handle.")
                self.setDemoButton(enabled: true)
                return
            }
            
            self.log(message: "The Register request was successful with key handle: \(keyHandle)")
            
            self.executeSignRequestWith(keyHandle: keyHandle, challenge: challenge, appId: appId, completion: { [weak self] (success) in
                guard let self = self else {
                    return
                }
                guard success else {
                    self.log(message: "The Sign request did not return a signature.")
                    self.setDemoButton(enabled: true)
                    return
                }
                self.log(message: "The Sign request was successful.")
                self.setDemoButton(enabled: true)
            })
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

    // MARK: - Session State Updates
    
    override func accessorySessionStateDidChange() {
        let sessionState = YubiKitManager.shared.accessorySession.sessionState
        if sessionState == .closed {
            logTextView.text = nil
            setDemoButton(enabled: true)
        }
    }
    
    // MARK: - Helpers

    private func executeRegisterRequestWith(challenge: String, appId: String, completion: @escaping (String?) -> Void) {
        guard let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId) else {
            log(message: "Could not create the Register request.")
            completion(nil)
            return
        }
        guard let u2fService = YubiKitManager.shared.accessorySession.u2fService else {
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
    
    private func executeSignRequestWith(keyHandle: String, challenge: String, appId: String, completion: @escaping (Bool) -> Void) {
        guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId) else {
            log(message: "Could not create the Sign request.")
            completion(false)
            return
        }
        guard let u2fService = YubiKitManager.shared.accessorySession.u2fService else {
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
