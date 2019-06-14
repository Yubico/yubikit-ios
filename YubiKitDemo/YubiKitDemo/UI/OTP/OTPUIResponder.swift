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

protocol OTPUIResponderDelegate: NSObjectProtocol {
    func otpUIResponderDidStartReadingOTP(_ responder: OTPUIResponder)
    func otpUIResponder(_ responder: OTPUIResponder, didReadOTP otp: String)
}

class OTPUIResponder: UIView {
    
    private let acceptedCharacters = "cbdefghijklnrtuv\r" // modhex and return only
    private let acceptedNumbers = "0123456789"
    
    private var listOfkeyCommands: [UIKeyCommand] = []
    
    private var otp: String = ""

    weak var delegate: OTPUIResponderDelegate?
    
    private var enabled = false
    var isEnabled: Bool {
        set {
            enabled = newValue
            if enabled {
                becomeFirstResponder()
            } else {
                resignFirstResponder()
                otp = ""
            }
        }
        get {
            return enabled
        }
    }
    
    // MARK: Initializers
    
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        let commands = acceptedCharacters + acceptedNumbers
        for char in commands {
            let keyCommand = UIKeyCommand(input: String(char), modifierFlags: [], action: #selector(characterReceived(sender:)))
            listOfkeyCommands.append(keyCommand)
        }
    }
    
    // MARK: Key Commands
    
    override var keyCommands: [UIKeyCommand]? {
        get {
            return listOfkeyCommands
        }
    }
    
    @objc func characterReceived(sender: UIKeyCommand) {
        if otp.isEmpty {
            assert(delegate != nil)
            delegate!.otpUIResponderDidStartReadingOTP(self)
        }
        
        if sender.input == "\r" {
            assert(delegate != nil)
            delegate!.otpUIResponder(self, didReadOTP: otp)
            otp = ""
            return
        }
        
        otp += sender.input!
    }
    
    // MARK: First responder
    
    override var canBecomeFirstResponder: Bool {
        return enabled
    }
    
    override var canResignFirstResponder: Bool {
        return !enabled
    }
}
