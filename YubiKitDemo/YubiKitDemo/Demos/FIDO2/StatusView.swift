// Copyright 2018-2020 Yubico AB
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


import Foundation
import UIKit

class StatusView: UIView {
    enum State {
        case message(String)
        case insertKey
        case touchKey
        case processingKey
        case hidden
    }
    
    enum Accessory {
        case checkmark
        case error
        case none
    }
    
    private var currentState = State.hidden
    private let progressView = ProgressHudView()
    private let accessoryKeyView = MFIKeyActionSheetView()
    
    var state: State {
        set {
            DispatchQueue.main.async { [self] in
                currentState = state
                self.isHidden = false
                switch newValue {
                case .message(let message):
                    self.progressView.startAnimating()
                    self.isHidden = false
                    progressView.alpha = 1
                    accessoryKeyView.alpha = 0
                    progressView.message = message
                case .insertKey:
                    self.isHidden = false
                    progressView.alpha = 0
                    accessoryKeyView.alpha = 1
                    accessoryKeyView.animateInsertKey(message: "Insert key")
                case .touchKey:
                    self.isHidden = false
                    progressView.alpha = 0
                    accessoryKeyView.alpha = 1
                    accessoryKeyView.animateTouchKey(message: "Touch key")
                case .processingKey:
                    self.isHidden = false
                    progressView.alpha = 0
                    accessoryKeyView.alpha = 1
                    accessoryKeyView.animateProcessing(message: "Processing...")
                case .hidden:
                    self.isHidden = true
                }
            }
        }
        get {
            return currentState
        }
    }
    
    func dismiss(message: String = "", accessory: Accessory = .none, delay: TimeInterval = 0.0) {
        DispatchQueue.main.async { [self] in
            self.progressView.stopAnimating()
            progressView.message = message
            switch accessory {
            case .checkmark:
                progressView.showCheckmark = true
                progressView.showError = false
            case .error:
                progressView.showCheckmark = false
                progressView.showError = true
            case .none:
                break
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            self.state = .hidden
            progressView.showCheckmark = false
            progressView.showError = false
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.embed(progressView)
        self.embed(accessoryKeyView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UIView {
    func presentStatusView() -> StatusView {
        let statusView = StatusView()
        embed(statusView)
        return statusView
    }
}
