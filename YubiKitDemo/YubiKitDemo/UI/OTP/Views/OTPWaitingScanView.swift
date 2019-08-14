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

class OTPWaitingScanView: UIView {
    
    @IBOutlet var messageLabel: UILabel!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else {
            return
        }
        if YubiKitDeviceCapabilities.supportsNFCScanning {
            messageLabel.text = """
                                Press the Read button below and select how to read the OTP, \
                                over NFC by scanning the key or from the MFi accessory key, by inserting the key.
                                """
        } else {
            messageLabel.text = """
                                Press the Read button below read the OTP from the MFi accessory key, by inserting the key.
                                """
        }
    }
}
