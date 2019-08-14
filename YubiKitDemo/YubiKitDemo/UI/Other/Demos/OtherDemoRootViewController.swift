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

class OtherDemoRootViewController: RootViewController {
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            YubiKitManager.shared.keySession.startSession()
            observeSessionStateUpdates = true
        } else {
            present(message: "This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            observeSessionStateUpdates = false
            YubiKitManager.shared.keySession.cancelCommands()
        }
    }
    
    deinit {
        observeSessionStateUpdates = false
    }
    
    // MARK: - Key State Observation
    
    private static var observationContext = 0
    private var isObservingSessionStateUpdates = false
    
    var observeSessionStateUpdates: Bool {
        get {
            return isObservingSessionStateUpdates
        }
        set {
            guard newValue != isObservingSessionStateUpdates else {
                return
            }
            isObservingSessionStateUpdates = newValue
            
            let keySession = YubiKitManager.shared.keySession as AnyObject
            let sessionStateKeyPath = #keyPath(YKFKeySession.sessionState)
            
            if isObservingSessionStateUpdates {
                keySession.addObserver(self, forKeyPath: sessionStateKeyPath, options: [], context: &OtherDemoRootViewController.observationContext)
            } else {
                keySession.removeObserver(self, forKeyPath: sessionStateKeyPath)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &OtherDemoRootViewController.observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case #keyPath(YKFKeySession.sessionState):
            DispatchQueue.main.async { [weak self] in
                self?.keySessionStateDidChange()
            }
        default:
            fatalError()
        }
    }
        
    func keySessionStateDidChange() {
        fatalError("Override the keySessionStateDidChange() to get session state updates.")
    }
}
