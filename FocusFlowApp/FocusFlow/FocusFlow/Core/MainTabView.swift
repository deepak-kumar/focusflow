import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.activeTab) {
            TimerView()
                .tabItem {
                    Image(systemName: AppState.Tab.timer.icon)
                    Text(AppState.Tab.timer.title)
                }
                .tag(AppState.Tab.timer)
            
            TasksView()
                .tabItem {
                    Image(systemName: AppState.Tab.tasks.icon)
                    Text(AppState.Tab.tasks.title)
                }
                .tag(AppState.Tab.tasks)
            
            StatsView()
                .tabItem {
                    Image(systemName: AppState.Tab.stats.icon)
                    Text(AppState.Tab.stats.title)
                }
                .tag(AppState.Tab.stats)
            
            SettingsView()
                .tabItem {
                    Image(systemName: AppState.Tab.settings.icon)
                    Text(AppState.Tab.settings.title)
                }
                .tag(AppState.Tab.settings)
        }
        .accentColor(.blue)
        .onAppear {
            // Apply glassmorphism styling to tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
