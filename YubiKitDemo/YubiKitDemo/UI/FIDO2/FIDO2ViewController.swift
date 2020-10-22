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

class FIDO2ViewController: UIViewController, UITextFieldDelegate, YKFManagerDelegate {
    
    enum ConnectionType {
        case nfc
        case accessory
    }
    
    enum Action {
        case register
        case authenticate
    }

    private var sceneObserver: SceneObserver?

    // MARK: - Outlets
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var keyInfoLabel: UILabel!
    
    var connection: YKFConnectionProtocol?
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?

    func connection(_ type: ConnectionType, completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = connection {
            completion(connection)
        } else {
            self.connectionCallback = { connection in
                completion(connection)
            }
            switch type {
            case .nfc:
                if #available(iOS 13.0, *) {
                    YubiKitManager.shared.startNFCConnection()
                } else {
                    // Fallback on earlier versions
                }
            case .accessory:
                YubiKitManager.shared.startAccessoryConnection()
            }
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if true {
            usernameTextField.text = "user42"
            passwordTextField.text = "password123"
        } else {
            usernameTextField.text = "user\(arc4random() % 1000)"
            passwordTextField.text = "password123"
        }
        YubiKitManager.shared.delegate = self
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            YubiKitManager.shared.startAccessoryConnection()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            YubiKitManager.shared.stopAccessoryConnection()
        }
    }
    
    // MARK: - YKFManagerDelegate
    
    func didConnectNFC(_ nfcConnection: YKFNFCConnection) {
        connection = nfcConnection
        guard let connectionCallback = connectionCallback else { return }
        connectionCallback(nfcConnection)
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        print("didDisconnectNFC")
    }
    
    func didConnectAccessory(_ accessoryConnection: YKFAccessoryConnection) {
        connection = accessoryConnection
        guard let connectionCallback = connectionCallback else { return }
        connectionCallback(accessoryConnection)
    }
    
    func didDisconnectAccessory(_ accessoryConnection: YKFAccessoryConnection, error: Error?) {
        connection = nil
        connectionCallback = nil
    }

    // MARK: - Actions

    @IBAction func actionButtonPressed(_ sender: Any) {
        view.endEditing(true)
        
        let title = segmentedControl.action == .register ? "Register" : "Authenticate"
        if YubiKitDeviceCapabilities.supportsISO7816NFCTags && YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            let alert = UIAlertController(title: title, message: "How do you want to \(title)?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "NFC Yubikey", style: .default, handler: { [weak self]  (action) in
                // NFC, Register || Authenticate
                self?.handleAction(connectionType: .nfc)
           }))
            alert.addAction(UIAlertAction(title: "Accessory Yubikey", style: .default, handler: { [weak self] (action) in
                // Accessory, Register || Authenticate
                self?.handleAction(connectionType: .accessory)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (action) in
                self?.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
        } else if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Accessory, Register || Authenticate
            handleAction(connectionType: .accessory)
        } else if YubiKitDeviceCapabilities.supportsISO7816NFCTags {
            // NFC, Register || Authenticate
            handleAction(connectionType: .nfc)
        } else {
            // This device does not work at all
        }
    }
    
    func handleAction(connectionType: ConnectionType) {
        switch segmentedControl.action {
        case .register:
            register(connectionType: connectionType)
        case .authenticate:
            authenticate(connectionType: connectionType)
        }
    }
    
    // MARK: - Register user
    
    func register(connectionType: ConnectionType) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        let statusView = view.presentStatusView()
        statusView.state = .message("Creating user...")
        // 1. Begin WebAuthn registration
        beginWebAuthnRegistration(username: username, password: password) { [self] result in
            switch result {
            case .success(let response):
                if connectionType == .accessory {
                    statusView.state = .insertKey
                }
                // 2. Create credential on Yubikey
                makeCredentialOnKey(connectionType: connectionType, response: response, statusView: statusView) { result in
                    if connectionType == .nfc, #available(iOS 13.0, *) {
                        YubiKitManager.shared.stopNFCConnection()
                    }
                    switch result {
                    case .success(let response):
                        statusView.state = .message("Finalising registration...")
                        // 3. Finalize WebAuthn registration
                        finalizeWebAuthnRegistration(response: response) { result in
                            switch result {
                            case .success:
                                statusView.dismiss(message: "User successfully registrered", accessory: .checkmark, delay: 5.0)
                            case .failure(let error):
                                statusView.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 5.0)
                            }
                        }
                    case .failure(let error):
                        statusView.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 5.0)
                    }
                }
            case .failure(let error):
                statusView.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 5.0)
            }
        }
    }
    
    func beginWebAuthnRegistration(username: String, password: String, completion: @escaping (Result<(BeginWebAuthnRegistrationResponse), Error>) -> Void) {
        let webauthnService = WebAuthnService()
        let createRequest = WebAuthnUserRequest(username: username, password: password, type: .create)
        webauthnService.createUserWith(request: createRequest) { (createUserResponse, error) in
            guard error == nil else { completion(.failure(error!)); return }
            guard let createUserResponse = createUserResponse else { fatalError() }
            let uuid = createUserResponse.uuid
            let registerBeginRequest = WebAuthnRegisterBeginRequest(uuid: uuid)
            webauthnService.registerBeginWith(request: registerBeginRequest) { (registerBeginResponse, error) in
                guard error == nil else { completion(.failure(error!)); return }
                guard let registerBeginResponse = registerBeginResponse else { fatalError() }
                let result = BeginWebAuthnRegistrationResponse(uuid: uuid,
                                                               requestId: registerBeginResponse.requestId,
                                                               challenge: registerBeginResponse.challenge,
                                                               rpId: registerBeginResponse.rpId,
                                                               rpName: registerBeginResponse.rpName,
                                                               userId: registerBeginResponse.userId,
                                                               userName: registerBeginResponse.username,
                                                               pubKeyAlg: registerBeginResponse.pubKeyAlg,
                                                               residentKey: registerBeginResponse.residentKey)
                completion(.success(result))
            }
        }
    }

    struct BeginWebAuthnRegistrationResponse {
        let uuid: String
        let requestId: String
        let challenge: String
        let rpId: String
        let rpName: String
        let userId: String
        let userName: String
        let pubKeyAlg: Int
        let residentKey: Bool
    }
        
    func makeCredentialOnKey(connectionType: ConnectionType, response: BeginWebAuthnRegistrationResponse, statusView: StatusView,  completion: @escaping (Result<MakeCredentialOnKeyRegistrationResponse, Error>) -> Void) {
        self.connection(connectionType) { connection in
            let challengeData = Data(base64Encoded: response.challenge)!
            let clientData = YKFWebAuthnClientData(type: .create, challenge: challengeData, origin: WebAuthnService.origin)!
            
            let makeCredentialRequest = YKFKeyFIDO2MakeCredentialRequest()
            makeCredentialRequest.clientDataHash = clientData.clientDataHash!
            
            let rp = YKFFIDO2PublicKeyCredentialRpEntity()
            rp.rpId = response.rpId
            rp.rpName = response.rpName
            makeCredentialRequest.rp = rp
            
            let user = YKFFIDO2PublicKeyCredentialUserEntity()
            user.userId = Data(base64Encoded: response.userId)!
            user.userName = response.userName
            makeCredentialRequest.user = user
            
            let param = YKFFIDO2PublicKeyCredentialParam()
            param.alg = response.pubKeyAlg
            makeCredentialRequest.pubKeyCredParams = [param]
            
            let makeOptions = [YKFKeyFIDO2MakeCredentialRequestOptionRK: response.residentKey]
            makeCredentialRequest.options = makeOptions
            
            if connectionType == .accessory {
                statusView.state = .insertKey
            }
            connection.fido2Session() { result in
                if connectionType == .accessory {
                    statusView.state = .touchKey
                }
                switch result {
                case .success(let session):
                    session.execute(makeCredentialRequest) { [self] keyResponse, error in
                        guard error == nil else {
                            if let error = error as NSError?, error.code == YKFKeyFIDO2ErrorCode.PIN_REQUIRED.rawValue {
                                handlePINCode(connectionType: connectionType, statusView: statusView) {
                                    makeCredentialOnKey(connectionType: connectionType, response: response, statusView: statusView, completion: completion)
                                }
                                return
                            }
                            completion(.failure(error!))
                            return
                        }
                        
                        guard let keyResponse = keyResponse else { fatalError() }
                        let result = MakeCredentialOnKeyRegistrationResponse(uuid: response.uuid,
                                                                             requestId: response.requestId,
                                                                             clientDataJSON: clientData.jsonData!,
                                                                             attestationObject: keyResponse.webauthnAttestationObject)
                        completion(.success(result))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    struct MakeCredentialOnKeyRegistrationResponse {
        let uuid: String
        let requestId: String
        let clientDataJSON: Data
        let attestationObject: Data
    }
    
    func finalizeWebAuthnRegistration(response: MakeCredentialOnKeyRegistrationResponse, completion: @escaping (Result<WebAuthnRegisterFinishResponse, Error>) -> Void) {
        let webauthnService = WebAuthnService()
        // Send back the response to the server.
        let registerFinishRequest = WebAuthnRegisterFinishRequest(uuid: response.uuid,
                                                                  requestId: response.requestId,
                                                                  clientDataJSON: response.clientDataJSON,
                                                                  attestationObject: response.attestationObject)
        webauthnService.registerFinishWith(request: registerFinishRequest) { (response, error) in
            guard error == nil else { completion(.failure(error!)); return }
            guard let response = response else { fatalError() }
            DispatchQueue.main.async {
                completion(.success(response))
            }
        }
    }

    func handlePINCode(connectionType: ConnectionType, statusView: StatusView, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            statusView.state = .hidden
            let alert = UIAlertController(pinInputCompletion: { pin in
                guard let pin = pin else {
                    statusView.dismiss(message: "No pin, exiting...", accessory: .error, delay: 5.0)
                    return
                }
                self.connection(connectionType) { connection in
                    connection.fido2Session { result in
                        switch result {
                        case .success(let session):
                            let pinRequest = YKFKeyFIDO2VerifyPinRequest(pin: pin)!
                            session.execute(pinRequest) { error in
                                guard error == nil else {
                                    statusView.dismiss(message: "Wrong PIN", accessory: .error, delay: 5.0)
                                    return
                                }
                                completion()
                            }
                        case .failure(let error):
                            statusView.dismiss(message: error.localizedDescription, accessory: .error, delay: 5.0)
                        }
                    }
                }
            })
            self.present(alert, animated: true)
        }
    }

    // MARK: - Authenticate User
    func authenticate(connectionType: ConnectionType) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        let statusView = view.presentStatusView()
        statusView.state = .message("Requesting authenticator challenge...")
        
        // 1. Begin WebAuthn authentication
        beginWebAuthnAuthentication(username: username, password: password) { [self] result in
            switch result {
            case .success(let response):
                if connectionType == .accessory {
                    statusView.state = .insertKey
                }
                // 2. Assert on Yubikey
                assertOnKey(connectionType: connectionType, response: response, statusView: statusView) { result in
                    switch result {
                    case .success(let response):
                        statusView.state = .message("Authenticating...")
                        // 3. Finalize WebAuthn authentication
                        finalizeWebAuthnAuthentication(response: response) { result in
                            switch result {
                            case .success:
                                statusView.dismiss(message: "User successfully authenticated", accessory: .checkmark, delay: 7.0)
                            case .failure(let error):
                                statusView.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 7.0)
                            }
                        }
                    case .failure(let error):
                        statusView.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 7.0)
                    }
                }
            case .failure(let error):
                statusView.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 7.0)
            }
        }
    }
    
    func beginWebAuthnAuthentication(username: String, password: String, completion: @escaping (Result<(BeginWebAuthnAuthenticationResponse), Error>) -> Void) {
        let webauthnService = WebAuthnService()
        let authenticationRequest = WebAuthnUserRequest(username: username, password: password, type: .login)
        webauthnService.loginUserWith(request: authenticationRequest) { (authenticationUserResponse, error) in
            guard error == nil else { completion(.failure(error!)); return }
            guard let authenticationUserResponse = authenticationUserResponse else { fatalError() }
            let uuid = authenticationUserResponse.uuid
            let authenticationBeginRequest = WebAuthnAuthenticateBeginRequest(uuid: uuid)
            webauthnService.authenticateBeginWith(request: authenticationBeginRequest) { (authenticationBeginResponse, error) in
                guard error == nil else { completion(.failure(error!)); return }
                guard let authenticationBeginResponse = authenticationBeginResponse else { fatalError() }
                let result = BeginWebAuthnAuthenticationResponse(uuid: uuid,
                                                                 requestId: authenticationBeginResponse.requestId,
                                                                 challenge: authenticationBeginResponse.challenge,
                                                                 rpId: authenticationBeginResponse.rpID,
                                                                 allowCredentials: authenticationBeginResponse.allowCredentials)
                completion(.success(result))
            }
        }
    }
    
    struct BeginWebAuthnAuthenticationResponse {
        let uuid: String
        let requestId: String
        let challenge: String
        let rpId: String
        let allowCredentials: [String]
    }
    
    func assertOnKey(connectionType: ConnectionType, response: BeginWebAuthnAuthenticationResponse, statusView: StatusView, completion: @escaping (Result<AssertOnKeyAuthenticationResponse, Error>) -> Void) {
        self.connection(connectionType) { connection in
            let challengeData = Data(base64Encoded: response.challenge)!
            let clientData = YKFWebAuthnClientData(type: .get, challenge: challengeData, origin: WebAuthnService.origin)!
            
            let getAssertionRequest = YKFKeyFIDO2GetAssertionRequest()
            getAssertionRequest.clientDataHash = clientData.clientDataHash!
            
            getAssertionRequest.rpId = response.rpId
            getAssertionRequest.options = [YKFKeyFIDO2GetAssertionRequestOptionUP: true]
            
            if connectionType == .accessory {
                statusView.state = .touchKey
            }
            
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
            
            connection.fido2Session() { result in
                switch result {
                case .success(let session):
                    session.execute(getAssertionRequest) { assertionResponse, error in
                        if connectionType == .nfc, #available(iOS 13.0, *) {
                            YubiKitManager.shared.stopNFCConnection()
                        }
                        guard error == nil else {
                            completion(.failure(error!))
                            return
                        }
                        guard let assertionResponse = assertionResponse else { fatalError() }
                        let result = AssertOnKeyAuthenticationResponse(uuid: response.uuid,
                                                                       requestId: response.requestId,
                                                                       credentialId: assertionResponse.credential!.credentialId,
                                                                       authenticatorData: assertionResponse.authData,
                                                                       clientDataJSON: clientData.jsonData!,
                                                                       signature: assertionResponse.signature)
                        completion(.success(result))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    struct AssertOnKeyAuthenticationResponse {
        let uuid: String
        let requestId: String
        let credentialId: Data
        let authenticatorData: Data
        let clientDataJSON: Data
        let signature: Data
    }
    
    func finalizeWebAuthnAuthentication(response: AssertOnKeyAuthenticationResponse, completion: @escaping (Result<WebAuthnAuthenticateFinishResponse, Error>) -> Void) {
        
        let webauthnService = WebAuthnService()
        let authenticateFinishRequest = WebAuthnAuthenticateFinishRequest(uuid: response.uuid,
                                                                          requestId: response.requestId,
                                                                          credentialId: response.credentialId,
                                                                          authenticatorData: response.authenticatorData,
                                                                          clientDataJSON: response.clientDataJSON,
                                                                          signature: response.signature)

        webauthnService.authenticateFinishWith(request: authenticateFinishRequest) { (response, error) in
            guard error == nil else { completion(.failure(error!)); return }
            guard let response = response else { fatalError() }
            completion(.success(response))
        }
    }
    
    // MARK: -
    
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
}

extension UISegmentedControl {
    var action: FIDO2ViewController.Action {
        get {
            if self.selectedSegmentIndex == 0 {
                return .register
            } else {
                return .authenticate
            }
        }
    }
}

extension UIAlertController {
    convenience init(pinInputCompletion:  @escaping (String?) -> Void) {
        self.init(title: "PIN verification required", message: "Enter the key PIN", preferredStyle: UIAlertController.Style.alert)
        addTextField { (textField) in
            textField.placeholder = "PIN"
            textField.isSecureTextEntry = true
        }
        addAction(UIAlertAction(title: "Verify", style: .default, handler: { (action) in
            let pin = self.textFields![0].text
            pinInputCompletion(pin)
        }))
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            pinInputCompletion(nil)
        }))
    }
}

// Wrap the fido2Session() Objective-C method in a more easy to use Swift version
extension YKFConnectionProtocol {
    func fido2Session(_ completion: @escaping ((_ result: Result<YKFKeyFIDO2SessionProtocol, Error>) -> Void)) {
        self.fido2Session { session, error in
            guard error == nil else { completion(.failure(error!)); return }
            guard let session = session else { fatalError() }
            completion(.success(session))
        }
    }
}
