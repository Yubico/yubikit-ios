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

protocol KeySessionObserverDelegate: NSObjectProtocol {
    func keySessionObserver(_ observer: KeySessionObserver, sessionStateChangedTo state: YKFKeySessionState)
}

/*
 The KeySessionObserver is an example on how to wrap the KVO observation of the Key Session into a separate
 class and use a delegate to notify about state changes. This example can be used to mask the KVO code when
 the target application prefers a delegate pattern.
 */
class KeySessionObserver: NSObject {
    
    private weak var delegate: KeySessionObserverDelegate?
    private var queue: DispatchQueue?

    private static var observationContext = 0
    private var isObservingSessionStateUpdates = false

    init(delegate: KeySessionObserverDelegate, queue: DispatchQueue? = nil) {
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
            
            let keySession = YubiKitManager.shared.keySession as AnyObject
            let keyPath = #keyPath(YKFKeySession.sessionState)
            
            if isObservingSessionStateUpdates {
                keySession.addObserver(self, forKeyPath: keyPath, options: [], context: &KeySessionObserver.observationContext)
            } else {
                keySession.removeObserver(self, forKeyPath: keyPath)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &KeySessionObserver.observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case #keyPath(YKFKeySession.sessionState):
            keySessionStateDidChange()
        default:
            fatalError()
        }
    }
    
    func keySessionStateDidChange() {
        let queue = self.queue ?? DispatchQueue.main
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let delegate = self.delegate else {
                return
            }
            
            let state = YubiKitManager.shared.keySession.sessionState
            delegate.keySessionObserver(self, sessionStateChangedTo: state)
        }
    }
}
