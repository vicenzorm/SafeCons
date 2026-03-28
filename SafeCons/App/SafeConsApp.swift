//
//  SafeConsApp.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 26/03/26.
//

import SwiftUI
import SwiftData

@main
struct SafeConsApp: App {
    
    let container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .fontDesign(.monospaced)
        }
        .modelContainer(container.modelContainer)
    }
}
