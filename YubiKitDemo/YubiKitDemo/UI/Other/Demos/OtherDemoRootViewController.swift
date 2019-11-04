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
        if (YubiKitDeviceCapabilities.supportsISO7816NFCTags) {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            observeNfcSessionStateUpdates = true
        }
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            YubiKitManager.shared.accessorySession.startSession()
            observeSessionStateUpdates = true
        } else {
            present(message: "This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            observeSessionStateUpdates = false
            YubiKitManager.shared.accessorySession.cancelCommands()
        }
        
        if (YubiKitDeviceCapabilities.supportsISO7816NFCTags) {
            guard #available(iOS 13.0, *) else {
                fatalError()
            }
            observeNfcSessionStateUpdates = false
        }
    }
    
    deinit {
        observeSessionStateUpdates = false

        if #available(iOS 13.0, *) {
            observeNfcSessionStateUpdates = false
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: - Key State Observation
    
    private static var observationContext = 0
    private var isObservingSessionStateUpdates = false
    private var isNfcObservingSessionStateUpdates = false
    private var nfcSesionStateObservation: NSKeyValueObservation?

    var observeSessionStateUpdates: Bool {
        get {
            return isObservingSessionStateUpdates
        }
        set {
            guard newValue != isObservingSessionStateUpdates else {
                return
            }
            isObservingSessionStateUpdates = newValue
            
            let accessorySession = YubiKitManager.shared.accessorySession as AnyObject
            let sessionStateKeyPath = #keyPath(YKFAccessorySession.sessionState)
            
            if isObservingSessionStateUpdates {
                accessorySession.addObserver(self, forKeyPath: sessionStateKeyPath, options: [], context: &OtherDemoRootViewController.observationContext)
            } else {
                accessorySession.removeObserver(self, forKeyPath: sessionStateKeyPath)
            }
        }
    }
    
    @available(iOS 13.0, *)
    var observeNfcSessionStateUpdates: Bool {
        get {
            return isNfcObservingSessionStateUpdates
        }
        set {
            guard newValue != isNfcObservingSessionStateUpdates else {
                return
            }
            isNfcObservingSessionStateUpdates = newValue
            
            let nfcSession = YubiKitManager.shared.nfcSession as! YKFNFCSession
            if isNfcObservingSessionStateUpdates {
                self.nfcSesionStateObservation = nfcSession.observe(\.iso7816SessionState, changeHandler: { [weak self] session, change in
                    DispatchQueue.main.async { [weak self] in
                        self?.nfcSessionStateDidChange()
                    }
                })
            } else {
                self.nfcSesionStateObservation = nil
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &OtherDemoRootViewController.observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case #keyPath(YKFAccessorySession.sessionState):
            DispatchQueue.main.async { [weak self] in
                self?.accessorySessionStateDidChange()
            }
        default:
            fatalError()
        }
    }
        
    func accessorySessionStateDidChange() {
        fatalError("Override the accessorySessionStateDidChange() to get session state updates.")
    }
    
    @available(iOS 13.0, *)
    func nfcSessionStateDidChange() {
        fatalError("Override the nfcSessionStateDidChange() to get session state updates.")
    }
}
