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

extension String {
    func websafeBase64String() -> String? {
        guard let base64Data = self.data(using: .utf8) else {
            return nil
        }
        return (base64Data as NSData).ykf_websafeBase64EncodedString()
    }
}

extension Data {
    func websafeBase64String() -> String? {
        return (self as NSData).ykf_websafeBase64EncodedString()
    }
}
