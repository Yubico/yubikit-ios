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

class FIDO2ViewController: UIViewController, UITextFieldDelegate, YKFManagerDelegate, YKFKeyFIDO2SessionKeyStateDelegate {
    
    func keyStateChanged(_ keyState: YKFKeyFIDO2SessionKeyState) {
        if keyState == .touchKey {
            self.statusView?.state = .touchKey
        }
    }
    
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
    
    var statusView: StatusView?
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusView = view.presentStatusView()
        statusView?.state = .hidden
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    var nfcConnection: YKFNFCConnection?

    func didConnectNFC(_ connection: YKFNFCConnection) {
        nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection)
        }
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
        session = nil
    }
    
    var accessoryConnection: YKFAccessoryConnection?

    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        accessoryConnection = nil
        session = nil
    }
    
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    
    var connectionType: ConnectionType? {
        get {
            if nfcConnection != nil {
                return .nfc
            } else if accessoryConnection != nil {
                return .accessory
            } else {
                return nil
            }
        }
    }
    
    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            connectionCallback = completion
            if #available(iOS 13.0, *) {
                YubiKitManager.shared.startNFCConnection()
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    var session: YKFKeyFIDO2Session?

    func session(completion: @escaping (_ session: YKFKeyFIDO2Session?, _ error: Error?) -> Void) {
        if let session = session {
            completion(session, nil)
            return
        }
        connection { connection in
            connection.fido2Session { session, error in
                self.session = session
                session?.delegate = self
                completion(session, error)
            }
        }
    }

    // MARK: - Actions

    @IBAction func actionButtonPressed(_ sender: Any) {
        view.endEditing(true)
        
        switch segmentedControl.action {
        case .register:
            register()
        case .authenticate:
            authenticate()
        }
    }

    
    // MARK: - Register user
    
    func register() {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        statusView?.state = .message("Creating user...")
        // 1. Begin WebAuthn registration
        beginWebAuthnRegistration(username: username, password: password) { result in
            switch result {
            case .success(let response):
                // 2. Create credential on Yubikey
                self.makeCredentialOnKey(response: response) { result in
                    if #available(iOS 13.0, *) {
                        YubiKitManager.shared.stopNFCConnection()
                    }
                    switch result {
                    case .success(let response):
                        self.statusView?.state = .message("Finalising registration...")
                        // 3. Finalize WebAuthn registration
                        self.finalizeWebAuthnRegistration(response: response) { result in
                            switch result {
                            case .success:
                                self.statusView?.dismiss(message: "User successfully registrered", accessory: .checkmark, delay: 5.0)
                            case .failure(let error):
                                self.statusView?.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 5.0)
                            }
                        }
                    case .failure(let error):
                        self.statusView?.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 5.0)
                    }
                }
            case .failure(let error):
                self.statusView?.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 5.0)
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
        
    func makeCredentialOnKey(response: BeginWebAuthnRegistrationResponse,  completion: @escaping (Result<MakeCredentialOnKeyRegistrationResponse, Error>) -> Void) {
        let challengeData = Data(base64Encoded: response.challenge)!
        let clientData = YKFWebAuthnClientData(type: .create, challenge: challengeData, origin: WebAuthnService.origin)!
        
        let clientDataHash = clientData.clientDataHash!
        
        let rp = YKFFIDO2PublicKeyCredentialRpEntity()
        rp.rpId = response.rpId
        rp.rpName = response.rpName
        
        let user = YKFFIDO2PublicKeyCredentialUserEntity()
        user.userId = Data(base64Encoded: response.userId)!
        user.userName = response.userName
        
        let param = YKFFIDO2PublicKeyCredentialParam()
        param.alg = response.pubKeyAlg
        let pubKeyCredParams = [param]
        
        let options = [YKFKeyFIDO2OptionRK: response.residentKey]
        
        session { session, error in
            guard let session = session else { completion(.failure(error!)); return }
            session.makeCredential(withClientDataHash:clientDataHash,
                                   rp: rp,
                                   user: user,
                                   pubKeyCredParams: pubKeyCredParams,
                                   excludeList: nil,
                                   options: options)  { [self] keyResponse, error in
                guard error == nil else {
                    if let error = error as NSError?, error.code == YKFKeyFIDO2ErrorCode.PIN_REQUIRED.rawValue {
                        handlePINCode() {
                            makeCredentialOnKey(response: response, completion: completion)
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

    func handlePINCode(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.statusView?.state = .hidden
            let alert = UIAlertController(pinInputCompletion: { pin in
                guard let pin = pin else {
                    self.statusView?.dismiss(message: "No pin, exiting...", accessory: .error, delay: 5.0)
                    return
                }
                self.session { session, error in
                    guard let session = session else {
                        self.statusView?.dismiss(message: error!.localizedDescription, accessory: .error, delay: 5.0)
                        return
                    }
                    session.verifyPin(pin) { error in
                        guard error == nil else {
                            self.statusView?.dismiss(message: "Wrong PIN", accessory: .error, delay: 5.0)
                            return
                        }
                        completion()
                    }
                }
            })
            self.present(alert, animated: true)
        }
    }

    // MARK: - Authenticate User
    func authenticate() {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        statusView?.state = .message("Requesting authenticator challenge...")
        
        // 1. Begin WebAuthn authentication
        beginWebAuthnAuthentication(username: username, password: password) { result in
            switch result {
            case .success(let response):
                // 2. Assert on Yubikey
                self.assertOnKey(response: response) { result in
                    switch result {
                    case .success(let response):
                        self.statusView?.state = .message("Authenticating...")
                        // 3. Finalize WebAuthn authentication
                        self.finalizeWebAuthnAuthentication(response: response) { result in
                            switch result {
                            case .success:
                                self.statusView?.dismiss(message: "User successfully authenticated", accessory: .checkmark, delay: 7.0)
                            case .failure(let error):
                                self.statusView?.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 7.0)
                            }
                        }
                    case .failure(let error):
                        self.statusView?.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 7.0)
                    }
                }
            case .failure(let error):
                self.statusView?.dismiss(message: "Error: \(error.localizedDescription)", accessory: .error, delay: 7.0)
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
    
    func assertOnKey(response: BeginWebAuthnAuthenticationResponse, completion: @escaping (Result<AssertOnKeyAuthenticationResponse, Error>) -> Void) {
        session { session, error in
            guard let session = session else { completion(.failure(error!)); return }
            let challengeData = Data(base64Encoded: response.challenge)!
            let clientData = YKFWebAuthnClientData(type: .get, challenge: challengeData, origin: WebAuthnService.origin)!
            
            let clientDataHash = clientData.clientDataHash!
            
            let rpId = response.rpId
            let options = [YKFKeyFIDO2OptionUP: true]
            
            var allowList = [YKFFIDO2PublicKeyCredentialDescriptor]()
            for credentialId in response.allowCredentials {
                let credentialDescriptor = YKFFIDO2PublicKeyCredentialDescriptor()
                credentialDescriptor.credentialId = Data(base64Encoded: credentialId)!
                let credType = YKFFIDO2PublicKeyCredentialType()
                credType.name = "public-key"
                credentialDescriptor.credentialType = credType
                allowList.append(credentialDescriptor)
            }
            
            session.getAssertionWithClientDataHash(clientDataHash,
                                                   rpId: rpId,
                                                   allowList: allowList,
                                                   options: options) { assertionResponse, error in
                if self.connectionType == .nfc, #available(iOS 13.0, *) {
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
