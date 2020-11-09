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

class RawDemoSecCertificate: NSObject {
    
    private var certificate: SecCertificate?
    
    init?(keyData: Data) {
        super.init()
        
        self.certificate = createCertificateWithKey(data: keyData)
        if self.certificate == nil {
            return nil
        }
    }
    
    func verify(data: Data, signature: Data) -> Bool {
        // The certificate shoould not be nil at this point because the initializer will fail.
        let publicKey = publicKeyFrom(certificate: certificate!)
        
        if publicKey == nil {
            print("Could not extract the public key from the certificate.")
            return false
        }
        
        var dataBytes = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &dataBytes, count: data.count)
        
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(dataBytes, UInt32(dataBytes.count), digest)
        
        var signatureBytes = [UInt8](repeating: 0, count: signature.count)
        signature.copyBytes(to: &signatureBytes, count: signature.count)
        
        let status = SecKeyRawVerify(publicKey!, .PKCS1SHA256, digest, Int(CC_SHA256_DIGEST_LENGTH), signatureBytes, signatureBytes.count)
        
        return status == errSecSuccess
    }
    
    // MARK: - Certificate Helpers
    
    private func createCertificateWithKey(data: Data) -> SecCertificate? {
        var mutableData = data
        
        mutableData.remove(at: 0)
        var objectLength = readDERObjectLength(data: mutableData)
        assert(mutableData.count >= objectLength.length + objectLength.offset)
        
        var range = objectLength.offset..<objectLength.length + objectLength.offset
        mutableData = mutableData.subdata(in: range)
        
        if (mutableData[0] != 0x70) {
            // Wrong DER certificate tag.
            return nil
        }
        
        // Get the actual certificate data.
        mutableData.remove(at: 0)
        objectLength = readDERObjectLength(data: mutableData)
        assert(mutableData.count >= objectLength.length + objectLength.offset)
        
        range = objectLength.offset..<objectLength.length + objectLength.offset
        mutableData = mutableData.subdata(in: range)
        
        /*
         Now the data is an ASN.1 DER encoded certificate.
         The Security Framework SecCertificateCreateWithData(_:_:) can be used to create a certificate data
         and use it with the iOS frameworks.
         */
        return SecCertificateCreateWithData(nil, mutableData as NSData)
    }
    
    private func publicKeyFrom(certificate: SecCertificate) -> SecKey? {
        let secPolicy = SecPolicyCreateBasicX509()
        var trust: SecTrust? = nil
        SecTrustCreateWithCertificates(certificate, secPolicy, &trust)
        
        var publicKey: SecKey? = nil
        
        // Wait with a semaphore for the async evaluation of the certificate.
        let evalTrustSemaphore = DispatchSemaphore(value: 0)
        SecTrustEvaluateAsync(trust!, DispatchQueue.global(qos: .background)) { _, trustResult in
            switch trustResult {
            case .proceed, .unspecified:
                publicKey = SecTrustCopyPublicKey(trust!)
                
            // This is for test only when using self signed certificates. In production this path should fail.
            case .recoverableTrustFailure:
                publicKey = SecTrustCopyPublicKey(trust!)
                
            default:
                fatalError()
            }
            
            evalTrustSemaphore.signal()
        }
        
        let timeout = DispatchTime.now() + .seconds(5)
        if evalTrustSemaphore.wait(timeout: timeout) == .timedOut {
            print("Trust evaluation timed out.")
        }
        
        return publicKey
    }
    
    // MARK: - Parsing Helpers
    
    func readDERObjectLength(data: Data) -> (offset: Int, length: Int) {
        if data[0] < 0x81 {
            let len = data[0]
            return (1, Int(len))
            
        } else if data[0] & 0x7f == 1  {
            let len = data[1]
            return (2, Int(len))
            
        } else if data[0] & 0x7f == 2 {
            let len = Int(data[1]) << 8 + Int(data[2])
            return (3, Int(len))
        }
        return (0, 0)
    }
}
