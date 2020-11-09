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

class OTPDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let otpDetailsViewControllerCellReuseID = "OTPDetailsViewControllerCell"
    private var token: YKFOTPTokenProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func displayTokenDetails(forToken token:YKFOTPTokenProtocol) {
        self.token = token
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reusableCell = tableView.dequeueReusableCell(withIdentifier: otpDetailsViewControllerCellReuseID)
        if reusableCell == nil {
            reusableCell = UITableViewCell(style: .subtitle, reuseIdentifier: otpDetailsViewControllerCellReuseID)
        }
        
        guard let cell = reusableCell else {
            fatalError()
        }
        
        switch indexPath.row {
        case 0:
            cell.textLabel!.text = "Token type"
            switch token.type {
            case .yubicoOTP:
                cell.detailTextLabel!.text = "Yubico OTP"
            break
                case .HOTP:
                cell.detailTextLabel!.text = "HOTP"
                break
            case .unknown:
                cell.detailTextLabel!.text = "Unknown"
                break
            @unknown default:
                fatalError()
            }
            break
            
        case 1:
            cell.textLabel!.text = "Metadata type"
            switch token.metadataType {
            case .text:
                cell.detailTextLabel!.text = "Text"
                break
            case .URI:
                cell.detailTextLabel!.text = "URI"
                break
            case .unknown:
                cell.detailTextLabel!.text = "Unknown"
                break
            @unknown default:
                fatalError()
            }
            break
            
        case 2:
            cell.textLabel!.text = "Value"
            cell.detailTextLabel!.text = token.value
            break
            
        case 3:
            switch token.metadataType {
            case .text:
                cell.textLabel!.text = "Text"
                cell.detailTextLabel!.text = token.text
                break
            case .URI:
                cell.textLabel!.text = "URI"
                cell.detailTextLabel!.text = token.uri
                break
            case .unknown:
                cell.textLabel!.text = "Text/URI"
                cell.detailTextLabel!.text = "no values"
                break
            @unknown default:
                fatalError()
            }
            break
            
        default:
            fatalError()
        }
        
        return cell
    }
}
