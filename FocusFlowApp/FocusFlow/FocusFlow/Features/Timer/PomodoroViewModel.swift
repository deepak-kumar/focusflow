import Foundation
import SwiftUI
import Combine
import ActivityKit

class PomodoroViewModel: ObservableObject {
    @Published var selectedTask: Task?
    @Published var isTaskSelectionVisible = false
    @Published var currentSession: TimerSession?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: TimerPhase = .focus
    @Published var progress: Double = 0.0

    private var timer: Timer?
    private var taskService: TaskService
    private var settingsViewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    enum TimerPhase: String, CaseIterable {
        case focus = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"
        
        func duration(settings: SettingsViewModel) -> TimeInterval {
            switch self {
            case .focus: return TimeInterval(settings.pomodoroDurations.focusDuration * 60)
            case .shortBreak: return TimeInterval(settings.pomodoroDurations.shortBreakDuration * 60)
            case .longBreak: return TimeInterval(settings.pomodoroDurations.longBreakDuration * 60)
            }
        }
        
        var color: Color {
            switch self {
            case .focus: return .blue
            case .shortBreak: return .green
            case .longBreak: return .orange
            }
        }
    }
    
    init(taskService: TaskService, settingsViewModel: SettingsViewModel) {
        self.taskService = taskService
        self.settingsViewModel = settingsViewModel
        
        // Initialize with current settings
        self.timeRemaining = TimeInterval(settingsViewModel.pomodoroDurations.focusDuration * 60)
        
        setupBindings()
        
        print("[PomodoroViewModel] initialized with settings focus:\(settingsViewModel.pomodoroDurations.focusDuration)min short:\(settingsViewModel.pomodoroDurations.shortBreakDuration)min long:\(settingsViewModel.pomodoroDurations.longBreakDuration)min")
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    
    func selectTask(_ task: Task?) {
        selectedTask = task
        isTaskSelectionVisible = false
    }
    
    func startTimer() {
        guard !isRunning else { return }
        
        let phaseDuration = currentPhase.duration(settings: settingsViewModel)
        
        // Create new session
        let session = TimerSession(
            startTime: Date(),
            duration: Int(phaseDuration),
            type: getSessionType(),
            taskId: selectedTask?.id
        )
        
        currentSession = session
        timeRemaining = phaseDuration
        isRunning = true
        isPaused = false
        
        // Start Live Activity when timer starts
        FocusActivityController.shared.startLiveActivity(
            phase: currentPhase.rawValue,
            totalDuration: TimeInterval(timeRemaining)
        )
        
        startTimerInternal()
        
        print("[PomodoroViewModel] starting \(currentPhase.rawValue) timer for \(Int(phaseDuration/60)) minutes")
    }
    
    func pauseTimer() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        
        // Update Live Activity to show paused state
        FocusActivityController.shared.updateLiveActivity(
            phase: currentPhase.rawValue,
            remaining: timeRemaining,
            progress: progress,
            isRunning: false
        )
    }
    
    func resumeTimer() {
        guard isRunning, isPaused else { return }
        isPaused = false
        startTimerInternal()
        
        // Update Live Activity to show running state
        FocusActivityController.shared.updateLiveActivity(
            phase: currentPhase.rawValue,
            remaining: timeRemaining,
            progress: progress,
            isRunning: true
        )
    }
    
    func stopTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        progress = 0.0
        currentSession = nil
        // End Live Activity when timer stops
        FocusActivityController.shared.endLiveActivity()
    }
    
    func skipToNextPhase() {
        stopTimer()
        
        // Cycle through phases: Focus -> Short Break -> Long Break -> Focus
        switch currentPhase {
        case .focus:
            currentPhase = .shortBreak
        case .shortBreak:
            currentPhase = .longBreak
        case .longBreak:
            currentPhase = .focus
        }
        
        timeRemaining = currentPhase.duration(settings: settingsViewModel)
        
        FocusActivityController.shared.startLiveActivity(
            phase: (currentPhase == .focus ? "Focus" : "Break"),
            totalDuration: TimeInterval(timeRemaining)
        )
        
        progress = 0.0
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen to settings changes and update timer if needed
        settingsViewModel.$pomodoroDurations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDurations in
                print("[PomodoroViewModel] settings changed focus:\(newDurations.focusDuration)min short:\(newDurations.shortBreakDuration)min long:\(newDurations.longBreakDuration)min")
                
                // If timer is not running, update the current phase duration
                if let self = self, !self.isRunning {
                    self.timeRemaining = self.currentPhase.duration(settings: self.settingsViewModel)
                    self.progress = 0.0
                }
            }
            .store(in: &cancellables)
    }
    
    private func startTimerInternal() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard isRunning, !isPaused else { return }
        
        timeRemaining -= 1
        progress = 1.0 - (timeRemaining / currentPhase.duration(settings: settingsViewModel))
        
        // Update Live Activity with current progress
        FocusActivityController.shared.updateLiveActivity(
            phase: currentPhase.rawValue,
            remaining: timeRemaining,
            progress: progress,
            isRunning: isRunning
        )
        
        if timeRemaining <= 0 {
            timerCompleted()
        }
    }
    
    private func timerCompleted() {
        stopTimer()
        
        // End Live Activity when timer completes
        FocusActivityController.shared.endLiveActivity()

        // Update task's completedPomodoros if this was a focus session
        if currentPhase == .focus, let task = selectedTask {
            // Use AsyncTask to handle async operation
            AsyncTask {
                do {
                    try await self.taskService.incrementPomodoros(for: task)
                } catch {
                    print("[PomodoroViewModel] failed to increment pomodoros: \(error)")
                }
            }
        }
        
        // Save completed session
        if let session = currentSession {
            saveCompletedSession(session)
        }
        
        // Reset for next session
        currentSession = nil
        timeRemaining = currentPhase.duration(settings: settingsViewModel)
        progress = 0.0
    }
    
    private func saveCompletedSession(_ session: TimerSession) {
        // This would typically save to Firestore
        // For now, we'll just log it
        print("[PomodoroViewModel] session completed:\(session.id)")
    }
    
    private func getSessionType() -> TimerSession.SessionType {
        switch currentPhase {
        case .focus: return .focus
        case .shortBreak: return .shortBreak
        case .longBreak: return .longBreak
        }
    }
    
    // MARK: - Computed Properties
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var phaseTitle: String {
        return currentPhase.rawValue
    }
    
    var phaseColor: Color {
        return currentPhase.color
    }
    
    var canStartTimer: Bool {
        return !isRunning && selectedTask != nil
    }
    
    var selectedTaskTitle: String {
        return selectedTask?.title ?? "No task selected"
    }
}
