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

enum FIDO2PinInputControllerType {
    case pin
    case setPin
    case changePin
}

class FIDO2PinInputController: NSObject {
    
    func showPinInputController(presenter: UIViewController, type: FIDO2PinInputControllerType,
                                completion: @escaping (String?, String?, String?, Bool) -> Void) {
        var alert: UIAlertController!
        
        switch type {
            
        case .pin:
            let title = "PIN verification required"
            let message = "Enter the key PIN."
            alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "PIN"
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Verify", style: .default, handler: { (action) in
                let pin = alert.textFields![0].text
                completion(pin, nil, nil, true)
            }))
            
        case .setPin:
            let title = "Set PIN"
            let message = "Enter and confirm the PIN to be set."
            alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "PIN"
                textField.isSecureTextEntry = true
            }
            alert.addTextField { (textField) in
                textField.placeholder = "Confirm PIN"
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Set", style: .default, handler: { (action) in
                let pin = alert.textFields![0].text
                let pinConfirmation = alert.textFields![1].text
                completion(pin, pinConfirmation, nil, true)
            }))
            
        case .changePin:
            let title = "Change PIN"
            let message = "Enter the current PIN and the new PIN to set."
            alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "Current PIN"
                textField.isSecureTextEntry = true
            }
            alert.addTextField { (textField) in
                textField.placeholder = "New PIN"
                textField.isSecureTextEntry = true
            }
            alert.addTextField { (textField) in
                textField.placeholder = "Confirm new PIN"
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (action) in
                let currentPin = alert.textFields![0].text
                let newPin = alert.textFields![1].text
                let newPinConfirmation = alert.textFields![2].text
                completion(currentPin, newPin, newPinConfirmation, true)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            completion(nil, nil, nil, false)
        }))
        presenter.present(alert, animated: true, completion: nil)
    }
}
