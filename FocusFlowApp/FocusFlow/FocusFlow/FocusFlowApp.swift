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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    init() {
        // Firebase configuration moved to AppDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.theme.colorScheme)
                .onAppear {
                    print("[App] launched theme:\(appState.theme.rawValue)")
                }
        }
    }
}
