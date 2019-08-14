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

enum MFIKeyInteractionViewControllerState {
    case insertKey
    case touchKey
    case processing
}

class MFIKeyInteractionViewController: RootViewController, MFIKeyActionSheetViewDelegate {

    private var mfiKeyActionSheetView: MFIKeyActionSheetView?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selector = #selector(applicationWillResignActive)
        let notificationName = UIApplication.willResignActiveNotification        
        NotificationCenter.default.addObserver(self, selector: selector, name: notificationName, object: nil)
    }
    
    deinit {
        let notificationName = UIApplication.willResignActiveNotification
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
        
        // Remove observations.
        observeSessionStateUpdates = false
        observeFIDO2ServiceStateUpdates = false
    }
    
    // MARK: - Application Events
    
    @objc func applicationWillResignActive() {
        dismissMFIKeyActionSheet()
    }
    
    // MARK: - State
    
    private func set(state: MFIKeyInteractionViewControllerState, message: String) {
        guard let actionSheet = mfiKeyActionSheetView else {
            return
        }
        switch state {
        case .insertKey:
            actionSheet.animateInsertKey(message: message)
        case .touchKey:
            actionSheet.animateTouchKey(message: message)
        case .processing:
            actionSheet.animateProcessing(message: message)
        }
    }
    
    // MARK: - Orientation
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (context) in
            self?.updateActionSheetOrientation()
        }, completion: nil)
    }
    
    private func updateActionSheetOrientation() {
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        self.mfiKeyActionSheetView?.updateInterfaceOrientation(orientation: interfaceOrientation)
    }
    
    // MARK: - Actionsheet Presenting
    
    func presentMFIKeyActionSheet(state: MFIKeyInteractionViewControllerState, message: String, completion: @escaping ()->Void = {}) {
        guard mfiKeyActionSheetView == nil else {
            set(state: state, message: message)
            completion()
            return
        }
        
        mfiKeyActionSheetView = MFIKeyActionSheetView.loadViewFromNib()
        
        if let actionSheet = mfiKeyActionSheetView, let parentView = UIApplication.shared.keyWindow {
            actionSheet.delegate = self
            actionSheet.frame = parentView.bounds
            parentView.addSubview(actionSheet)
            
            actionSheet.present(animated: true, completion: completion)
            set(state: state, message: message)
        } else {
            fatalError()
        }
        
        updateActionSheetOrientation()
    }
    
    func dismissMFIKeyActionSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        guard let actionSheet = mfiKeyActionSheetView else {
            completion()
            return
        }
        actionSheet.dismiss(animated: true, delayed: delayed) { [weak self] in
            guard let self = self else {
                return
            }
            if let lightingActionSheet = self.mfiKeyActionSheetView {
                lightingActionSheet.removeFromSuperview()
                self.mfiKeyActionSheetView = nil
            }
            completion()
        }
    }
    
    func dismissMFIKeyActionSheetAndShow(message: String) {
        dismissMFIKeyActionSheet { [weak self] in
            self?.present(message: message)
        }
    }
    
    // MARK: - MFIKeyActionSheetViewDelegate
    
    func mfiKeyActionSheetDidDismiss(_ actionSheet: MFIKeyActionSheetView) {
        dismissMFIKeyActionSheet(delayed: false, completion: {})
    }
    
    // MARK: - State Observation
    
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
            let keyPath = #keyPath(YKFKeySession.sessionState)
            
            if isObservingSessionStateUpdates {
                keySession.addObserver(self, forKeyPath: keyPath, options: [], context: &MFIKeyInteractionViewController.observationContext)
            } else {
                keySession.removeObserver(self, forKeyPath: keyPath)
            }
        }
    }
    
    private var isObservingFIDO2ServiceStateUpdates = false
    
    var observeFIDO2ServiceStateUpdates: Bool {
        get {
            return isObservingFIDO2ServiceStateUpdates
        }
        set {
            guard newValue != isObservingFIDO2ServiceStateUpdates else {
                return
            }
            isObservingFIDO2ServiceStateUpdates = newValue
            
            let keySession = YubiKitManager.shared.keySession as AnyObject
            let keyPath = #keyPath(YKFKeySession.fido2Service.keyState)
            
            if isObservingFIDO2ServiceStateUpdates {
                keySession.addObserver(self, forKeyPath: keyPath, options: [], context: &MFIKeyInteractionViewController.observationContext)
            } else {
                keySession.removeObserver(self, forKeyPath: keyPath)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &MFIKeyInteractionViewController.observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case #keyPath(YKFKeySession.sessionState):
            DispatchQueue.main.async { [weak self] in
                self?.keySessionStateDidChange()
            }
        case #keyPath(YKFKeySession.fido2Service.keyState):
            DispatchQueue.main.async { [weak self] in
                self?.fido2ServiceStateDidChange()
            }
        default:
            fatalError()
        }
    }
    
    func keySessionStateDidChange() {
        fatalError("Override the keySessionStateDidChange() to get Key Session state updates.")
    }
    
    func fido2ServiceStateDidChange() {
        fatalError("Override the fido2ServiceStateDidChange() to get FIDO2 Service state updates.")
    }
}
