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

final class WebAuthnRegisterBeginResponse: NSObject, WebAuthnResponseProtocol {
    
    private(set) var requestId: String
    
    private(set) var username: String
    private(set) var userId: String
    
    private(set) var rpId: String
    private(set) var rpName: String
    
    private(set) var pubKeyAlg: Int
    private(set) var residentKey: Bool
    
    private(set)  var challenge: String
    
    init?(response: Data) {
        do {
            guard let responseDictionary = try JSONSerialization.jsonObject(with: response) as? Dictionary<String, Any> else {
                return nil
            }
            guard let status = responseDictionary["status"] as? String else { return nil }
            guard status == "success" else { return nil }
            
            guard let dataDictionary = responseDictionary["data"] as? Dictionary<String, Any> else { return nil }
            guard let dataRequestId = dataDictionary["requestId"] as? String else { return nil }
            requestId = dataRequestId
            
            guard let publicKeyDictionary = dataDictionary["publicKey"] as? Dictionary<String, Any> else { return nil }
            guard let userDictionary = publicKeyDictionary["user"] as? Dictionary<String, Any> else { return nil }
            guard let respUsername = userDictionary["name"] as? String else { return nil }
            username = respUsername
            guard let respUserId = userDictionary["id"] as? String else { return nil }
            userId = respUserId
            
            guard let rpDictionary = publicKeyDictionary["rp"] as? Dictionary<String, Any> else { return nil }
            guard let resRpId = rpDictionary["id"] as? String else { return nil }
            rpId = resRpId
            guard let respRpName = rpDictionary["name"] as? String else { return nil }
            rpName = respRpName
            
            guard let pubKeyCredParamsArray = publicKeyDictionary["pubKeyCredParams"] as? Array<Dictionary<String, Any>> else { return nil }
            guard let alg = pubKeyCredParamsArray[0]["alg"] as? Int else { return nil }
            pubKeyAlg = alg // -7 (ECC) or -257 (RSA). ECC is preffered and is usually the first returned by the demo server.
            
            guard let authenticatorSelectionDictionary = publicKeyDictionary["authenticatorSelection"] as? Dictionary<String, Any> else { return nil }
            guard let respResidentKey = authenticatorSelectionDictionary["requireResidentKey"] as? Bool else { return nil }
            residentKey = respResidentKey
            
            guard let respChallenge = publicKeyDictionary["challenge"] as? String else { return nil }
            challenge = respChallenge // Will be used to create later the clientData to be signed by the key.
        } catch _ {
            return nil
        }
        super.init()
    }
}
