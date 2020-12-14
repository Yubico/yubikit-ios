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

import SwiftUI

struct CredentialView: View {
    
    let credential: Credential
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(credential.otp ?? "*** ***").font(.title)
            Text("\(credential.issuer ?? "") \(credential.accountName)").font(.headline).foregroundColor(.gray)
        }.padding(10)
    }
}


struct CredentialView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialView(credential:Credential.previewCredentials().randomElement()!)
    }
}
