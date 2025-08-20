//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Created by deepak kumar on 18/08/25.
//

import SwiftUI
import Firebase

@main
struct FocusFlowApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.theme.colorScheme)
                .onAppear {
                    print("FocusFlowApp: App launched with theme: \(appState.theme.rawValue)")
                }
        }
    }
}
