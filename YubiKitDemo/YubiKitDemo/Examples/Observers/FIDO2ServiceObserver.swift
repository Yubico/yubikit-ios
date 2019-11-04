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

protocol FIDO2ServiceObserverDelegate: NSObjectProtocol {
    func fido2ServiceObserver(_ observer: FIDO2ServiceObserver, keyStateChangedTo state: YKFKeyFIDO2ServiceKeyState)
}

/*
 The FIDO2ServiceObserver is an example on how to wrap the KVO observation of the FIDO2 service key state into
 a separate class and use a delegate to notify about state changes. This example can be used to mask the KVO
 code when the target application prefers a delegate pattern.
 */
class FIDO2ServiceObserver: NSObject {
    
    private weak var delegate: FIDO2ServiceObserverDelegate?
    private var queue: DispatchQueue?
    
    private var isObservingServiceKeyStateUpdates = false
    private var fido2ServiceStateObservation: NSKeyValueObservation?
    
    init(delegate: FIDO2ServiceObserverDelegate, queue: DispatchQueue? = nil) {
        self.delegate = delegate
        self.queue = queue
        super.init()
        observeServiceKeyState = true
    }
    
    deinit {
        observeServiceKeyState = false
    }
    
    var observeServiceKeyState: Bool {
        get {
            return isObservingServiceKeyStateUpdates
        }
        set {
            guard newValue != isObservingServiceKeyStateUpdates else {
                return
            }
            isObservingServiceKeyStateUpdates = newValue
                                                
            if isObservingServiceKeyStateUpdates {
                let accessorySession = YubiKitManager.shared.accessorySession as! YKFAccessorySession
                fido2ServiceStateObservation = accessorySession.observe(\.fido2Service?.keyState, changeHandler: { [weak self] session, change in
                    self?.serviceKeyStateDidChange()
                })
            } else {
                fido2ServiceStateObservation = nil
            }
        }
    }
        
    func serviceKeyStateDidChange() {
        let queue = self.queue ?? DispatchQueue.main
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let delegate = self.delegate else {
                return
            }
            
            var state: YKFKeyFIDO2ServiceKeyState = .idle
            if let fido2Service = YubiKitManager.shared.accessorySession.fido2Service {
                state = fido2Service.keyState
            }
            delegate.fido2ServiceObserver(self, keyStateChangedTo: state)
        }
    }
}
