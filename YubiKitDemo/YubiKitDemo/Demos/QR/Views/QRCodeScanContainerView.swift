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

enum QRCodeWaitingScanViewState {
    case notSupported
    case waitingForScan
    case scanResult
}

class QRCodeScanContainerView: UIView {
    
    private var currentState: QRCodeWaitingScanViewState = .notSupported
    private(set) var scanResultsView: QRCodeScanResultsView?
    
    func show(state: QRCodeWaitingScanViewState) {
        clearContainer()
        switch state {
        case .notSupported:
            showQRCodeScanNotSupported()
            currentState = .notSupported
            break
        case .waitingForScan:
            showWaitingForScan()
            currentState = .waitingForScan
            break
        case .scanResult:
            showScanResult()
            currentState = .scanResult
            break
        }
    }
    
    // MARK: State setup
    
    private func clearContainer() {
        for view in subviews {
            view.removeFromSuperview()
        }
        scanResultsView = nil
    }
    
    private func showQRCodeScanNotSupported() {
        let view = Bundle.main.loadNibNamed("QRCodeScanNotAvailableView", owner: nil, options: nil)?.first as! UIView
        setContained(view: view)
    }
    
    private func showWaitingForScan() {
        let view = Bundle.main.loadNibNamed("QRCodeScanWaitingView", owner: nil, options: nil)?.first as! UIView
        setContained(view: view)
    }
    
    private func showScanResult() {
        let view = Bundle.main.loadNibNamed("QRCodeScanResultsView", owner: nil, options: nil)?.first as! QRCodeScanResultsView
        scanResultsView = view
        setContained(view: view)
    }
    
    private func setContained(view: UIView) {
        view.frame = bounds
        addSubview(view)
    }
}
