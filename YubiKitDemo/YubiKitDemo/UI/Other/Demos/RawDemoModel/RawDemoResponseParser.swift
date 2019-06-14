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

class RawDemoResponseParser: NSObject {

    private var response: Data
    
    /// Initializes the parser with the response from the key.
    init(response: Data) {
        self.response = response
        super.init()
    }
    
    /// Returns the SW from a key response.
    var statusCode: UInt16 {
        get {
            guard response.count >= 2 else {
                return 0x00
            }
            return UInt16(response[response.count - 2]) << 8 + UInt16(response[response.count - 1])
        }
    }
    
    /// Returns the data from a key response without the SW.
    var responseData: Data? {
        get {
            guard response.count > 2 else {
                return nil
            }
            return response.subdata(in: 0..<response.count - 2)
        }
    }
}
