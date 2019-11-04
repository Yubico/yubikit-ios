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
    
    private enum FIDO2ViewControllerKeyType {
        case unknown
        case accessory
        case nfc
    }
    private var keyType: FIDO2ViewControllerKeyType = .unknown

    private var nfcSesionStateObservation: NSKeyValueObservation?
    private var sceneObserver: SceneObserver?
    
    // MARK: - Services
    
    /**
     The WS interface to communicate with the Yubico Demo website.
     */
    private let webauthnService = WebAuthnService()
    
    /**
     Returns the service associated with the desired session.
     */
    private var keyFido2Service: YKFKeyFIDO2ServiceProtocol {
        get {
            var fido2Service: YKFKeyFIDO2ServiceProtocol? = nil
            if keyType == .accessory {
                fido2Service = YubiKitManager.shared.accessorySession.fido2Service
            } else {
                guard #available(iOS 13.0, *) else {
                    fatalError()
                }
                fido2Service = YubiKitManager.shared.nfcSession.fido2Service
            }
            guard fido2Service != nil else {
                fatalError()
            }
            return fido2Service!
        }
    }
    
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
            YubiKitManager.shared.accessorySession.startSession()
        
            updateKeyInfo()
        
            // Enable state observation (see MFIKeyInteractionViewController)
            observeAccessorySessionStateUpdates = true
            observeFIDO2ServiceStateUpdates = true
        } else {
            present(message: "This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Disable state observation (see MFIKeyInteractionViewController)
            observeAccessorySessionStateUpdates = false
            observeFIDO2ServiceStateUpdates = false
        
            YubiKitManager.shared.accessorySession.cancelCommands()
        }
    }

    // MARK: - Actions

    @IBAction func actionButtonPressed(_ sender: Any) {
        view.endEditing(true)
        
        guard !usernameTextField.text!.isEmpty && !passwordTextField.text!.isEmpty else {
            present(message: "Enter the username and the password to register or authenticate.")
            return
        }
        
        let title = segmentedControl.selectedSegmentIndex == 0 ? "Register" : "Authenticate"
        let message = "How do you want to \(title)?"
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        if YubiKitDeviceCapabilities.supportsISO7816NFCTags {
            actionSheet.addAction(UIAlertAction(title: "Scan my key - Over NFC", style: .default, handler: { [weak self]  (action) in
                guard let self = self else {
                    return
                }
                self.keyType = .nfc
                self.executeFIDOAction()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Plug my key - From MFi key", style: .default, handler: { [weak self] (action) in
            guard let self = self else {
                return
            }
            self.keyType = .accessory
            self.executeFIDOAction()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (action) in
            self?.dismiss(animated: true, completion: nil)
        }))
        
        // The action sheet requires a presentation popover on iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.modalPresentationStyle = .popover
            if let presentationController = actionSheet.popoverPresentationController {
                presentationController.sourceView = actionButton
                presentationController.sourceRect = actionButton.bounds
            }
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func executeFIDOAction() {
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
        
    // MARK: - MFIKeyActionSheetViewDelegate
    
    override func mfiKeyActionSheetDidDismiss(_ actionSheet: MFIKeyActionSheetView) {
        super.mfiKeyActionSheetDidDismiss(actionSheet)
        nextAction = .none
        
        webauthnService.cancelAllRequests()
        YubiKitManager.shared.accessorySession.cancelCommands()
    }
    
    // MARK: - UITextFieldDelegate
    
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
    
    override func accessorySessionStateDidChange() {
        let state = YubiKitManager.shared.accessorySession.sessionState
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
        guard let fido2Service = YubiKitManager.shared.accessorySession.fido2Service else {
            return
        }
        if fido2Service.keyState == .touchKey {
            presentAuthenticationProgress(message: "Touch the key to complete the operation.", state: .touchKey)
        }
    }

    // MARK: - Registration
    
    private func requestRegistration() {
        if keyType == .accessory {
            guard YubiKitManager.shared.accessorySession.sessionState == .open else {
                nextAction = .register
                presentAuthenticationProgress(message: "Insert the key to register a new account.", state: .insertKey)
                return
            }
        }
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        let createRequest = WebAuthnUserRequest(username: username, password: password, type: .create)
        
        presentAuthenticationProgress(message: "Creating account...", state: .processing)
        
        webauthnService.createUserWith(request: createRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
                return
            }
            guard let response = response else {
                fatalError()
            }
            
            let uuid = response.uuid
            let registerBeginRequest = WebAuthnRegisterBeginRequest(uuid: uuid)
            
            self.presentAuthenticationProgress(message: "Requesting to add a new authenticator...", state: .processing)
            
            self.webauthnService.registerBeginWith(request: registerBeginRequest) { [weak self] (response, error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
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
          
        executeKeyRequestWith { [weak self] in
            guard let self = self else {
                return
            }
            self.keyFido2Service.execute(makeCredentialRequest) { [weak self] (response, error) in
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
                                
                if self.keyType == .accessory {
                    self.finalizeRegistration(response: response, uuid: uuid, requestId: requestId, clientDataJSON: clientDataJSON)
                } else {
                    guard #available(iOS 13.0, *) else {
                        fatalError()
                    }

                    // Observe the scene activation to detect when the Core NFC system UI goes away.
                    // For more details about this solution check the comments on SceneObserver.
                    self.sceneObserver = SceneObserver(sceneActivationClosure: {  [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.finalizeRegistration(response: response, uuid: uuid, requestId: requestId, clientDataJSON: clientDataJSON)
                        self.sceneObserver = nil
                    })

                    // Stop the session to dismiss the Core NFC system UI.
                    YubiKitManager.shared.nfcSession.stopIso7816Session()
                }
            }
        }
    }

    private func finalizeRegistration(response: YKFKeyFIDO2MakeCredentialResponse, uuid: String, requestId: String, clientDataJSON: Data) {
        presentAuthenticationProgress(message: "Adding authenticator to the account...", state: .processing)
        
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
                self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
                return
            }
            
            self.dismissAuthenticationProgressAndPresent(message: "The registration was successful. The account will be valid for 24h.")
        }
    }
    
    // MARK: - Authentication

    private func requestAuthentication() {
        if keyType == .accessory {
            guard YubiKitManager.shared.accessorySession.sessionState == .open else {
                nextAction = .authenticate
                presentAuthenticationProgress(message: "Insert the key to authenticate.", state: .insertKey)
                return
            }
        }
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        let loginRequest = WebAuthnUserRequest(username: username, password: password, type: .login)
        
        presentAuthenticationProgress(message: "Authenticating...", state: .processing)
        
        webauthnService.loginUserWith(request: loginRequest) { [weak self] (response, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
                return
            }
            guard let response = response else {
                fatalError()
            }
            
            let uuid = response.uuid
            let authenticateBeginRequest = WebAuthnAuthenticateBeginRequest(uuid: uuid)
            
            self.presentAuthenticationProgress(message: "Requesting for authenticator challenge..." , state: .processing)
            
            self.webauthnService.authenticateBeginWith(request: authenticateBeginRequest) { [weak self] (response, error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
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
        
        executeKeyRequestWith { [weak self] in
            guard let self = self else {
                return
            }
            self.keyFido2Service.execute(getAssertionRequest) { [weak self] (response, error) in
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
                
                if self.keyType == .accessory {
                    self.finalizeAuthentication(response: response, uuid: uuid, requestId: requestId, clientDataJSON: clientDataJSON)
                } else {
                    guard #available(iOS 13.0, *) else {
                        fatalError()
                    }

                    // Observe the scene activation to detect when the Core NFC system UI goes away.
                    // For more details about this solution check the comments on SceneObserver.
                    self.sceneObserver = SceneObserver(sceneActivationClosure: {  [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.finalizeAuthentication(response: response, uuid: uuid, requestId: requestId, clientDataJSON: clientDataJSON)
                        self.sceneObserver = nil
                    })

                    // Stop the session to dismiss the Core NFC system UI.
                    YubiKitManager.shared.nfcSession.stopIso7816Session()
                }
            }
        }
    }

    private func finalizeAuthentication(response: YKFKeyFIDO2GetAssertionResponse, uuid: String, requestId: String, clientDataJSON: Data) {
        presentAuthenticationProgress(message:"Authenticating..." , state: .processing)
        
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
                self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
                return
            }
            
            self.dismissAuthenticationProgressAndPresent(message: "The authentication was successful.")
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
                    self.dismissAuthenticationProgressAndPresent(message: "The PIN is empty.")
                    return
                }
                guard let verifyPinRequest = YKFKeyFIDO2VerifyPinRequest(pin: pin) else {
                    self.dismissAuthenticationProgressAndPresent(message: "Could not create the request to verify the PIN.")
                    return
                }
                
                self.presentAuthenticationProgress(message: "Verifying PIN...", state: .processing)
                                                
                self.executeKeyRequestWith { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.keyFido2Service.execute(verifyPinRequest) { (error) in
                        completion(error)
                    }
                }
            }
        }
    }
    
    private func handleMakeCredential(error: Error, response: WebAuthnRegisterBeginResponse, uuid: String) {
        let makeCredentialError = error as NSError
        
        guard makeCredentialError.code == YKFKeyFIDO2ErrorCode.PIN_REQUIRED.rawValue else {
            dismissAuthenticationProgressAndPresent(message: makeCredentialError.localizedDescription)
            return
        }
                
        let requestExecutionClosure = { [weak self] in
            guard let self = self else {
                return
            }
            self.handlePinVerificationRequired { [weak self] (error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
                    return
                }
                self.handleRegistration(response: response, uuid: uuid)
            }
        }
        
        // PIN verification is required for the Make Credential request.
        if keyType == .accessory {
            dismissMFIKeyActionSheet()
            requestExecutionClosure()
        } else {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            
            // In case of NFC stop the session to allow the user to input the PIN (the NFC system action sheet blocks any interaction).
            YubiKitManager.shared.nfcSession.stopIso7816Session()
            
            // Observe the scene activation to detect when the Core NFC system UI goes away.
            // For more details about this solution check the comments on SceneObserver.
            self.sceneObserver = SceneObserver(sceneActivationClosure: {  [weak self] in
                guard let self = self else {
                    return
                }
                requestExecutionClosure()
                self.sceneObserver = nil
            })
        }
    }
    
    private func handleGetAssertion(error: Error, response: WebAuthnAuthenticateBeginResponse, uuid: String) {
        let getAssertionError = error as NSError
        
        guard getAssertionError.code == YKFKeyFIDO2ErrorCode.PIN_REQUIRED.rawValue else {
            dismissAuthenticationProgressAndPresent(message: getAssertionError.localizedDescription)
            return
        }
        
        // PIN verification is required for the Get Assertion request.
        if keyType == .accessory {
            dismissMFIKeyActionSheet()
        } else {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            // In case of NFC stop the session to allow the user to input the PIN (the NFC system action sheet blocks any interaction).
            YubiKitManager.shared.nfcSession.stopIso7816Session()
        }
        
        self.handlePinVerificationRequired { [weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                self.dismissAuthenticationProgressAndPresent(message: error!.localizedDescription)
                return
            }
            self.handleAuthentication(response: response, uuid: uuid)
        }
    }
    
    private func executeKeyRequestWith(execution: @escaping () -> Void) {
        if keyType == .accessory {
            // Execute the request right away.
            execution()
        } else {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            
            dismissProgressHud()
            
            let nfcSession = YubiKitManager.shared.nfcSession as! YKFNFCSession
            if nfcSession.iso7816SessionState == .open {
                execution()
                return
            }
            
            // The ISO7816 session is started only when required since it's blocking the application UI with the NFC system action sheet.
            YubiKitManager.shared.nfcSession.startIso7816Session()
            
            // Execute the request after the key(tag) is connected.
            nfcSesionStateObservation = nfcSession.observe(\.iso7816SessionState, changeHandler: { [weak self] session, change in
                if session.iso7816SessionState == .open {
                    execution()
                    self?.nfcSesionStateObservation = nil // remove the observation
                }
            })
        }
    }
    
    // MARK: - Key Info
    
    private func updateKeyInfo() {
        guard YubiKitManager.shared.accessorySession.sessionState == .open else {
            keyInfoLabel.text = nil
            return
        }        
        guard let accessoryDescription = YubiKitManager.shared.accessorySession.accessoryDescription else {
            keyInfoLabel.text = nil
            return
        }
        
        var keyInfoText = ""
        if accessoryDescription.serialNumber.isEmpty {
            keyInfoText = "- Key info -\nFirmware: \(accessoryDescription.firmwareRevision)"
        } else {
            keyInfoText = "- Key info -\nSerial: \(accessoryDescription.serialNumber), Firmware: \(accessoryDescription.firmwareRevision)"
        }
        keyInfoLabel.text = keyInfoText
    }
    
    // MARK: - Authentication Progress

    private func presentAuthenticationProgress(message: String, state: MFIKeyInteractionViewControllerState) {
        switch state {
        case .processing:
            if keyType == .accessory {
                presentMFIKeyActionSheet(state: state, message: message)
            } else {
                presentProgressHud(message: message)
            }
            
        case .insertKey:
            fallthrough
        case .touchKey:
            presentMFIKeyActionSheet(state: state, message: message)
        }
    }
    
    private func dismissAuthenticationProgressAndPresent(message: String) {
        if keyType == .accessory {
            dismissMFIKeyActionSheetAndPresent(message: message)
        } else {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            guard YubiKitManager.shared.nfcSession.iso7816SessionState != .closed else {
                dismissProgressHudAndPresent(message: message)
                return
            }
            
            let nfcSession = YubiKitManager.shared.nfcSession as! YKFNFCSession
            nfcSession.stopIso7816Session()
            
            // Observe the scene activation to detect when the Core NFC system UI goes away.
            // For more details about this solution check the comments on SceneObserver.
            self.sceneObserver = SceneObserver(sceneActivationClosure: {  [weak self] in
                guard let self = self else {
                    return
                }
                self.dismissProgressHudAndPresent(message: message)
                self.sceneObserver = nil
            })
        }
        return
    }
}
