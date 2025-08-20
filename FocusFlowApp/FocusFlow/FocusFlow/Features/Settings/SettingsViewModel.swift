import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

class SettingsViewModel: ObservableObject {
    @Published var pomodoroDurations = PomodoroDurations()
    @Published var behaviour = Behaviour()
    @Published var appearance = Appearance()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    private var settingsListener: ListenerRegistration?
    
    // MARK: - Data Models
    
    struct PomodoroDurations: Codable {
        var focusDuration: Int = 25
        var shortBreakDuration: Int = 5
        var longBreakDuration: Int = 15
    }
    
    struct Behaviour: Codable {
        var autoStartBreak: Bool = false
        var autoStartNextPomodoro: Bool = false
        var dailyGoal: Int = 8
    }
    
    struct Appearance: Codable {
        var theme: Theme = .system
        var hapticFeedback: Bool = true
        var soundEffects: Bool = true
    }
    
    enum Theme: String, CaseIterable, Codable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "gear"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
    
    init() {
        setupUserId()
    }
    
    private func setupUserId() {
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
            loadSettings()
        }
    }
    
    func setUserId(_ uid: String) {
        self.userId = uid
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func updateFocusDuration(_ duration: Int) {
        pomodoroDurations.focusDuration = duration
        saveSettings()
        print("SettingsViewModel: Updated focus duration to \(duration) minutes")
    }
    
    func updateShortBreakDuration(_ duration: Int) {
        pomodoroDurations.shortBreakDuration = duration
        saveSettings()
        print("SettingsViewModel: Updated short break duration to \(duration) minutes")
    }
    
    func updateLongBreakDuration(_ duration: Int) {
        pomodoroDurations.longBreakDuration = duration
        saveSettings()
        print("SettingsViewModel: Updated long break duration to \(duration) minutes")
    }
    
    func toggleAutoStartBreak() {
        behaviour.autoStartBreak.toggle()
        saveSettings()
        print("SettingsViewModel: Updated auto-start break to \(behaviour.autoStartBreak)")
    }
    
    func toggleAutoStartNextPomodoro() {
        behaviour.autoStartNextPomodoro.toggle()
        saveSettings()
        print("SettingsViewModel: Updated auto-start next Pomodoro to \(behaviour.autoStartNextPomodoro)")
    }
    
    func updateDailyGoal(_ goal: Int) {
        behaviour.dailyGoal = goal
        saveSettings()
        print("SettingsViewModel: Updated daily goal to \(goal) Pomodoros")
    }
    
    func updateTheme(_ theme: Theme) {
        appearance.theme = theme
        saveSettings()
        print("SettingsViewModel: Updated theme to \(theme.displayName)")
    }
    
    func toggleHapticFeedback() {
        appearance.hapticFeedback.toggle()
        saveSettings()
        print("SettingsViewModel: Updated haptic feedback to \(appearance.hapticFeedback)")
    }
    
    func toggleSoundEffects() {
        appearance.soundEffects.toggle()
        saveSettings()
        print("SettingsViewModel: Updated sound effects to \(appearance.soundEffects)")
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        guard let userId = userId else { return }
        
        isLoading = true
        
        // Remove existing listener
        settingsListener?.remove()
        
        // Listen to settings document
        let settingsRef = db.collection("users").document(userId).collection("settings").document("user_settings")
        
        settingsListener = settingsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load settings: \(error.localizedDescription)"
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    // Load existing settings
                    self.loadSettingsFromSnapshot(snapshot)
                } else {
                    // Create default settings
                    self.createDefaultSettings()
                }
            }
        }
    }
    
    private func loadSettingsFromSnapshot(_ snapshot: DocumentSnapshot) {
        guard let data = snapshot.data() else { return }
        
        print("SettingsViewModel: Loading settings from snapshot: \(data)")
        
        // Load Pomodoro durations
        if let durationsData = data["pomodoroDurations"] as? [String: Any] {
            let oldFocus = pomodoroDurations.focusDuration
            let oldShortBreak = pomodoroDurations.shortBreakDuration
            let oldLongBreak = pomodoroDurations.longBreakDuration
            
            pomodoroDurations.focusDuration = durationsData["focusDuration"] as? Int ?? 25
            pomodoroDurations.shortBreakDuration = durationsData["shortBreakDuration"] as? Int ?? 5
            pomodoroDurations.longBreakDuration = durationsData["longBreakDuration"] as? Int ?? 15
            
            print("SettingsViewModel: Pomodoro durations updated - Focus: \(oldFocus) → \(pomodoroDurations.focusDuration), Short: \(oldShortBreak) → \(pomodoroDurations.shortBreakDuration), Long: \(oldLongBreak) → \(pomodoroDurations.longBreakDuration)")
        }
        
        // Load behaviour settings
        if let behaviourData = data["behaviour"] as? [String: Any] {
            behaviour.autoStartBreak = behaviourData["autoStartBreak"] as? Bool ?? false
            behaviour.autoStartNextPomodoro = behaviourData["autoStartNextPomodoro"] as? Bool ?? false
            behaviour.dailyGoal = behaviourData["dailyGoal"] as? Int ?? 4
            print("SettingsViewModel: Behaviour settings loaded - Auto-start break: \(behaviour.autoStartBreak), Auto-start next: \(behaviour.autoStartNextPomodoro), Daily goal: \(behaviour.dailyGoal)")
        }
        
        // Load appearance settings
        if let appearanceData = data["appearance"] as? [String: Any] {
            if let themeString = appearanceData["theme"] as? String,
               let theme = Theme(rawValue: themeString) {
                appearance.theme = theme
                print("SettingsViewModel: Theme loaded: \(theme.rawValue)")
            }
            appearance.hapticFeedback = appearanceData["hapticFeedback"] as? Bool ?? true
            appearance.soundEffects = appearanceData["soundEffects"] as? Bool ?? true
            print("SettingsViewModel: Appearance settings loaded - Haptic: \(appearance.hapticFeedback), Sound: \(appearance.soundEffects)")
        }
    }
    
    private func createDefaultSettings() {
        // Settings will be saved when first modified
        saveSettings()
    }
    
    private func saveSettings() {
        guard let userId = userId else { 
            print("SettingsViewModel: No userId available, cannot save settings")
            return 
        }
        
        print("SettingsViewModel: Saving settings to Firestore for user \(userId)")
        
        let settingsRef = db.collection("users").document(userId).collection("settings").document("user_settings")
        
        let settingsData: [String: Any] = [
            "pomodoroDurations": [
                "focusDuration": pomodoroDurations.focusDuration,
                "shortBreakDuration": pomodoroDurations.shortBreakDuration,
                "longBreakDuration": pomodoroDurations.longBreakDuration
            ],
            "behaviour": [
                "autoStartBreak": behaviour.autoStartBreak,
                "autoStartNextPomodoro": behaviour.autoStartNextPomodoro,
                "dailyGoal": behaviour.dailyGoal
            ],
            "appearance": [
                "theme": appearance.theme.rawValue,
                "hapticFeedback": appearance.hapticFeedback,
                "soundEffects": appearance.soundEffects
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        print("SettingsViewModel: Settings data to save: \(settingsData)")
        
        settingsRef.setData(settingsData, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("SettingsViewModel: Failed to save settings: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to save settings: \(error.localizedDescription)"
                } else {
                    print("SettingsViewModel: Settings saved successfully to Firestore")
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    deinit {
        settingsListener?.remove()
    }
}
