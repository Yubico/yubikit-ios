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

enum WebAuthnUserRequestType {
    case create
    case login
}

class WebAuthnUserRequest: WebAuthnRequest {
    
    private let createUserApiEndpoint = "https://demo.yubico.com/api/v1/user"
    private let loginUserApiEndpoint = "https://demo.yubico.com/api/v1/auth/login"
    
    private let namespace = "webauthnflow"
    private let minUsernameLenght = 1
    private let minPasswordLength = 1
    
    private(set) var username: String
    private(set) var password: String
    private(set) var type: WebAuthnUserRequestType
    
    override var apiEndpoint: String {
        get {
            return self.type == .create ? createUserApiEndpoint : loginUserApiEndpoint
        }
    }
    
    override var jsonData: Data? {
        get {
//            assert(username.count >= minUsernameLenght)
//            assert(password.count >= minPasswordLength)
            
            let jsonDictionary = [
                "namespace": namespace,
                "username": username,
                "password": password
            ]
            
            do {
                return try JSONSerialization.data(withJSONObject: jsonDictionary)
            } catch _ {
                return nil
            }
        }
    }
    
    init(username: String, password: String, type: WebAuthnUserRequestType) {
        self.username = username
        self.password = password
        self.type = type
        super.init()
    }
}
