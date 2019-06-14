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

class WebAuthnAuthenticateBeginRequest: WebAuthnRequest {
    
    private let authenticateBeginApiEndpoint = "https://demo.yubico.com/api/v1/auth/webauthn/authenticate-begin"
    
    private let namespace = "webauthnflow"
    private(set) var uuid: String

    override var apiEndpoint: String {
        get {
            return authenticateBeginApiEndpoint
        }
    }
    
    override var jsonData: Data? {
        get {
            let jsonDictionary = [
                "namespace": namespace,
                "uuid": uuid
            ]
            
            do {
                return try JSONSerialization.data(withJSONObject: jsonDictionary)
            } catch _ {
                return nil
            }
        }
    }
    
    init(uuid: String) {
        self.uuid = uuid
        super.init()
    }
}
