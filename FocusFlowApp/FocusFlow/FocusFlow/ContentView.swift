//
//  ContentView.swift
//  FocusFlow
//
//  Created by deepak kumar on 18/08/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthService()
    @StateObject private var timerService = TimerService()
    @StateObject private var taskService = TaskService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                // Loading view while authenticating
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Setting up FocusFlow...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding()
            }
        }
        .environmentObject(appState)
        .environmentObject(authService)
        .environmentObject(timerService)
        .environmentObject(taskService)
        .onAppear {
            // Connect AuthService with AppState
            print("ContentView: Connecting AuthService with AppState")
            authService.setAppState(appState)
            
            // Connect TimerService with AppState
            print("ContentView: Connecting TimerService with AppState")
            timerService.setAppState(appState)
            
            // Connect current user to settings
            if let userId = appState.currentUser?.uid {
                print("ContentView: Setting userId for SettingsViewModel: \(userId)")
                appState.setUserId(userId)
            }
        }
        .onChange(of: appState.currentUser?.uid) { newUserId in
            if let userId = newUserId {
                print("ContentView: User ID changed, updating SettingsViewModel: \(userId)")
                appState.setUserId(userId)
            }
        }
        .task {
            // Sign in anonymously on app launch
            print("ContentView: Starting anonymous sign in")
            do {
                try await authService.signInAnonymously()
                print("ContentView: Anonymous sign in completed successfully")
            } catch {
                print("Failed to sign in anonymously: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
