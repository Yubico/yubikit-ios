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

class FIDO2DemoViewController: OtherDemoRootViewController {

    // MARK: - Outlets
    
    @IBOutlet var logTextView: UITextView!
    
    @IBOutlet var runDemoButton: UIButton!
    @IBOutlet var pinManagementButton: UIButton!
    
    // MARK: - Actions
    
    @IBAction func runDemoButtonPressed(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Run Demo", message: "Select which demo you want to run.", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Get Info Demo", style: .default) { [weak self]  (action) in
            self?.runGetInfoDemo()
        })
        actionSheet.addAction(UIAlertAction(title: "ECC Demo: ES256, non-RK, UP", style: .default) { [weak self]  (action) in
            self?.runECCDemo()
        })
        actionSheet.addAction(UIAlertAction(title: "EdDSA Demo: Ed25519, RK, no UP", style: .default) { [weak self] (action) in
            self?.runEdDSADemo()
        })
        actionSheet.addAction(UIAlertAction(title: "Reset FIDO2 Application", style: .destructive) { [weak self] (action) in
            self?.runApplicationReset()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            self?.dismiss(animated: true, completion: nil)
        })
        
        // The action sheet requires a presentation popover on iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.modalPresentationStyle = .popover
            if let presentationController = actionSheet.popoverPresentationController {
                presentationController.sourceView = runDemoButton
                presentationController.sourceRect = runDemoButton.bounds
            }
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func pinManagementButtonPressed(_ sender: Any) {
        let actionSheet = UIAlertController(title: "PIN Management", message: "Select the PIN action you want to run.", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Verify PIN", style: .default) { [weak self]  (action) in
            self?.runVerifyPin()
        })
        actionSheet.addAction(UIAlertAction(title: "Set PIN", style: .default) { [weak self]  (action) in
            self?.runSetPin()
        })
        actionSheet.addAction(UIAlertAction(title: "Change PIN", style: .default) { [weak self]  (action) in
            self?.runChangePin()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            self?.dismiss(animated: true, completion: nil)
        })
        
        // The action sheet requires a presentation popover on iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.modalPresentationStyle = .popover
            if let presentationController = actionSheet.popoverPresentationController {
                presentationController.sourceView = pinManagementButton
                presentationController.sourceRect = pinManagementButton.bounds
            }
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func setDemoButtons(enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.runDemoButton.isEnabled = enabled
            self.runDemoButton.backgroundColor = enabled ? NamedColor.yubicoGreenColor : UIColor.lightGray
            
            self.pinManagementButton.isEnabled = enabled
            self.pinManagementButton.backgroundColor = enabled ? NamedColor.yubicoGreenColor : UIColor.lightGray
        }
    }
    
    // MARK: - Verify PIN
    
    private func runVerifyPin() {
        logTextView.text = nil
        setDemoButtons(enabled: false)

        let accessorySession = YubiKitManager.shared.accessorySession
        guard accessorySession.sessionState == .open else {
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            setDemoButtons(enabled: true)
            return
        }
        
        let pinInputController = FIDO2PinInputController()
        pinInputController.showPinInputController(presenter: self, type: .pin) { [weak self](pin, _, _, verifyPin) in
            guard let self = self else {
                return
            }
            if verifyPin {
                if pin != nil {
                    self.verify(pin: pin!)
                    return
                } else {
                    self.log(message: "Cannot verify PIN: PIN value must be provided.")
                }
            }
            self.log(message: "PIN verification canceled.")
            self.setDemoButtons(enabled: true)
        }
    }
    
    private func verify(pin: String) {
        let accessorySession = YubiKitManager.shared.accessorySession
        guard let fido2Service = accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            return
        }
                
        fido2Service.executeGetPinRetries { [weak self] (retries, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Get PIN Retries: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            if retries == 0 {
                self.log(message: "No more retries for PIN.")
                self.setDemoButtons(enabled: true)
                return
            }
            self.log(message: "PIN retries left: \(retries)")
            
            guard let verifyPinRequest = YKFKeyFIDO2VerifyPinRequest(pin: pin) else {
                return
            }
            fido2Service.execute(verifyPinRequest) { [weak self] (error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.log(message: "Error while executing Verify PIN request: \((error! as NSError).code) - \(error!.localizedDescription)")
                    self.setDemoButtons(enabled: true)
                    return
                }
                
                self.log(message: "Verify PIN request was successful.")
                self.setDemoButtons(enabled: true)
            }
        }
    }
    
    // MARK: - Set PIN
    
    private func runSetPin() {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        let accessorySession = YubiKitManager.shared.accessorySession
        guard accessorySession.sessionState == .open else {
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            setDemoButtons(enabled: true)
            return
        }
        
        let pinInputController = FIDO2PinInputController()
        pinInputController.showPinInputController(presenter: self, type: .setPin) { [weak self](pin, pinConfirmation, _, setPin) in
            guard let self = self else {
                return
            }
            if setPin {
                if pin != nil && pinConfirmation != nil && (pin == pinConfirmation) {
                    self.set(pin: pin!)
                    return
                } else {
                    self.log(message: "Cannot set PIN: PIN value must be provided and values must match.")
                }
            }
            self.log(message: "PIN verification canceled.")
            self.setDemoButtons(enabled: true)
        }
    }
    
    private func set(pin: String) {
        let accessorySession = YubiKitManager.shared.accessorySession
        guard let fido2Service = accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            return
        }
        
        guard let setPinRequest = YKFKeyFIDO2SetPinRequest(pin: pin) else {
            return
        }
        fido2Service.execute(setPinRequest) { [weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Set PIN request: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            
            self.log(message: "Set PIN request was successful.")
            
            self.setDemoButtons(enabled: true)
        }
    }
    
    // MARK: - Change PIN
    
    private func runChangePin() {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        let accessorySession = YubiKitManager.shared.accessorySession
        
        guard accessorySession.sessionState == .open else {
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            setDemoButtons(enabled: true)
            return
        }
        
        let pinInputController = FIDO2PinInputController()
        pinInputController.showPinInputController(presenter: self, type: .changePin) { [weak self](oldPin, newPin, newPinConfirmation, changePin) in
            guard let self = self else {
                return
            }
            if changePin {
                if oldPin != nil && newPin != nil && newPinConfirmation != nil && (newPin == newPinConfirmation) {
                    self.change(to: newPin!, oldPin: oldPin!)
                    return
                } else {
                    self.log(message: "Cannot change PIN: Old and new PIN values must be provided and new values must match.")
                }
            }
            self.log(message: "PIN change canceled.")
            self.setDemoButtons(enabled: true)
        }
    }
    
    private func change(to newPin: String, oldPin: String) {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        let accessorySession = YubiKitManager.shared.accessorySession
        
        guard accessorySession.sessionState == .open else {
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            setDemoButtons(enabled: true)
            return
        }
        guard let fido2Service = accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            return
        }
        
        guard let changePinRequest = YKFKeyFIDO2ChangePinRequest(newPin: newPin, oldPin: oldPin) else {
            return
        }
        fido2Service.execute(changePinRequest) { [weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Change PIN request: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            
            self.log(message: "Change PIN request was successful.")
            
            self.setDemoButtons(enabled: true)
        }
    }
    
    // MARK: - GetInfo Demo
    
    private func runGetInfoDemo() {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        let accessorySession = YubiKitManager.shared.accessorySession
        
        guard accessorySession.sessionState == .open else {
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            setDemoButtons(enabled: true)
            return
        }
        guard let fido2Service = accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            return
        }
        
        log(message: "Executing Get Info request...")
        fido2Service.executeGetInfoRequest { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Get Info request: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            
            self.log(message: "Get Info request was successful.\n")
            self.logFIDO2GetInfo(response: response!)
            
            self.setDemoButtons(enabled: true)
        }
    }
    
    // MARK: - ES256, EdDSA Demos
    
    private func runECCDemo() {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        log(message: "Executing ECC Demo...")
        log(message: "(!) Touch the key when the LEDs are blinking slowly.")
        
        // Not a resident key (stored on the authenticator) and no PIN required.
        let makeOptions = [YKFKeyFIDO2MakeCredentialRequestOptionRK: false]
        
        // User presence required (touch) but not user verification (PIN).
        let assertionOptions = [YKFKeyFIDO2GetAssertionRequestOptionUP: true]
        
        makeFIDO2CredentialWith(algorithm:YKFFIDO2PublicKeyAlgorithmES256, makeOptions: makeOptions, assertionOptions: assertionOptions)
    }
    
    private func runEdDSADemo() {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        log(message: "Executing EdDSA (Ed25519) Demo...")
        log(message: "(!) Touch the key when the LEDs are blinking slowly.")
        
        // Resident key (stored on the authenticator) and no PIN required.
        let makeOptions = [YKFKeyFIDO2MakeCredentialRequestOptionRK: true]
        
        // User presence and verification disabled (silent authentication).
        let assertionOptions = [YKFKeyFIDO2GetAssertionRequestOptionUP: false]
        
        makeFIDO2CredentialWith(algorithm:YKFFIDO2PublicKeyAlgorithmEdDSA, makeOptions: makeOptions, assertionOptions: assertionOptions)
    }
    
    private func makeFIDO2CredentialWith(algorithm: NSInteger, makeOptions: [String: Bool], assertionOptions: [String: Bool]) {
        guard let fido2Service = YubiKitManager.shared.accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            return
        }
        
        /*
         1. Setup the Make Credential request.
         */
        
        let makeCredentialRequest = YKFKeyFIDO2MakeCredentialRequest()
        
        let data = Data(repeating: 0, count: 32)
        makeCredentialRequest.clientDataHash = data
        
        let rp = YKFFIDO2PublicKeyCredentialRpEntity()
        rp.rpId = "yubico.com"
        rp.rpName = "Yubico"
        makeCredentialRequest.rp = rp
        
        let user = YKFFIDO2PublicKeyCredentialUserEntity()
        user.userId = data
        user.userName = "johnpsmith@yubico.com"
        user.userDisplayName = "John P. Smith"
        makeCredentialRequest.user = user

        let param = YKFFIDO2PublicKeyCredentialParam()
        param.alg = algorithm
        makeCredentialRequest.pubKeyCredParams = [param]
  
        makeCredentialRequest.options = makeOptions
        
        /*
         2. Create the credential.
         */
        
        fido2Service.execute(makeCredentialRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Make Credential request: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            guard let authenticatorData = response!.authenticatorData else {
                self.setDemoButtons(enabled: true)
                return
            }
            
            self.log(message: "Make Credential was successful.\n")
            self.logFIDO2MakeCredential(response: response!)
            
            /*
             3. Setup the Get Assertion request.
             */
            
            let getAssertionRequest = YKFKeyFIDO2GetAssertionRequest()
            
            getAssertionRequest.rpId = "yubico.com"
            getAssertionRequest.clientDataHash = data
            getAssertionRequest.options = assertionOptions
            
            let credentialDescriptor = YKFFIDO2PublicKeyCredentialDescriptor()
            credentialDescriptor.credentialId = authenticatorData.credentialId!
            let credType = YKFFIDO2PublicKeyCredentialType()
            credType.name = "public-key"
            credentialDescriptor.credentialType = credType
            getAssertionRequest.allowList = [credentialDescriptor]
            
            /*
             4. Get the assertion (signature).
             */
            
            self.getAssertionWith(request: getAssertionRequest)
        }
    }
    
    private func getAssertionWith(request: YKFKeyFIDO2GetAssertionRequest) {
        guard let fido2Service = YubiKitManager.shared.accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            return
        }
        
        fido2Service.execute(request) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Get Assertion request: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            
            self.log(message: "Get Assertion was successful.\n")
            self.logFIDO2GetAssertion(response: response!)
            
            self.setDemoButtons(enabled: true)
        }
    }
    
    // MARK: - FIDO2 Application Reset
    
    private func runApplicationReset() {
        logTextView.text = nil
        setDemoButtons(enabled: false)
        
        let accessorySession = YubiKitManager.shared.accessorySession
        
        guard accessorySession.sessionState == .open else {
            log(message: "The session with the key is closed. Plugin the key before running the demo.")
            setDemoButtons(enabled: true)
            return
        }
        guard let fido2Service = accessorySession.fido2Service else {
            setDemoButtons(enabled: true)
            return
        }
        
        log(message: "(!) The Reset operation must be executed within 5 seconds after the key was powered up. Otherwise the key will return an error.")
        log(message: "")
        log(message: "Executing Reset request...")
        log(message: "(!) Touch the key when the LEDs are blinking slowly.")
        
        fido2Service.executeResetRequest { [weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.log(message: "Error while executing Reset request: \((error! as NSError).code) - \(error!.localizedDescription)")
                self.setDemoButtons(enabled: true)
                return
            }
            
            self.log(message: "Reset request was successful.")
            self.setDemoButtons(enabled: true)
        }
    }
    
    // MARK: - Session State Updates
    
    override func accessorySessionStateDidChange() {
        let sessionState = YubiKitManager.shared.accessorySession.sessionState
        if sessionState == .closed {
            logTextView.text = nil
            setDemoButtons(enabled: true)
        }
    }
    
    // MARK: - FIDO2 Response Log Helpers
    
    private func logFIDO2GetInfo(response: YKFKeyFIDO2GetInfoResponse) {
        log(header: "Get Info response")
        
        log(tag: "Versions", value: response.versions.description)
        log(tag: "AAGUID", value: response.aaguid.hexDescription())

        if response.extensions != nil {
            log(tag: "Extensions", value: response.extensions!.description)
        }
        if response.options != nil {
            log(tag: "Options", value: response.options!.description)
        }
        if response.pinProtocols != nil {
            log(tag: "PIN protocols", value: response.pinProtocols!.description)
        }
        if response.maxMsgSize != 0 {
            log(tag: "Max message size", value: "\(response.maxMsgSize)")
        }
    }
    
    private func logFIDO2MakeCredential(response: YKFKeyFIDO2MakeCredentialResponse) {
        log(header: "Make credential response")
        
        log(tag: "Authenticator data", value: response.authData.hexDescription())
        log(tag: "Attestation statement format identifier", value: response.fmt)
        log(tag: "Attestation statement", value: response.attStmt.hexDescription())
        
        if let authenticatorData = response.authenticatorData {
            log(tag: "authenticatorData.rpIdHash", value: authenticatorData.rpIdHash.hexDescription())
            log(tag: "authenticatorData.flags", value: "\(authenticatorData.flags)")
            log(tag: "authenticatorData.signCount", value: "\(authenticatorData.signCount)")
            log(tag: "authenticatorData.aaguid", value: authenticatorData.aaguid?.hexDescription() ?? "?")
            log(tag: "authenticatorData.credentialId", value: authenticatorData.credentialId?.hexDescription() ?? "?")
            log(tag: "authenticatorData.coseEncodedCredentialPublicKey", value: authenticatorData.coseEncodedCredentialPublicKey?.hexDescription() ?? "?")
        }
    }
    
    private func logFIDO2GetAssertion(response: YKFKeyFIDO2GetAssertionResponse) {
        log(header: "Get Assertion response")

        if let credential = response.credential {
            log(tag: "credential.credentialId", value: credential.credentialId.hexDescription())
            log(tag: "credential.credentialType", value: credential.credentialType.name)
            
            if let transports = credential.credentialTransports {
                log(tag: "Transports", value: transports.description)
            }
        }

        log(tag: "Auth Data", value: response.authData.hexDescription())
        log(tag: "Signature", value: response.signature.hexDescription())
        
        if let user = response.user {
            log(tag: "User.id", value: user.userId.hexDescription())
            log(tag: "User.name", value: user.userName ?? "?")
            log(tag: "User.displayName", value: user.userDisplayName ?? "?")
            log(tag: "User.icon", value: user.userIcon ?? "?")
        }
        
        if response.numberOfCredentials != 0 {
            log(tag: "Number of credentials", value: "\(response.numberOfCredentials)")
        }
    }
    
    // MARK: - Log Helpers
    
    private func log(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            print(message)
            self.logTextView.insertText("\(message)\n")
            
            let bottom = self.logTextView.contentSize.height - self.logTextView.bounds.size.height
            if bottom > 0 {
                self.logTextView.setContentOffset(CGPoint(x:0, y:bottom), animated: true)
            }
        }
    }
    
    private func logSepparator() {
        log(message: "-- -- -- -- -- -- -- -- -- -- -- -- --")
    }
    
    private func log(header: String) {
        logSepparator()
        log(message: header)
        logSepparator()
    }
    
    private func log(tag: String, value: String) {
        log(message: "\n* \(tag):\n\(value)")
    }
}
