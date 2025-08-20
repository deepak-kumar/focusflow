import SwiftUI

/// Premium UI wrapper that mirrors TimerView functionality (Focus / Short Break / Long Break)
/// without touching business logic. It reads state from TimerService and calls existing actions.
struct PremiumTimerView: View {
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var appState: AppState
    
    // Haptic service for micro-interactions
    private let hapticService = HapticService.shared
    
    // Derive phase name and accent color just like the old TimerView
    private var phaseName: String {
        switch timerService.currentPhase {
        case .focus:       return "Focus"
        case .shortBreak:  return "Short Break"
        case .longBreak:   return "Long Break"
        @unknown default:  return "Focus"
        }
    }

    private var accent: Color {
        PhaseTheme.color(for: phaseName)
    }

    private var timeText: String {
        // Format time exactly like TimerViewModel does
        let totalSeconds = max(0, Int(timerService.timeRemaining))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var progressValue: Double {
        // Calculate progress like TimerViewModel does
        guard let session = timerService.currentSession else { return 0 }
        let totalDuration = TimeInterval(session.duration * 60)
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - timerService.timeRemaining
        return min(1, max(0, elapsed / totalDuration))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                GlassCard {
                    PremiumProgressRing(
                        progress: progressValue,
                        title: phaseName,
                        timeText: timeText,
                        accent: accent,
                        isRunning: timerService.isRunning && !timerService.isPaused
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .accessibilityIdentifier("premium-progress-ring")
                }

                GlassCard {
                    PremiumTimerControlBar(
                        onFocus: { timerService.startSession(type: .focus) },
                        onShortBreak: { timerService.startSession(type: .shortBreak) },
                        onLongBreak: { timerService.startSession(type: .longBreak) },
                        onReset: { timerService.resetSession() },
                        onSkip: { timerService.skipToNextPhase() }
                    )
                    .accessibilityIdentifier("premium-control-bar")
                }

                // Session Info (enhanced with glass card)
                if let session = timerService.currentSession {
                    GlassCard(corner: 16) {
                        PremiumSessionInfoView(session: session)
                    }
                }
                
                // Quick Stats (enhanced with glass card)
                GlassCard(corner: 16) {
                    PremiumQuickStatsView(completedSessions: timerService.completedSessions)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.08), Color(.systemBackground)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Set user ID when view appears
            if let userId = appState.currentUser?.uid {
                timerService.setUserId(userId)
            }
        }
        .onChange(of: appState.currentUser?.uid) { newUserId in
            if let userId = newUserId {
                timerService.setUserId(userId)
            }
        }
    }
}

// MARK: - Enhanced Supporting Views

struct PremiumSessionInfoView: View {
    let session: TimerSession
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Session")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(PhaseTheme.color(for: session.type.displayName))
            }
            
            HStack {
                Text("Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(session.duration) minutes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(session.startTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct PremiumQuickStatsView: View {
    let completedSessions: [TimerSession]
    
    private var focusSessions: Int {
        completedSessions.filter { $0.type == .focus }.count
    }
    
    private var totalFocusTime: Int {
        completedSessions.filter { $0.type == .focus }.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                PremiumStatCard(
                    title: "Focus Sessions",
                    value: "\(focusSessions)",
                    color: PhaseTheme.color(for: "Focus"),
                    icon: "play.circle.fill"
                )
                
                PremiumStatCard(
                    title: "Focus Time",
                    value: "\(totalFocusTime)m",
                    color: PhaseTheme.color(for: "Short Break"),
                    icon: "timer"
                )
            }
        }
    }
}

struct PremiumStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 4)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    PremiumTimerView()
        .environmentObject(AppState())
        .environmentObject(TimerService())
}
