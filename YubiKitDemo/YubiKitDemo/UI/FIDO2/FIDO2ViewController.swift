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

class FIDO2ViewController: MFIKeyInteractionViewController, UITextFieldDelegate {
    
    private enum FIDO2ViewControllerNextAction {
        case none
        case register
        case authenticate
    }
    private var nextAction: FIDO2ViewControllerNextAction = .none
    
    private let webauthnService = WebAuthnService()
    
    // MARK: - Outlets
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var keyInfoLabel: UILabel!
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Make sure the session is started (in case it was closed by another demo).
            YubiKitManager.shared.keySession.startSession()
        
            updateKeyInfo()
        
            // Enable state observation (see MFIKeyInteractionViewController)
            observeSessionStateUpdates = true
            observeFIDO2ServiceStateUpdates = true
        } else {
            present(message: "This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Disable state observation (see MFIKeyInteractionViewController)
            observeSessionStateUpdates = false
            observeFIDO2ServiceStateUpdates = false
        
            YubiKitManager.shared.keySession.cancelCommands()
        }
    }

    // MARK: - Actions

    @IBAction func actionButtonPressed(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            requestRegistration()
        } else {
            requestAuthentication()
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            actionButton.setTitle("Register", for: .normal)
        } else {
            actionButton.setTitle("Authenticate", for: .normal)
        }
    }
    
    @IBAction func didTapBackground(_ sender: Any) {
        view.endEditing(true)
    }
    
    override func mfiKeyActionSheetDidDismiss(_ actionSheet: MFIKeyActionSheetView) {
        super.mfiKeyActionSheetDidDismiss(actionSheet)
        nextAction = .none
        
        webauthnService.cancelAllRequests()
        YubiKitManager.shared.keySession.cancelCommands()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            passwordTextField.resignFirstResponder()
            actionButtonPressed(actionButton as Any)
        }
        return false
    }
    
    // MARK: - State Observation
    
    override func keySessionStateDidChange() {
        let state = YubiKitManager.shared.keySession.sessionState
        if state == .open {
            // The key session is ready to be used.
            switch nextAction {
            case .register:
                requestRegistration()
                nextAction = .none
            case .authenticate:
                requestAuthentication()
                nextAction = .none
            case .none:
                break
            }
            updateKeyInfo()
        }
        else if state == .closing {
            // The key session will close soon.
            webauthnService.cancelAllRequests()
            dismissMFIKeyActionSheet()
            updateKeyInfo()
        }
    }
    
    override func fido2ServiceStateDidChange() {
        guard let fido2Service = YubiKitManager.shared.keySession.fido2Service else {
            return
        }
        if fido2Service.keyState == .touchKey {
            presentMFIKeyActionSheetOnMain(state: .touchKey, message: "Touch the key to complete the operation.")
        }
    }

    // MARK: - Registration
    
    private func requestRegistration() {
        guard !usernameTextField.text!.isEmpty && !passwordTextField.text!.isEmpty else {
            present(message: "Enter the username and the password to register a new account.")
            return
        }
        view.endEditing(true)
        
        guard YubiKitManager.shared.keySession.sessionState == .open else {
            nextAction = .register
            presentMFIKeyActionSheetOnMain(state: .insertKey, message: "Insert the key to register a new account.")
            return
        }
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        let createRequest = WebAuthnUserRequest(username: username, password: password, type: .create)
        
        presentMFIKeyActionSheetOnMain(state: .processing, message: "Creating account...")
        
        webauthnService.createUserWith(request: createRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissActionSheetAndPresent(error: error!)
                return
            }
            guard let response = response else {
                fatalError()
            }
            
            let uuid = response.uuid
            let registerBeginRequest = WebAuthnRegisterBeginRequest(uuid: uuid)
            
            self.presentMFIKeyActionSheetOnMain(state: .processing, message: "Requesting to add a new authenticator...")
            
            self.webauthnService.registerBeginWith(request: registerBeginRequest) { [weak self] (response, error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.dismissActionSheetAndPresent(error: error!)
                    return
                }
                guard let response = response else {
                    fatalError()
                }
                
                self.handleRegistration(response: response, uuid: uuid)
            }
        }
    }

    /*
     This is an important code snippet for building and executing a FIDO2 Make Credential request.
     */
    private func handleRegistration(response: WebAuthnRegisterBeginResponse, uuid: String){
        /*
         Build the Make Credential request from the server response.
         */
        let makeCredentialRequest = YKFKeyFIDO2MakeCredentialRequest()
        
        guard let challengeData = Data(base64Encoded: response.challenge) else {
            return
        }
        guard let clientData = YKFWebAuthnClientData(type: .create, challenge:challengeData, origin: WebAuthnService.origin) else {
            return
        }
        let clientDataJSON = clientData.jsonData!
        let requestId = response.requestId
        let registerBeginResponse = response
        
        makeCredentialRequest.clientDataHash = clientData.clientDataHash!
        
        let rp = YKFFIDO2PublicKeyCredentialRpEntity()
        rp.rpId = response.rpId
        rp.rpName = response.rpName
        makeCredentialRequest.rp = rp
        
        let user = YKFFIDO2PublicKeyCredentialUserEntity()
        user.userId = Data(base64Encoded: response.userId)!
        user.userName = response.username
        makeCredentialRequest.user = user
        
        let param = YKFFIDO2PublicKeyCredentialParam()
        param.alg = response.pubKeyAlg
        makeCredentialRequest.pubKeyCredParams = [param]
        
        let makeOptions = [YKFKeyFIDO2MakeCredentialRequestOptionRK: response.residentKey]
        makeCredentialRequest.options = makeOptions
        
        /*
         Execute the Make Credential request.
         */
        guard let fido2Service = YubiKitManager.shared.keySession.fido2Service else {
            return
        }
        fido2Service.execute(makeCredentialRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.handleMakeCredential(error: error!, response: registerBeginResponse, uuid: uuid)
                return
            }
            
            // The reponse from the key must not be empty at this point.
            guard let response = response else {
                fatalError()
            }
            self.finalizeRegistration(response: response, uuid: uuid, requestId: requestId, clientDataJSON: clientDataJSON)
        }
    }

    private func finalizeRegistration(response: YKFKeyFIDO2MakeCredentialResponse, uuid: String, requestId: String, clientDataJSON: Data) {
        presentMFIKeyActionSheetOnMain(state: .processing, message: "Adding authenticator to the account...")

        let attestationObject = response.webauthnAttestationObject
        
        // Send back the response to the server.
        let registerFinishRequest = WebAuthnRegisterFinishRequest(uuid: uuid,
                                                                  requestId: requestId,
                                                                  clientDataJSON: clientDataJSON,
                                                                  attestationObject: attestationObject)
        
        webauthnService.registerFinishWith(request: registerFinishRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissActionSheetAndPresent(error: error!)
                return
            }
            self.dismissActionSheetAndPresent(message: "The registration was successful. The account will be valid for 24h.")
        }
    }
    
    // MARK: - Authentication

    private func requestAuthentication() {
        guard !usernameTextField.text!.isEmpty && !passwordTextField.text!.isEmpty else {
            present(message: "Enter the username and the password to authenticate.")
            return
        }
        view.endEditing(true)
        
        guard YubiKitManager.shared.keySession.sessionState == .open else {
            nextAction = .authenticate
            presentMFIKeyActionSheetOnMain(state: .insertKey, message: "Insert the key to authenticate.")
            return
        }
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        let loginRequest = WebAuthnUserRequest(username: username, password: password, type: .login)
        
        presentMFIKeyActionSheetOnMain(state: .processing, message: "Authenticating...")
        
        webauthnService.loginUserWith(request: loginRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissActionSheetAndPresent(error: error!)
                return
            }
            guard let response = response else {
                fatalError()
            }
            
            let uuid = response.uuid
            let authenticateBeginRequest = WebAuthnAuthenticateBeginRequest(uuid: uuid)
            
            self.presentMFIKeyActionSheetOnMain(state: .processing, message: "Requesting for authenticator challenge...")
            
            self.webauthnService.authenticateBeginWith(request: authenticateBeginRequest) { [weak self] (response, error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.dismissActionSheetAndPresent(error: error!)
                    return
                }
                guard let response = response else {
                    fatalError()
                }
                
                self.handleAuthentication(response: response, uuid: uuid)
            }
        }
    }
    
    /*
     This is an important code snippet for building and executing a FIDO2 Get Assertion request.
     */
    private func handleAuthentication(response: WebAuthnAuthenticateBeginResponse, uuid: String){
        /*
         Build the Get Assertion request from the server response.
         */
        let getAssertionRequest = YKFKeyFIDO2GetAssertionRequest()

        guard let challengeData = Data(base64Encoded: response.challenge) else {
            return
        }
        guard let clientData = YKFWebAuthnClientData(type: .get, challenge:challengeData, origin: WebAuthnService.origin) else {
            return
        }
        let clientDataJSON = clientData.jsonData!
        let requestId = response.requestId
        let authenticateBeginResponse = response
        
        getAssertionRequest.rpId = response.rpID
        getAssertionRequest.clientDataHash = clientData.clientDataHash!
        getAssertionRequest.options = [YKFKeyFIDO2GetAssertionRequestOptionUP: true]
        
        var allowList = [YKFFIDO2PublicKeyCredentialDescriptor]()
        for credentialId in response.allowCredentials {
            let credentialDescriptor = YKFFIDO2PublicKeyCredentialDescriptor()
            credentialDescriptor.credentialId = Data(base64Encoded: credentialId)!
            let credType = YKFFIDO2PublicKeyCredentialType()
            credType.name = "public-key"
            credentialDescriptor.credentialType = credType
            allowList.append(credentialDescriptor)
        }
        getAssertionRequest.allowList = allowList
        
        /*
         Execute the Get Assertion request.
         */
        guard let fido2Service = YubiKitManager.shared.keySession.fido2Service else {
            fatalError()
        }
        fido2Service.execute(getAssertionRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.handleGetAssertion(error: error!, response: authenticateBeginResponse, uuid: uuid)
                return
            }

            // The reponse from the key must not be empty at this point.
            guard let response = response else {
                fatalError()
            }
            self.finalizeAuthentication(response: response, uuid: uuid, requestId: requestId, clientDataJSON: clientDataJSON)
        }
    }

    private func finalizeAuthentication(response: YKFKeyFIDO2GetAssertionResponse, uuid: String, requestId: String, clientDataJSON: Data) {
        presentMFIKeyActionSheetOnMain(state: .processing, message: "Authenticating...")

        let authenticateFinishRequest = WebAuthnAuthenticateFinishRequest(uuid: uuid,
                                                                          requestId: requestId,
                                                                          credentialId: response.credential!.credentialId,
                                                                          authenticatorData: response.authData,
                                                                          clientDataJSON: clientDataJSON,
                                                                          signature: response.signature)
        
        webauthnService.authenticateFinishWith(request: authenticateFinishRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissActionSheetAndPresent(error: error!)
                return
            }
            self.dismissActionSheetAndPresent(message: "The authentication was successful.")
        }
    }
    
    // MARK: - PIN Verification
    
    /*
     1. To set a PIN on the key, the FIDO2 demo on the Other demos tab provides the ability to perform PIN Management.
     2. To remove the PIN, the FIDO2 application must be reset. Once set, the PIN can only be changed.
     */
    private func handlePinVerificationRequired(completion: @escaping (Error?) -> Void ) {
        dispatchMain {
            let pinInputController = FIDO2PinInputController()
            pinInputController.showPinInputController(presenter: self, type: .pin) { [weak self] (pin, _, _, verify) in
                guard let self = self else {
                    return
                }
                guard verify else {
                    self.dismissMFIKeyActionSheet()
                    return
                }
                guard let pin = pin else {
                    self.dismissActionSheetAndPresent(message: "The PIN is empty.")
                    return
                }
                
                guard let fido2Service = YubiKitManager.shared.keySession.fido2Service else {
                    return
                }
                guard let verifyPinRequest = YKFKeyFIDO2VerifyPinRequest(pin: pin) else {
                    self.dismissActionSheetAndPresent(message: "Could not create the request to verify the PIN.")
                    return
                }
                
                self.presentMFIKeyActionSheetOnMain(state: .processing, message: "Verifying PIN...")
                
                fido2Service.execute(verifyPinRequest) { (error) in
                    completion(error)
                }
            }
        }
    }
    
    private func handleMakeCredential(error: Error, response: WebAuthnRegisterBeginResponse, uuid: String) {
        let makeCredentialError = error as NSError
        
        guard makeCredentialError.code == YKFKeyFIDO2ErrorCode.PIN_REQUIRED.rawValue else {
            self.dismissActionSheetAndPresent(error: makeCredentialError)
            return
        }
        
        // PIN verification is required for the Make Credential request.
        self.dismissMFIKeyActionSheetOnMain()
        self.handlePinVerificationRequired { [weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissActionSheetAndPresent(error: error!)
                return
            }
            self.handleRegistration(response: response, uuid: uuid)
        }
    }
    
    private func handleGetAssertion(error: Error, response: WebAuthnAuthenticateBeginResponse, uuid: String) {
        let getAssertionError = error as NSError
        
        guard getAssertionError.code == YKFKeyFIDO2ErrorCode.PIN_REQUIRED.rawValue else {
            self.dismissActionSheetAndPresent(error: getAssertionError)
            return
        }
        
        // PIN verification is required for the Get Assertion request.
        self.dismissMFIKeyActionSheetOnMain()
        self.handlePinVerificationRequired { [weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissActionSheetAndPresent(error: error!)
                return
            }
            self.handleAuthentication(response: response, uuid: uuid)
        }
    }
    
    // MARK: - Helpers
    
    private func updateKeyInfo() {
        guard YubiKitManager.shared.keySession.sessionState == .open else {
            keyInfoLabel.text = nil
            return
        }        
        guard let keyDescription = YubiKitManager.shared.keySession.keyDescription else {
            keyInfoLabel.text = nil
            return
        }
        
        var keyInfoText = ""
        if keyDescription.serialNumber.isEmpty {
            keyInfoText = "- Key info -\nFirmware: \(keyDescription.firmwareRevision)"
        } else {
            keyInfoText = "- Key info -\nSerial: \(keyDescription.serialNumber), Firmware: \(keyDescription.firmwareRevision)"
        }
        keyInfoLabel.text = keyInfoText
    }
    
    private func dispatchMain(execute: @escaping ()->Void) {
        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.async(execute: execute)
        }
    }
    
    private func presentMFIKeyActionSheetOnMain(state: MFIKeyInteractionViewControllerState, message: String) {
        dispatchMain { [weak self] in
            self?.presentMFIKeyActionSheet(state: state, message: message)
        }
    }

    private func dismissMFIKeyActionSheetOnMain() {
        dispatchMain { [weak self] in
            self?.dismissMFIKeyActionSheet(delayed: false)
        }
    }
    
    private func dismissActionSheetAndPresent(error: Error) {
        dispatchMain { [weak self] in
            self?.dismissMFIKeyActionSheetAndShow(message: error.localizedDescription)
        }
    }
    
    private func dismissActionSheetAndPresent(message: String) {
        dispatchMain { [weak self] in
            self?.dismissMFIKeyActionSheetAndShow(message: message)
        }
    }
}
