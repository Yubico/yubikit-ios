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

class OtherDemosTableViewController: UITableViewController {

    private let otherDemosTableViewCellReuseIdentifier = "OtherDemosTableViewCell"
    
    // MARK: - Segues
    
    private let otherDemosPCSCDemoSegueID = "OtherDemosPCSCDemoSegueID"
    private let otherDemosRawCommandsDemoSegueID = "OtherDemosRawCommandsDemoSegueID"
    
    private let otherDemosFIDO2DemoSegueID = "OtherDemosFIDO2DemoSegueID"
    private let otherDemosU2FDemoSegueID = "OtherDemosU2FDemoSegueID"
    
    // MARK: - UITableDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 2
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reusableCell = tableView.dequeueReusableCell(withIdentifier: otherDemosTableViewCellReuseIdentifier)
        if reusableCell == nil {
            reusableCell = UITableViewCell(style: .subtitle, reuseIdentifier: otherDemosTableViewCellReuseIdentifier)
        }
        
        guard let cell = reusableCell else {
            fatalError()
        }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "PC/SC Demo"
                cell.detailTextLabel!.text = "Reads a PIV certificate using the PC/SC-like interface."
                break
                
            case 1:
                cell.textLabel!.text = "Raw Commands Demo"
                cell.detailTextLabel!.text = "Reads a PIV certificate using the Raw Commands Service."
                break
                
            default:
                fatalError()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "FIDO2 Demo"
                cell.detailTextLabel!.text = "A collection of small, self-contained FIDO2 demos."
                break
                
            case 1:
                cell.textLabel!.text = "U2F Demo"
                cell.detailTextLabel!.text = "Self-contained U2F demo for creating a credential and getting an assertion."
                break
                
            default:
                fatalError()
            }
        default:
            fatalError()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Raw Command Demos"
        case 1:
            return "FIDO Demos"
        default:
            fatalError()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: otherDemosPCSCDemoSegueID, sender: self)
            case 1:
                performSegue(withIdentifier: otherDemosRawCommandsDemoSegueID, sender: self)
            default:
                fatalError()
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: otherDemosFIDO2DemoSegueID, sender: self)
            case 1:
                performSegue(withIdentifier: otherDemosU2FDemoSegueID, sender: self)
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
}
