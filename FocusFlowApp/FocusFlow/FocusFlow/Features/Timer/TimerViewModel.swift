import Foundation
import SwiftUI
import Combine

class TimerViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: TimerSession.SessionType = .focus
    @Published var progress: Double = 0
    @Published var timeString: String = "25:00"
    @Published var phaseTitle: String = "Focus"
    @Published var phaseColor: Color = .blue
    @Published var showPhaseTransition = false
    
    private var timerService: TimerService
    private var cancellables = Set<AnyCancellable>()
    
    init(timerService: TimerService) {
        self.timerService = timerService
        setupBindings()
    }
    
    func updateTimerService(_ newService: TimerService) {
        // Cancel existing subscriptions
        cancellables.removeAll()
        
        // Update the service
        self.timerService = newService
        
        // Setup new bindings
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind timer service properties
        timerService.$timeRemaining
            .sink { [weak self] time in
                self?.timeRemaining = time
                self?.updateTimeString()
                self?.updateProgress()
            }
            .store(in: &cancellables)
        
        timerService.$isRunning
            .sink { [weak self] running in
                self?.isRunning = running
            }
            .store(in: &cancellables)
        
        timerService.$isPaused
            .sink { [weak self] paused in
                self?.isPaused = paused
            }
            .store(in: &cancellables)
        
        timerService.$currentPhase
            .sink { [weak self] phase in
                self?.currentPhase = phase
                self?.updatePhaseInfo()
                self?.animatePhaseTransition()
            }
            .store(in: &cancellables)
        
        timerService.$currentSession
            .sink { [weak self] session in
                if let session = session {
                    self?.timeRemaining = self?.timerService.timeRemaining ?? 0
                    self?.currentPhase = session.type
                    self?.updatePhaseInfo()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startTimer() {
        timerService.startSession()
    }
    
    func pauseTimer() {
        timerService.pauseSession()
    }
    
    func resumeTimer() {
        timerService.resumeSession()
    }
    
    func resetTimer() {
        timerService.resetSession()
    }
    
    func skipToNextPhase() {
        timerService.skipToNextPhase()
    }
    
    func startFocusSession() {
        timerService.startSession(type: .focus)
    }
    
    func startShortBreak() {
        timerService.startSession(type: .shortBreak)
    }
    
    func startLongBreak() {
        timerService.startSession(type: .longBreak)
    }
    
    // MARK: - Private Methods
    
    private func updateTimeString() {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        timeString = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateProgress() {
        guard let session = timerService.currentSession else {
            progress = 0
            return
        }
        
        let totalDuration = TimeInterval(session.duration * 60)
        let elapsed = totalDuration - timeRemaining
        progress = elapsed / totalDuration
    }
    
    private func updatePhaseInfo() {
        phaseTitle = currentPhase.displayName
        phaseColor = getColorForPhase(currentPhase)
    }
    
    private func getColorForPhase(_ phase: TimerSession.SessionType) -> Color {
        switch phase {
        case .focus: return .blue
        case .shortBreak: return .green
        case .longBreak: return .purple
        }
    }
    
    private func animatePhaseTransition() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showPhaseTransition = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.showPhaseTransition = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var canStart: Bool {
        return !isRunning && !isPaused
    }
    
    var canPause: Bool {
        return isRunning && !isPaused
    }
    
    var canResume: Bool {
        return isPaused
    }
    
    var canReset: Bool {
        return isRunning || isPaused || timeRemaining > 0
    }
    
    var canSkip: Bool {
        return isRunning || isPaused
    }
    
    var progressAngle: Double {
        return progress * 360
    }
    
    var remainingAngle: Double {
        return 360 - progressAngle
    }
}
