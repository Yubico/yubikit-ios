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

class QRScanViewController: RootViewController, QRCodeScanResultsViewDelegate {
    
    @IBOutlet var scanQRCodeButton: UIButton!
    @IBOutlet var scanContainerView: QRCodeScanContainerView!
    
    private var lastScannedValue: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if YubiKitDeviceCapabilities.supportsQRCodeScanning {
            scanContainerView.show(state: .waitingForScan)
        } else {
            scanContainerView.show(state: .notSupported)
            scanQRCodeButton.isHidden = true
        }
    }
    
    // MARK: Actions
    
    @IBAction func scanQRCodeButtonPressed(_ sender: Any) {                
        YKFQRReaderSession.shared.scanQrCode(withPresenter: self) { [weak self] (payload, error) in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                strongSelf.present(error: error!)
                return
            }
            
            strongSelf.scanContainerView.show(state: .scanResult)
            strongSelf.lastScannedValue = payload
            
            if let scanResultsView = strongSelf.scanContainerView.scanResultsView {
                scanResultsView.tokenLabel.text = payload
                scanResultsView.delegate = self
            }
            strongSelf.scanQRCodeButton.isHidden = true
        }
    }
    
    // MARK: QRCodeScanResultsViewDelegate
    
    func qrScanResultsViewDidPressCopyToClipboard(_ view: QRCodeScanResultsView) {
        guard let currentValue = lastScannedValue else {
            return
        }
        UIPasteboard.general.string = currentValue
    }
    
    func qrScanResultsViewDidPressRescan(_ view: QRCodeScanResultsView) {
        scanContainerView.show(state: .waitingForScan)
        scanQRCodeButton.isHidden = false
    }    
}
