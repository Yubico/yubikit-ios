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

final class WebAuthnAuthenticateBeginResponse: NSObject, WebAuthnResponseProtocol {
    
    private(set) var requestId: String
    private(set) var rpID: String
    private(set) var challenge: String
    private(set) var allowCredentials: Array<String> = []
    
    init?(response: Data) {
        do {
            guard let responseDictionary = try JSONSerialization.jsonObject(with: response) as? Dictionary<String, Any> else {
                return nil
            }
            guard let status = responseDictionary["status"] as? String else { return nil }
            guard status == "success" else { return nil }
            
            guard let dataDictionary = responseDictionary["data"] as? Dictionary<String, Any> else { return nil }
            guard let respRequestId = dataDictionary["requestId"] as? String else { return nil }
            requestId = respRequestId
            
            guard let publicKeyDictionary = dataDictionary["publicKey"] as? Dictionary<String, Any> else { return nil }
            guard let respRpId = publicKeyDictionary["rpId"] as? String else { return nil }
            rpID = respRpId
            guard let respChallenge = publicKeyDictionary["challenge"] as? String else { return nil }
            challenge = respChallenge
            
            guard let allowCredentialsArray = publicKeyDictionary["allowCredentials"] as? Array<Dictionary<String, String>> else { return nil }
            for credential in allowCredentialsArray {
                guard let credentialId = credential["id"] else { return nil }
                allowCredentials.append(credentialId)
            }            
        } catch _ {
            return nil
        }
        super.init()
    }
}
