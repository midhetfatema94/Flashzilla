//
//  SettingsView.swift
//  Flashzilla
//
//  Created by Waveline Media on 1/15/21.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var reuseCards: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Toggle("Card should be re-used when answered incorrectly", isOn: $reuseCards)
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            }))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(reuseCards: .constant(false))
    }
}
