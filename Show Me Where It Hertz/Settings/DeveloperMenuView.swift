//
//  DeveloperMenuView.swift
//  OSTRich
//
//  Created by snow on 8/28/24.
//

import SwiftUI
import SwiftData

struct DeveloperMenuView: View {
    
    var body: some View {
        List {
            Section("Convenience") {
            }
            
        }
        .onAppear {
            Analytics.track(.openedDeveloperMenu)
        }
        .navigationTitle("Developer")
    }
    
}

#Preview {
    DeveloperMenuView()
}
