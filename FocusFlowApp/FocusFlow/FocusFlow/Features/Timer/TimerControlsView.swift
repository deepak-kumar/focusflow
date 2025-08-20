import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    private let hapticService = HapticService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Main control buttons
            HStack(spacing: 24) {
                // Start/Pause/Resume button
                Button(action: {
                    hapticService.buttonTap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if viewModel.canStart {
                            viewModel.startTimer()
                        } else if viewModel.canPause {
                            viewModel.pauseTimer()
                        } else if viewModel.canResume {
                            viewModel.resumeTimer()
                        }
                    }
                }) {
                    Image(systemName: buttonIcon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(buttonColor)
                                .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .scaleEffect(buttonScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: buttonScale)
                
                // Reset button
                Button(action: {
                    hapticService.buttonTap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.resetTimer()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .opacity(viewModel.canReset ? 1.0 : 0.5)
                .scaleEffect(viewModel.canReset ? 1.0 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.canReset)
                
                // Skip button
                Button(action: {
                    hapticService.buttonTap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.skipToNextPhase()
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .opacity(viewModel.canSkip ? 1.0 : 0.5)
                .scaleEffect(viewModel.canSkip ? 1.0 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.canSkip)
            }
            
            // Quick start buttons
            HStack(spacing: 16) {
                QuickStartButton(
                    title: "Focus",
                    color: .blue,
                    action: { 
                        hapticService.buttonTap()
                        viewModel.startFocusSession() 
                    }
                )
                
                QuickStartButton(
                    title: "Short Break",
                    color: .green,
                    action: { 
                        hapticService.buttonTap()
                        viewModel.startShortBreak() 
                    }
                )
                
                QuickStartButton(
                    title: "Long Break",
                    color: .purple,
                    action: { 
                        hapticService.buttonTap()
                        viewModel.startLongBreak() 
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Computed Properties
    
    private var buttonIcon: String {
        if viewModel.canStart {
            return "play.fill"
        } else if viewModel.canPause {
            return "pause.fill"
        } else if viewModel.canResume {
            return "play.fill"
        } else {
            return "play.fill"
        }
    }
    
    private var buttonColor: Color {
        if viewModel.canStart {
            return .blue
        } else if viewModel.canPause {
            return .orange
        } else if viewModel.canResume {
            return .green
        } else {
            return .blue
        }
    }
    
    private var buttonScale: Double {
        if viewModel.isRunning || viewModel.isPaused {
            return 1.0
        } else {
            return 0.95
        }
    }
}

struct QuickStartButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: true)
    }
}

#Preview {
    TimerControlsView(viewModel: TimerViewModel(timerService: TimerService()))
        .background(Color.black.opacity(0.1))
}
