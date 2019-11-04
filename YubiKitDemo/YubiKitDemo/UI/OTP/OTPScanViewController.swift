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
import CoreNFC
import SafariServices

class OTPScanViewController: MFIKeyInteractionViewController, OTPScanResultsViewDelegate, OTPUIResponderDelegate {
    
    private let presentTokenDetailsSegueID = "PresentTokenDetailsSegueID"
    
    private var lastScannedToken: YKFOTPTokenProtocol?
    
    private var waitingForReadingOTP = false
    private let otpUIResponder = OTPUIResponder()
    
    // MARK: - Outlets
    
    @IBOutlet var otpScanContainerView: OTPScanContainerView!
    @IBOutlet var readOTPButton: UIButton!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This will allow the otpUIResponder to notify this view controller when the OTP from the YubiKey was read.
        view.addSubview(otpUIResponder)
        otpUIResponder.delegate = self
        
        otpScanContainerView.show(state: .waitingForScan)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Make sure the session is started (in case it was closed by another demo).
            YubiKitManager.shared.accessorySession.startSession()
        
            // Enable state observation (see MFIKeyInteractionViewController)
            observeAccessorySessionStateUpdates = true
        } else {
            present(message: "This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Disable state observation (see MFIKeyInteractionViewController)
            observeAccessorySessionStateUpdates = false
        }
    }
    
    // MARK: - Actions
    
    @IBAction func readOTPButtonPressed(_ sender: Any) {
        showOTPSourceSelection()
    }
    
    // MARK: - OTP Reading Results
    
    private func processScanResult(withToken token: YKFOTPTokenProtocol?, error: Error?) {
        guard error == nil else {
            if !shouldIgnore(error: error!) {
                present(error: error!)
            }
            return
        }
        
        // Token should not be nil at this point
        assert(token != nil)
        
        let scannedToken = token!
        showScanResultView(forToken: scannedToken)
        
        lastScannedToken = scannedToken
        UIPasteboard.general.string = scannedToken.value // Copy to clipboard as well
    }
    
    private func showScanResultView(forToken token: YKFOTPTokenProtocol) {
        otpScanContainerView.show(state: .scanResult)
        if let scanResultsView = otpScanContainerView.scanResultsView {
            scanResultsView.tokenLabel.text = token.value
            scanResultsView.delegate = self
            
            let canTestToken = (token.type == .yubicoOTP && token.uri != nil)
            scanResultsView.testItButton.isEnabled = canTestToken
            scanResultsView.testItButton.borderColor = canTestToken ? NamedColor.yubicoGreenColor : UIColor.lightGray
        }
        readOTPButton.isHidden = true
    }
    
    // MARK: - OTPScanResultsViewDelegate
    
    func otpScanResultsViewDidPressMoreDetails(_ view: OTPScanResultsView) {
        guard lastScannedToken != nil else {
            return
        }
        performSegue(withIdentifier: presentTokenDetailsSegueID, sender: self)
    }
    
    func otpScanResultsViewDidPressTestIt(_ view: OTPScanResultsView) {
        guard let currentToken = lastScannedToken else {
            return
        }
        guard currentToken.type == .yubicoOTP && currentToken.uri != nil else {
            return
        }
        guard let testPageURL = URL(string: currentToken.uri!) else {
            return
        }
        
        let safariViewController = SFSafariViewController(url: testPageURL)
        present(safariViewController, animated: true) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            // Reset the scanning after testing the token since the OTP token can be verified/used only once
            strongSelf.otpScanContainerView.show(state: .waitingForScan)
            strongSelf.readOTPButton.isHidden = false
        }
    }
    
    func otpScanResultsViewDidPressRescan(_ view: OTPScanResultsView) {
        otpScanContainerView.show(state: .waitingForScan)
        readOTPButton.isHidden = false
        readOTPButtonPressed(readOTPButton as Any)
    }
    
    // MARK: - OTP Reading Options
    
    private func showOTPSourceSelection() {
        let actionSheet = UIAlertController(title: "Read OTP", message: "How do you want to read the OTP?", preferredStyle: .actionSheet)
        
        if YubiKitDeviceCapabilities.supportsNFCScanning {
            actionSheet.addAction(UIAlertAction(title: "Scan my key - Over NFC", style: .default, handler: { [weak self]  (action) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.readOTPOverNFC()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Plug my key - From MFi key", style: .default, handler: { [weak self] (action) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.readOTPFromMFIAccessoryKey()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (action) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dismiss(animated: true, completion: nil)
        }))
        
        // The action sheet requires a presentation popover on iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.modalPresentationStyle = .popover
            if let presentationController = actionSheet.popoverPresentationController {
                presentationController.sourceView = readOTPButton
                presentationController.sourceRect = readOTPButton.bounds
            }
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func readOTPOverNFC() {
        // Here is the important code snippet to ask YubiKit to scan an OTP.
        if #available(iOS 11, *) {
            YubiKitManager.shared.nfcSession.otpService.requestOTPToken { [weak self] (token, error) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.processScanResult(withToken: token, error: error)
            }
        }
    }
    
    /*
     Important Note:
        The generation of OTPs over iAP2 HID is currently an experimental feature. This feature may
        change in the final version of the firmware.
    */
    private func readOTPFromMFIAccessoryKey() {        
        // Make the otpUIResponder the first responder to intercept the OTP.
        otpUIResponder.isEnabled = true
        waitingForReadingOTP = true
        
        if YubiKitManager.shared.accessorySession.sessionState == .open {
            presentMFIKeyActionSheet(state: .touchKey, message: "Touch the key to read the OTP.")
        } else {
            presentMFIKeyActionSheet(state: .insertKey, message: "Insert the key to read the OTP.")
        }
    }
    
    // MARK: - State Observation
    
    override func accessorySessionStateDidChange() {
        guard waitingForReadingOTP else {
            return // If the view controller is not actively waiting for an OTP discard the updates.
        }
        let state = YubiKitManager.shared.accessorySession.sessionState
        
        if state == .open {
            presentMFIKeyActionSheet(state: .touchKey, message: "Touch the key to read the OTP.")
        }
        if state == .closed {
            waitingForReadingOTP = false
            otpUIResponder.isEnabled = false
            dismissMFIKeyActionSheet()
        }
    }

    // MARK: - OTPUIResponderDelegate
    
    func otpUIResponderDidStartReadingOTP(_ responder: OTPUIResponder) {
        presentMFIKeyActionSheet(state: .processing, message: "Reading the OTP from the key...")
    }
    
    func otpUIResponder(_ responder: OTPUIResponder, didReadOTP otp: String) {
        waitingForReadingOTP = false
        dismissMFIKeyActionSheet {
            let token = YKFOTPToken()
            token.type = .unknown
            token.metadataType = .unknown
            token.value = otp
            self.processScanResult(withToken: token, error: nil)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == presentTokenDetailsSegueID {
            let detailsViewController = segue.destination as! OTPDetailsViewController
            detailsViewController.displayTokenDetails(forToken: lastScannedToken!)
        }
    }
    
    // MARK: - Helpers
    
    private func shouldIgnore(error: Error) -> Bool {
        let nsError = error as NSError
        
        if #available(iOS 11, *) {
            // The user canceled the NFC scan
            return nsError.code == NFCReaderError.readerSessionInvalidationErrorUserCanceled.rawValue
        } else {
            return false
        }
    }
    
    override func dismissMFIKeyActionSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        super.dismissMFIKeyActionSheet(delayed: delayed, completion: completion)
        waitingForReadingOTP = false
        otpUIResponder.isEnabled = false
    }
}
