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

class WebAuthnRegisterFinishRequest: WebAuthnRequest {
    
    private let registerFinishApiEndpointTemplate = "https://demo.yubico.com/api/v1/user/%@/webauthn/register-finish"
    
    private(set) var uuid: String
    private(set) var requestId: String
    private(set) var clientDataJSON: Data
    private(set) var attestationObject: Data
    
    override var apiEndpoint: String {
        get {
            return String(format: registerFinishApiEndpointTemplate, uuid)
        }
    }
    
    override var jsonData: Data? {
        get {
            let encodedClientDataJSON = clientDataJSON.base64EncodedString()
            let encodedAttestationObject = attestationObject.base64EncodedString()
            
            let jsonDictionary = [
                "requestId": requestId,
                "attestation": ["clientDataJSON": encodedClientDataJSON,
                                "attestationObject": encodedAttestationObject]
                ] as [String: Any]
            
            do {
                return try JSONSerialization.data(withJSONObject: jsonDictionary)
            } catch _ {
                return nil
            }
        }
    }
        
    init(uuid: String, requestId: String, clientDataJSON: Data, attestationObject: Data) {
        self.uuid = uuid
        self.requestId = requestId
        self.clientDataJSON = clientDataJSON
        self.attestationObject = attestationObject
        super.init()
    }
}
