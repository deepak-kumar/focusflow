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
        print("[Settings] focus duration:\(duration)min")
    }
    
    func updateShortBreakDuration(_ duration: Int) {
        pomodoroDurations.shortBreakDuration = duration
        saveSettings()
        print("[Settings] short break duration:\(duration)min")
    }
    
    func updateLongBreakDuration(_ duration: Int) {
        pomodoroDurations.longBreakDuration = duration
        saveSettings()
        print("[Settings] long break duration:\(duration)min")
    }
    
    func toggleAutoStartBreak() {
        behaviour.autoStartBreak.toggle()
        saveSettings()
        print("[Settings] auto-start break:\(behaviour.autoStartBreak)")
    }
    
    func toggleAutoStartNextPomodoro() {
        behaviour.autoStartNextPomodoro.toggle()
        saveSettings()
        print("[Settings] auto-start next pomodoro:\(behaviour.autoStartNextPomodoro)")
    }
    
    func updateDailyGoal(_ goal: Int) {
        behaviour.dailyGoal = goal
        saveSettings()
        print("[Settings] daily goal:\(goal) pomodoros")
    }
    
    func updateTheme(_ theme: Theme) {
        appearance.theme = theme
        saveSettings()
        print("[Settings] theme:\(theme.displayName)")
    }
    
    func toggleHapticFeedback() {
        appearance.hapticFeedback.toggle()
        saveSettings()
        print("[Settings] haptic feedback:\(appearance.hapticFeedback)")
    }
    
    func toggleSoundEffects() {
        appearance.soundEffects.toggle()
        saveSettings()
        print("[Settings] sound effects:\(appearance.soundEffects)")
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
        
        print("[Settings] loading settings from snapshot")
        
        // Load Pomodoro durations
        if let durationsData = data["pomodoroDurations"] as? [String: Any] {
            let oldFocus = pomodoroDurations.focusDuration
            let oldShortBreak = pomodoroDurations.shortBreakDuration
            let oldLongBreak = pomodoroDurations.longBreakDuration
            
            pomodoroDurations.focusDuration = durationsData["focusDuration"] as? Int ?? 25
            pomodoroDurations.shortBreakDuration = durationsData["shortBreakDuration"] as? Int ?? 5
            pomodoroDurations.longBreakDuration = durationsData["longBreakDuration"] as? Int ?? 15
            
            print("[Settings] pomodoro durations updated focus:\(pomodoroDurations.focusDuration)min short:\(pomodoroDurations.shortBreakDuration)min long:\(pomodoroDurations.longBreakDuration)min")
        }
        
        // Load behaviour settings
        if let behaviourData = data["behaviour"] as? [String: Any] {
            behaviour.autoStartBreak = behaviourData["autoStartBreak"] as? Bool ?? false
            behaviour.autoStartNextPomodoro = behaviourData["autoStartNextPomodoro"] as? Bool ?? false
            behaviour.dailyGoal = behaviourData["dailyGoal"] as? Int ?? 4
            print("[Settings] behaviour settings loaded auto-start break:\(behaviour.autoStartBreak) auto-start next:\(behaviour.autoStartNextPomodoro) daily goal:\(behaviour.dailyGoal)")
        }
        
        // Load appearance settings
        if let appearanceData = data["appearance"] as? [String: Any] {
            if let themeString = appearanceData["theme"] as? String,
               let theme = Theme(rawValue: themeString) {
                appearance.theme = theme
                print("[Settings] theme loaded:\(theme.rawValue)")
            }
            appearance.hapticFeedback = appearanceData["hapticFeedback"] as? Bool ?? true
            appearance.soundEffects = appearanceData["soundEffects"] as? Bool ?? true
            print("[Settings] appearance settings loaded haptic:\(appearance.hapticFeedback) sound:\(appearance.soundEffects)")
        }
    }
    
    private func createDefaultSettings() {
        // Settings will be saved when first modified
        saveSettings()
    }
    
    private func saveSettings() {
        guard let userId = userId else { 
            print("[Settings] no userId available cannot save settings")
            return 
        }
        
        print("[Settings] saving settings to Firestore for user:\(userId)")
        
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
        
        print("[Settings] settings data to save")
        
        settingsRef.setData(settingsData, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[Settings] failed to save settings: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to save settings: \(error.localizedDescription)"
                } else {
                    print("[Settings] settings saved successfully to Firestore")
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    deinit {
        settingsListener?.remove()
    }
}
