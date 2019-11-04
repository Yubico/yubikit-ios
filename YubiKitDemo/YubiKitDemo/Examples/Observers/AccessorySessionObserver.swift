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

protocol AccessorySessionObserverDelegate: NSObjectProtocol {
    func accessorySessionObserver(_ observer: AccessorySessionObserver, sessionStateChangedTo state: YKFAccessorySessionState)
}

/*
 The AccessorySessionObserver is an example on how to wrap the KVO observation of the Key Session into a separate
 class and use a delegate to notify about state changes. This example can be used to mask the KVO code when
 the target application prefers a delegate pattern.
 */
class AccessorySessionObserver: NSObject {
    
    private weak var delegate: AccessorySessionObserverDelegate?
    private var queue: DispatchQueue?

    private var isObservingSessionStateUpdates = false
    private var accessorySessionStateObservation: NSKeyValueObservation?

    init(delegate: AccessorySessionObserverDelegate, queue: DispatchQueue? = nil) {
        self.delegate = delegate
        self.queue = queue
        super.init()
        observeSessionState = true
    }
    
    deinit {
        observeSessionState = false
    }
    
    var observeSessionState: Bool {
        get {
            return isObservingSessionStateUpdates
        }
        set {
            guard newValue != isObservingSessionStateUpdates else {
                return
            }
            isObservingSessionStateUpdates = newValue
                        
            if isObservingSessionStateUpdates {
                let accessorySession = YubiKitManager.shared.accessorySession as! YKFAccessorySession
                accessorySessionStateObservation = accessorySession.observe(\.sessionState, changeHandler: { [weak self] session, change in
                    self?.accessorySessionStateDidChange()
                })
            } else {
                accessorySessionStateObservation = nil
            }
        }
    }
        
    func accessorySessionStateDidChange() {
        let queue = self.queue ?? DispatchQueue.main
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let delegate = self.delegate else {
                return
            }
            
            let state = YubiKitManager.shared.accessorySession.sessionState
            delegate.accessorySessionObserver(self, sessionStateChangedTo: state)
        }
    }
}
