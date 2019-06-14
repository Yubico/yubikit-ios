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

let WebServiceServerError            = (code: 1, description: "Server error.")
let WebServiceMalformedResponseError = (code: 2, description: "Malformed response received from server.")
let WebServiceMalformedRequestError  = (code: 3, description: "Malformed request: could not create an URL request with the specified parameters.")
let WebServiceValidationError        = (code: 4, description: "Unknown validation error.")

class WebServiceError: NSError {
    
    static var webServiceErrorDomain = "WebServiceError"
    
    // MARK: - Errors
    
    class func serverError() -> WebServiceError {
        return WebServiceError(withCode: WebServiceServerError.code, description: WebServiceServerError.description)
    }
    
    class func malformedResponseError() -> WebServiceError {
        return WebServiceError(withCode: WebServiceMalformedResponseError.code, description: WebServiceMalformedResponseError.description)
    }

    class func malformedRequestError() -> WebServiceError {
        return WebServiceError(withCode: WebServiceMalformedRequestError.code, description: WebServiceMalformedRequestError.description)
    }
    
    // MARK: - Object lifecycle
    
    init(withCode code: Int, description:String) {
        super.init(domain: WebServiceError.webServiceErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    convenience init(data: Data?) {
        var description: String? = nil
        guard let data = data else {
            self.init(withCode: WebServiceValidationError.code, description: "No error status returned by the server.")
            return
        }
        do {
            guard let responseDictionary = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>  else {
                self.init(withCode: WebServiceMalformedResponseError.code, description: WebServiceMalformedResponseError.description)
                return
            }
            if let status = responseDictionary["status"] as? String {
                switch status {
                case "error":
                    description = responseDictionary["message"] as? String
                case "fail":
                    fallthrough
                default:
                    description = "Invalid input error returned by the server."
                }
            }
        } catch _ {
            self.init(withCode: WebServiceMalformedResponseError.code, description: WebServiceMalformedResponseError.description)
            return
        }

        let errorDescription = description ?? WebServiceValidationError.description
        self.init(withCode: WebServiceValidationError.code, description: errorDescription)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
