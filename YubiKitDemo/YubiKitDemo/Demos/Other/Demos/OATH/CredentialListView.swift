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
import SwiftUI

struct CredentialListView: View {
    @ObservedObject var credentialsProvider: CredentialsProvider
    
    var body: some View {
        NavigationView {
            List {
                ForEach(credentialsProvider.credentials) { credential in
                    CredentialView(credential: credential)
                }.onDelete(perform: delete)
            }
            .navigationBarTitle(Text("Accounts"))
            .navigationBarItems(leading: Button(action: { addCredential() } ) { Text("Add credential") },
                                trailing: Button(action: { credentialsProvider.refresh() } ) { Text("Refresh") }
            )
        }
    }
    
    func delete(at offsets: IndexSet) {
        let credentialsToDelete = offsets.map { credentialsProvider.credentials[$0] }
        guard let credential = credentialsToDelete.first else { return }
        credentialsProvider.delete(credential: credential)
    }
    
    func addCredential() {
        let randomNumber = arc4random() % 100
        let credential = Credential(issuer: "Yubico", accountName: "john.doe.\(randomNumber)@yubico.com", otp: nil)
        credentialsProvider.add(credential: credential)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let credentialsProvider = CredentialsProvider()
        credentialsProvider.credentials = Credential.previewCredentials()
        return CredentialListView(credentialsProvider: credentialsProvider)
    }
}
