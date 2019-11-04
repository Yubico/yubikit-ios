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

enum OTPScanDetailsViewState {
    case waitingForScan
    case scanResult
}

class OTPScanContainerView: UIView {
    
    private var currentState: OTPScanDetailsViewState = .waitingForScan
    private(set) var scanResultsView: OTPScanResultsView?
    
    func show(state: OTPScanDetailsViewState) {
        clearContainer()
        
        switch state {
        case .waitingForScan:
            showWaitingForScan()
            currentState = .waitingForScan
            
        case .scanResult:
            showScanResult()
            currentState = .scanResult
        }
    }
    
    // MARK: State setup
    
    private func clearContainer() {
        for view in subviews {
            view.removeFromSuperview()
        }
        scanResultsView = nil
    }
        
    private func showWaitingForScan() {
        let view = Bundle.main.loadNibNamed("OTPWaitingScanView", owner: nil, options: nil)?.first as! OTPWaitingScanView
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                view.yubikeyImageView.isHidden = true
            } else {
                view.yubikeyImageView.isHidden = false
            }
        } else {
            view.yubikeyImageView.isHidden = false
        }
        setContained(view: view)
    }
    
    private func showScanResult() {
        let view = Bundle.main.loadNibNamed("OTPScanResultsView", owner: nil, options: nil)?.first as! UIView
        scanResultsView = view as? OTPScanResultsView
        setContained(view: view)
    }
        
    private func setContained(view: UIView) {
        view.frame = bounds
        addSubview(view)
    }
}
