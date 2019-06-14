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

class WebAuthnAuthenticateFinishRequest: WebAuthnRequest {
    
    private let authenticateFinishApiEndpoint = "https://demo.yubico.com/api/v1/auth/webauthn/authenticate-finish"
    
    private let namespace = "webauthnflow"
    private(set) var uuid: String
    private(set) var requestId: String
    
    private(set) var credentialId: Data
    private(set) var authenticatorData: Data
    private(set) var clientDataJSON: Data
    private(set) var signature: Data
    
    override var apiEndpoint: String {
        get {
            return authenticateFinishApiEndpoint
        }
    }
    
    override var jsonData: Data? {
        get {
            let encodedCredentialId = credentialId.base64EncodedString()
            let encodedAuthenticatorData = authenticatorData.base64EncodedString()
            let encodedClientDataJSON = clientDataJSON.base64EncodedString()
            let encodedSignature = signature.base64EncodedString()
            
            let jsonDictionary = [
                "namespace": namespace,
                "uuid": uuid,
                "requestId": requestId,
                "assertion": ["credentialId": encodedCredentialId,
                              "authenticatorData": encodedAuthenticatorData,
                              "clientDataJSON": encodedClientDataJSON,
                              "signature": encodedSignature]
                ] as [String : Any]
            
            do {
                return try JSONSerialization.data(withJSONObject: jsonDictionary)
            } catch _ {
                return nil
            }
        }
    }        
    
    init(uuid: String, requestId: String, credentialId: Data, authenticatorData: Data, clientDataJSON: Data, signature: Data) {
        self.uuid = uuid
        self.requestId = requestId
        self.credentialId = credentialId
        self.authenticatorData = authenticatorData
        self.clientDataJSON = clientDataJSON
        self.signature = signature
        super.init()
    }
}
