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
    
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var runDemoButton: UIButton!

    @IBAction func runDemoButtonPressed(_ sender: Any) {
        logTextView.text = nil
        setDemoButton(enabled: false)
        
        self.connection { connection in
            connection.u2fSession { session, error in
                guard let session = session else {
                    self.log(message: "Failed to create session. Error: \(error!.localizedDescription)")
                    self.finishDemo()
                    return
                }
                
                let challenge = "D2pzTPZa7bq69ABuiGQILo9zcsTURP26RLifTyCkilc"
                let appId = "https://demo.yubico.com"

                self.executeRegisterRequestWith(session: session, challenge: challenge, appId: appId) { keyHandle in
                    guard let keyHandle = keyHandle else {
                        self.log(message: "The Register request did not return a key handle.")
                        self.finishDemo()
                        return
                    }
                    
                    self.log(message: "The Register request was successful with key handle: \(keyHandle)")
                    
                    self.executeSignRequestWith(session: session, keyHandle: keyHandle, challenge: challenge, appId: appId, completion: { success in
                        self.finishDemo()
                        guard success else {
                            self.log(message: "The Sign request did not return a signature.")
                            return
                        }
                        self.log(message: "The Sign request was successful.")
                    })
                }
            }
        }
    }
    
    private func finishDemo() {
        // Stop the session to dismiss the Core NFC system UI.
        if #available(iOS 13.0, *) {
            YubiKitManager.shared.nfcSession.stop()
        }
        self.setDemoButton(enabled: true)
    }
    
    private func setDemoButton(enabled: Bool) {
        DispatchQueue.main.async {
            self.runDemoButton.isEnabled = enabled
            self.runDemoButton.backgroundColor = enabled ? NamedColor.yubicoGreenColor : UIColor.lightGray
        }
    }

    private func executeRegisterRequestWith(session: YKFKeyU2FSession, challenge: String, appId: String, completion: @escaping (String?) -> Void) {
        
        self.log(message: "Running the U2F Register...")
        self.log(message: "Touch the key when it's blinking slowly.")
        
        session.register(withChallenge: challenge, appId: appId) { response, error in
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
    
    private func executeSignRequestWith(session: YKFKeyU2FSession, keyHandle: String, challenge: String, appId: String, completion: @escaping (Bool) -> Void) {
        
        self.log(message: "Running U2F Sign...")
        self.log(message: "Touch the key when it's blinking slowly.")
        
        session.sign(withChallenge: challenge, keyHandle: keyHandle, appId: appId) { response, error in
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
        DispatchQueue.main.async {
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
