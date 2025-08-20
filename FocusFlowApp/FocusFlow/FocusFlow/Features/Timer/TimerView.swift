import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerService: TimerService
    @StateObject private var viewModel: TimerViewModel
    @EnvironmentObject var appState: AppState
    
    init() {
        // Initialize with a temporary service, will be replaced by environment object
        let tempService = TimerService()
        self._viewModel = StateObject(wrappedValue: TimerViewModel(timerService: tempService))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Pomodoro Timer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Stay focused, take breaks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Circular Progress
                CircularProgressView(
                    progress: viewModel.progress,
                    timeString: viewModel.timeString,
                    phaseTitle: viewModel.phaseTitle,
                    phaseColor: viewModel.phaseColor,
                    showPhaseTransition: viewModel.showPhaseTransition
                )
                .padding(.vertical, 20)
                
                // Timer Controls
                TimerControlsView(viewModel: viewModel)
                    .padding(.bottom, 20)
                
                // Session Info
                if let session = timerService.currentSession {
                    SessionInfoView(session: session)
                        .padding(.horizontal, 20)
                }
                
                // Quick Stats
                QuickStatsView(completedSessions: timerService.completedSessions)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05)
                ]),
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
}

struct SessionInfoView: View {
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
                    .foregroundColor(getColorForPhase(session.type))
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func getColorForPhase(_ phase: TimerSession.SessionType) -> Color {
        switch phase {
        case .focus: return .blue
        case .shortBreak: return .green
        case .longBreak: return .purple
        }
    }
}

struct QuickStatsView: View {
    let completedSessions: [TimerSession]
    
    private var focusSessions: Int {
        completedSessions.filter { $0.type == .focus }.count
    }
    
    private var totalFocusTime: Int {
        completedSessions.filter { $0.type == .focus }.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Focus Sessions",
                value: "\(focusSessions)",
                color: .blue,
                icon: "play.circle.fill"
            )
            
            StatCard(
                title: "Focus Time",
                value: "\(totalFocusTime)m",
                color: .green,
                icon: "timer"
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TimerView()
        .environmentObject(AppState())
}
