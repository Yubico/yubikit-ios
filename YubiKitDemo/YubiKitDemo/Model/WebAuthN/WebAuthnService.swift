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

class WebAuthnService: NSObject {
    
    static let origin = "https://demo.yubico.com"
    
    private static let appSharedSession: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfiguration.httpMaximumConnectionsPerHost = 1
        
        return URLSession(configuration: sessionConfiguration)
    }()
    
    private var urlSession: URLSession {
        get {
            return WebAuthnService.appSharedSession
        }
    }
    
    // MARK: - User
    
    func createUserWith(request: WebAuthnUserRequest, completion: @escaping (WebAuthnCreateUserResponse?, Error?) -> Void)  {
       execute(request: request, completion: completion)
    }

    func loginUserWith(request: WebAuthnUserRequest, completion: @escaping (WebAuthnLoginUserResponse?, Error?) -> Void)  {
       execute(request: request, completion: completion)
    }
    
    // MARK: - Registration
    
    func registerBeginWith(request: WebAuthnRegisterBeginRequest, completion: @escaping (WebAuthnRegisterBeginResponse?, Error?) -> Void) {
       execute(request: request, completion: completion)
    }
    
    func registerFinishWith(request: WebAuthnRegisterFinishRequest, completion: @escaping (WebAuthnRegisterFinishResponse?, Error?) -> Void) {
        execute(request: request, completion: completion)
    }
    
    // MARK: - Authentication
    
    func authenticateBeginWith(request: WebAuthnAuthenticateBeginRequest, completion: @escaping (WebAuthnAuthenticateBeginResponse?, Error?) -> Void) {
        execute(request: request, completion: completion)
    }

    func authenticateFinishWith(request: WebAuthnAuthenticateFinishRequest, completion: @escaping (WebAuthnAuthenticateFinishResponse?, Error?) -> Void) {
        execute(request: request, completion: completion)
    }
    
    // MARK: - Helpers
    
    func cancelAllRequests() {
        urlSession.getTasksWithCompletionHandler { (dataTasks, _, _) in
            for dataTask in dataTasks {
                dataTask.cancel()
            }
        }
    }
    
    private func execute<T: WebAuthnResponseProtocol>(request: WebAuthnRequest, completion: @escaping (T?, Error?) -> Void) {
        guard let urlRequest = request.urlRequest else {
            completion(nil, WebServiceError.malformedRequestError())
            return
        }
        execute(request: urlRequest) { (data, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let data = data else {
                fatalError()
            }
            guard let requestResponse = T(response: data) else {
                completion(nil, WebServiceError.malformedResponseError())
                return
            }
            completion(requestResponse, nil)
        }
    }
    
    private func execute(request: URLRequest, completion: @escaping (Data?, Error?) -> Void) {
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError()
            }
            
            guard !(300...399).contains(httpResponse.statusCode) && !(500...599).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(nil, WebServiceError.serverError())
                }
                return
            }
            guard !(400...499).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(nil, WebServiceError(data: data))
                }
                return
            }
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
}
