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

/*
 Client Data as defined in the WebAuthN:
 https://developer.mozilla.org/en-US/docs/Web/API/AuthenticatorResponse/clientDataJSON
 */
class WebAuthnClientData: NSObject {
    
    enum  WebAuthnClientDataType: String {
        case create = "webauthn.create"
        case get = "webauthn.get"
    }
    
    var type: String
    var challenge: String
    var origin: String
    
    /*
     In WebAuthN, the expected hash to be signed by the CTAP2/FIDO2 authenticator is the
     SHA256 of the clientDataJSON.
     */
    var clientDataHash: Data? {
        get {
            guard let data = jsonData else {
                return nil
            }
            
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes { (bytes) in
                guard let rawBytes = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    fatalError()
                }
                _ = CC_SHA256(rawBytes, CC_LONG(data.count), &hash)
            }
            
            return Data(hash)
        }
    }
    
    init(type: WebAuthnClientDataType, challenge: String, origin: String) {
        self.type = type.rawValue
        self.challenge = challenge
        self.origin = origin
        super.init()
    }
    
    var jsonData: Data? {
        get {
            /*
             Notes:
             1. The Yubico WebAuthN demo server returns the challenge data encoded in Base64.
             2. The challenge in the clientDataJSON must be base64url (same as websafeBase64) encoded as
                required by the WebAuthN specifications. The base64url encoding is defined in RFC 4648,
                section 5: https://tools.ietf.org/html/rfc4648#section-5.
             */
            guard let challengeData = Data(base64Encoded: challenge) else {
                return nil
            }
            guard let websafeChallenge = challengeData.websafeBase64String() else {
                return nil
            }
            
            let jsonDictionary = [
                "type": type,
                "challenge": websafeChallenge,
                "origin": origin
            ]
            
            do {
                return try JSONSerialization.data(withJSONObject: jsonDictionary)
            } catch _ {
                return nil
            }
        }
    }
}
