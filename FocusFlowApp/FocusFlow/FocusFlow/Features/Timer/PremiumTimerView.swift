import SwiftUI

struct PremiumTimerView: View {
    @EnvironmentObject var timerService: TimerService
    @StateObject private var viewModel: TimerViewModel
    @EnvironmentObject var appState: AppState
    
    // Haptic service for micro-interactions
    private let hapticService = HapticService.shared
    
    init() {
        // Initialize with a temporary service, will be replaced by environment object
        let tempService = TimerService()
        self._viewModel = StateObject(wrappedValue: TimerViewModel(timerService: tempService))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                // Premium Progress Ring in Glass Card
                GlassCard {
                    PremiumProgressRing(
                        progress: viewModel.progress,
                        title: viewModel.phaseTitle,
                        timeText: viewModel.timeString,
                        accent: PhaseTheme.color(for: viewModel.phaseTitle),
                        isRunning: viewModel.isRunning
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                }
                
                // Premium Control Bar in Glass Card
                GlassCard {
                    TimerControlBar(
                        isRunning: viewModel.isRunning,
                        canPause: viewModel.canPause,
                        onStart: { 
                            startAction()
                        },
                        onPause: { 
                            pauseAction()
                        },
                        onReset: { 
                            resetAction()
                        },
                        onSkip: { 
                            skipAction()
                        }
                    )
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
                colors: [Color.black.opacity(0.1), Color(.systemBackground)],
                startPoint: .topLeading, 
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            // Update viewModel with the injected timerService
            viewModel.updateTimerService(timerService)
            
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
    
    // MARK: - Action Methods with Haptics
    
    private func startAction() {
        if appState.hapticFeedback {
            hapticService.timerStart()
        }
        
        if viewModel.canResume {
            viewModel.resumeTimer()
        } else {
            viewModel.startTimer()
        }
    }
    
    private func pauseAction() {
        if appState.hapticFeedback {
            hapticService.timerPause()
        }
        viewModel.pauseTimer()
    }
    
    private func resetAction() {
        if appState.hapticFeedback {
            hapticService.impact(style: .medium)
        }
        viewModel.resetTimer()
    }
    
    private func skipAction() {
        if appState.hapticFeedback {
            hapticService.impact(style: .light)
        }
        viewModel.skipToNextPhase()
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
