import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var activeTab: Tab = .timer
    @Published var theme: Theme = .system
    
    // Settings ViewModel - shared across the app
    @Published var settingsViewModel = SettingsViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSettingsBinding()
    }
    
    private func setupSettingsBinding() {
        // Bind settings theme to app state theme
        settingsViewModel.$appearance
            .map { $0.theme }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settingsTheme in
                switch settingsTheme {
                case .system:
                    self?.theme = .system
                case .light:
                    self?.theme = .light
                case .dark:
                    self?.theme = .dark
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Access Properties
    
    var currentSettings: SettingsViewModel {
        return settingsViewModel
    }
    
    // Computed properties for easy access to settings
    var focusDuration: Int {
        settingsViewModel.pomodoroDurations.focusDuration
    }
    
    var shortBreakDuration: Int {
        settingsViewModel.pomodoroDurations.shortBreakDuration
    }
    
    var longBreakDuration: Int {
        settingsViewModel.pomodoroDurations.longBreakDuration
    }
    
    var autoStartBreak: Bool {
        settingsViewModel.behaviour.autoStartBreak
    }
    
    var autoStartNextPomodoro: Bool {
        settingsViewModel.behaviour.autoStartNextPomodoro
    }
    
    var hapticFeedback: Bool {
        settingsViewModel.appearance.hapticFeedback
    }
    
    var soundEffects: Bool {
        settingsViewModel.appearance.soundEffects
    }
    
    func setUserId(_ uid: String) {
        print("[AppState] set userId:\(uid)")
        settingsViewModel.setUserId(uid)
        
        // Also set currentUser if not already set
        if currentUser == nil {
            currentUser = User(uid: uid, isAnonymous: true, createdAt: Date())
        }
    }
    
    enum Tab: Int, CaseIterable {
        case timer = 0
        case tasks = 1
        case stats = 2
        case settings = 3
        
        var title: String {
            switch self {
            case .timer: return "Timer"
            case .tasks: return "Tasks"
            case .stats: return "Stats"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .timer: return "timer"
            case .tasks: return "checklist"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape"
            }
        }
    }
    
    enum Theme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        case custom = "custom"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            case .custom: return nil
            }
        }
    }
}

struct User {
    let uid: String
    let isAnonymous: Bool
    let createdAt: Date
}
