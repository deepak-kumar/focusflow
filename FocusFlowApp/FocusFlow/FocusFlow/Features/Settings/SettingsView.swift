import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    private var viewModel: SettingsViewModel {
        appState.settingsViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Customize your FocusFlow experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Pomodoro Durations Section
                    SettingsSection(title: "Pomodoro Durations", icon: "timer") {
                        VStack(spacing: 20) {
                            // Focus Duration
                            DurationSettingRow(
                                title: "Focus Duration",
                                subtitle: "Length of focus sessions",
                                value: viewModel.pomodoroDurations.focusDuration,
                                range: 15...60,
                                unit: "min",
                                onValueChanged: { viewModel.updateFocusDuration($0) }
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Short Break Duration
                            DurationSettingRow(
                                title: "Short Break",
                                subtitle: "Length of short breaks",
                                value: viewModel.pomodoroDurations.shortBreakDuration,
                                range: 1...15,
                                unit: "min",
                                onValueChanged: { viewModel.updateShortBreakDuration($0) }
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Long Break Duration
                            DurationSettingRow(
                                title: "Long Break",
                                subtitle: "Length of long breaks",
                                value: viewModel.pomodoroDurations.longBreakDuration,
                                range: 10...30,
                                unit: "min",
                                onValueChanged: { viewModel.updateLongBreakDuration($0) }
                            )
                        }
                    }
                    
                    // Behaviour Section
                    SettingsSection(title: "Behaviour", icon: "brain.head.profile") {
                        VStack(spacing: 20) {
                            // Auto-start break
                            ToggleSettingRow(
                                title: "Auto-start Break",
                                subtitle: "Automatically start break after focus",
                                isOn: viewModel.behaviour.autoStartBreak,
                                onToggle: viewModel.toggleAutoStartBreak
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Auto-start next Pomodoro
                            ToggleSettingRow(
                                title: "Auto-start Next",
                                subtitle: "Automatically start next Pomodoro",
                                isOn: viewModel.behaviour.autoStartNextPomodoro,
                                onToggle: viewModel.toggleAutoStartNextPomodoro
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Daily Goal
                            StepperSettingRow(
                                title: "Daily Goal",
                                subtitle: "Target Pomodoros per day",
                                value: viewModel.behaviour.dailyGoal,
                                range: 1...20,
                                onValueChanged: { viewModel.updateDailyGoal($0) }
                            )
                        }
                    }
                    
                    // Appearance Section
                    SettingsSection(title: "Appearance", icon: "paintbrush") {
                        VStack(spacing: 20) {
                            // Theme Selection
                            ThemeSelectionRow(
                                selectedTheme: viewModel.appearance.theme,
                                onThemeSelected: { viewModel.updateTheme($0) }
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Haptic Feedback
                            ToggleSettingRow(
                                title: "Haptic Feedback",
                                subtitle: "Vibrate on interactions",
                                isOn: viewModel.appearance.hapticFeedback,
                                onToggle: viewModel.toggleHapticFeedback
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Sound Effects
                            ToggleSettingRow(
                                title: "Sound Effects",
                                subtitle: "Play sounds for notifications",
                                isOn: viewModel.appearance.soundEffects,
                                onToggle: viewModel.toggleSoundEffects
                            )
                        }
                    }
                    
                    // Debug Section (temporary)
                    #if DEBUG
                    SettingsSection(title: "Debug Tools", icon: "wrench") {
                        NavigationLink(destination: LiveActivityDebugView()) {
                            HStack {
                                Image(systemName: "ladybug")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Live Activity Debug")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Test Live Activity functionality")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    #endif
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .refreshable {
                // Refresh settings
            }
        }
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Section Content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DurationSettingRow: View {
    let title: String
    let subtitle: String
    let value: Int
    let range: ClosedRange<Int>
    let unit: String
    let onValueChanged: (Int) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .frame(minWidth: 40)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Could add custom picker here
        }
        
        // Slider for duration adjustment
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { onValueChanged(Int($0)) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .accentColor(.blue)
            
            HStack {
                Text("\(range.lowerBound)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(range.upperBound)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ToggleSettingRow: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
}

struct StepperSettingRow: View {
    let title: String
    let subtitle: String
    let value: Int
    let range: ClosedRange<Int>
    let onValueChanged: (Int) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .frame(minWidth: 30)
                
                Stepper("", value: Binding(
                    get: { value },
                    set: { onValueChanged($0) }
                ), in: range)
                .labelsHidden()
            }
        }
    }
}

struct ThemeSelectionRow: View {
    let selectedTheme: SettingsViewModel.Theme
    let onThemeSelected: (SettingsViewModel.Theme) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Theme")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(SettingsViewModel.Theme.allCases, id: \.self) { theme in
                    ThemeOptionButton(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        onTap: { onThemeSelected(theme) }
                    )
                }
            }
        }
    }
}

struct ThemeOptionButton: View {
    let theme: SettingsViewModel.Theme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
