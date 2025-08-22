import SwiftUI

/// Premium control bar with 6 clear buttons: Focus, Short Break, Long Break, Pause/Resume, Reset, Skip
/// Each button has premium styling, never wraps text, and scales well with Dynamic Type
struct PremiumTimerControlBar: View {
    @EnvironmentObject var timerService: TimerService

    var body: some View {
        VStack(spacing: 16) {
            // Top row: Focus, Short Break, Long Break
            HStack(spacing: 12) {
                premiumButton(
                    title: "Focus",
                    icon: "brain.head.profile",
                    color: PhaseTheme.color(for: "Focus"),
                    action: { timerService.startSession(type: .focus) }
                )
                
                premiumButton(
                    title: "Short Break",
                    icon: "cup.and.saucer",
                    color: PhaseTheme.color(for: "Short Break"),
                    action: { timerService.startSession(type: .shortBreak) }
                )
                
                premiumButton(
                    title: "Long Break",
                    icon: "figure.walk",
                    color: PhaseTheme.color(for: "Long Break"),
                    action: { timerService.startSession(type: .longBreak) }
                )
            }
            
            // Bottom row: Pause/Resume, Reset, Skip
            HStack(spacing: 12) {
                // Pause/Resume button - ALWAYS VISIBLE, toggles based on timer state
                let isRunning = timerService.isRunning
                let isPaused = timerService.isPaused
                let canPause = isRunning && !isPaused        // running → can pause
                let canResume = isRunning && isPaused        // paused  → can resume
                let isEnabled = canPause || canResume        // enabled only if one action is possible
                let label = canResume ? "Resume" : "Pause"   // dynamic label
                let icon = canResume ? "play.fill" : "pause.fill"
                
                premiumButton(
                    title: label,
                    icon: icon,
                    color: .orange,
                    action: {
                        if canPause {
                            timerService.pauseSession()
                        } else if canResume {
                            timerService.resumeSession()
                        }
                    },
                    style: .accent
                )
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.55)
                
                premiumButton(
                    title: "Reset",
                    icon: "arrow.counterclockwise",
                    color: .secondary,
                    action: { timerService.resetSession() },
                    style: .neutral
                )
                
                premiumButton(
                    title: "Skip",
                    icon: "forward.end.fill",
                    color: .secondary,
                    action: { timerService.skipToNextPhase() },
                    style: .neutral
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    
    enum ButtonStyle {
        case accent, neutral
    }
    
    @ViewBuilder
    private func premiumButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void,
        style: ButtonStyle = .accent
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(style == .accent ? .white : color)
                    .shadow(color: style == .accent ? color.opacity(0.5) : .clear, radius: 4)
                
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style == .accent ? .white : color)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundGradient(for: color, style: style))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        style == .accent ? .clear : color.opacity(0.3),
                        lineWidth: style == .accent ? 0 : 1
                    )
            )
            .shadow(
                color: style == .accent ? color.opacity(0.4) : .black.opacity(0.1),
                radius: style == .accent ? 12 : 6,
                x: 0,
                y: style == .accent ? 6 : 3
            )
            .contentShape(Rectangle())               // Generous tap target
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
        }
        .buttonStyle(PremiumButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Starts \(title.lowercased()) session")
    }
    
    private func backgroundGradient(for color: Color, style: ButtonStyle) -> some ShapeStyle {
        switch style {
        case .accent:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .neutral:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.12),
                        Color.secondary.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

/// Custom button style for premium interactions
struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("Premium Timer Controls")
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
        
        GlassCard {
            PremiumTimerControlBar()
                .environmentObject(TimerService())
        }
        
        Spacer()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.black.opacity(0.05), .gray.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}