import Foundation
import FirebaseFirestore
import Combine

class TimerService: ObservableObject {
    @Published var currentSession: TimerSession?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: TimerSession.SessionType = .focus
    @Published var completedSessions: [TimerSession] = []
    
    private let db = Firestore.firestore()
    private var userId: String?
    private let hapticService = HapticService.shared
    
    // Precise timer implementation
    private var tickTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.focusflow.timer", qos: .userInitiated)
    private var sessionStartDate: Date?
    private var accumulatedElapsed: TimeInterval = 0
    private var sessionTotalSeconds: TimeInterval = 0
    private var lastTickLogTime: Date = Date()
    
    // Reference to AppState for settings
    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize with default focus duration
        timeRemaining = TimeInterval(25 * 60) // 25 minutes default
    }
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
        setupSettingsBindings()
        
        // Update initial duration with settings
        if !isRunning {
            timeRemaining = TimeInterval(getDuration(for: currentPhase) * 60)
        }
        
        print("[TimerService] Connected to AppState for settings")
    }
    
    func setUserId(_ uid: String) {
        self.userId = uid
        loadLastSession()
    }
    
    private func setupSettingsBindings() {
        guard let appState = appState else { return }
        
        // Listen to settings changes and update the current phase duration if not running
        appState.settingsViewModel.$pomodoroDurations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isRunning else { return }
                // Update time remaining for current phase with new settings
                self.timeRemaining = TimeInterval(self.getDuration(for: self.currentPhase) * 60)
                print("[TimerService] settings updated \(self.currentPhase)")
            }
            .store(in: &cancellables)
    }
    
    private func onTick() {
        // Compute elapsed using sessionStartDate + accumulatedElapsed for correctness
        guard !isPaused, isRunning else { return }
        let now = Date()
        let elapsed = accumulatedElapsed + (now.timeIntervalSince(sessionStartDate ?? now))
        let remaining = max(sessionTotalSeconds - elapsed, 0)
        
        // Update model on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timeRemaining = remaining
            
            // Update progress based on total seconds to preserve original behavior
            let total = max(self.sessionTotalSeconds, 1)
            let progress = 1.0 - (remaining / total)
            
            // Log every ~5 seconds to avoid spam
            let now = Date()
            if now.timeIntervalSince(self.lastTickLogTime) >= 5.0 {
                print("[TimerService] tick t-\(Int(remaining))s")
                self.lastTickLogTime = now
            }
            
            // Live Activity update (keep the existing controller calls/shape)
            let phaseNameForUpdate: String = {
                switch self.currentPhase {
                case .focus: return "Focus"
                case .shortBreak: return "Short Break"
                case .longBreak: return "Long Break"
                }
            }()
            
            FocusActivityController.shared.updateLiveActivity(
                phase: phaseNameForUpdate,
                remaining: remaining,
                progress: progress,
                isRunning: !self.isPaused
            )
            
            if remaining <= 0.001 {
                self.completeSession()
            }
        }
    }
    
    func startSession(type: TimerSession.SessionType? = nil) {
        let sessionType = type ?? currentPhase
        let duration = getDuration(for: sessionType)
        
        print("[TimerService] start \(sessionType) \(duration)min")
        
        // ALWAYS invalidate and nil out any existing timers before creating new one
        tickTimer?.cancel()
        tickTimer = nil
        
        let session = TimerSession(
            duration: duration,
            type: sessionType
        )
        
        currentSession = session
        currentPhase = sessionType
        sessionTotalSeconds = TimeInterval(duration * 60)
        timeRemaining = sessionTotalSeconds
        sessionStartDate = Date()
        accumulatedElapsed = 0
        isRunning = true
        isPaused = false
        
        // Create DispatchSourceTimer on timerQueue
        tickTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        tickTimer?.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(100))
        tickTimer?.setEventHandler { [weak self] in self?.onTick() }
        tickTimer?.resume()
        
        // Live Activity: Start
        let phaseName: String = {
            switch currentPhase {
            case .focus: return "Focus"
            case .shortBreak: return "Short Break"
            case .longBreak: return "LongBreak"
            }
        }()

        FocusActivityController.shared.startLiveActivity(
            phase: phaseName,
            totalDuration: sessionTotalSeconds
        )
        
        // Haptic feedback (if enabled)
        if appState?.hapticFeedback == true {
            hapticService.timerStart()
        }
        
        // Save session to Firestore
        saveSessionToFirestore(session)
    }
    
    func pauseSession() {
        guard isRunning && !isPaused else { return }
        
        // Update accumulatedElapsed with time since session started/resumed
        accumulatedElapsed += Date().timeIntervalSince(sessionStartDate ?? Date())
        isPaused = true
        
        print("[TimerService] pause")
        
        // Cancel DispatchSourceTimer
        tickTimer?.cancel()
        tickTimer = nil
        
        // Live Activity: Update to show paused state
        let total = TimeInterval(getDuration(for: currentPhase) * 60)
        let remaining = max(timeRemaining, 0)
        let progress = total > 0 ? (1.0 - (remaining / total)) : 0.0

        let phaseNameForPause: String = {
            switch currentPhase {
            case .focus: return "Focus"
            case .shortBreak: return "Short Break"
            case .longBreak: return "Long Break"
            }
        }()

        FocusActivityController.shared.updateLiveActivity(
            phase: phaseNameForPause,
            remaining: remaining,
            progress: progress,
            isRunning: false // Show as paused
        )
        
        // Haptic feedback (if enabled)
        if appState?.hapticFeedback == true {
            hapticService.timerPause()
        }
        
        // Update session in Firestore
        updateSessionInFirestore()
    }
    
    func resumeSession() {
        guard isRunning && isPaused else { return }
        
        // Reset session start date for elapsed calculation
        sessionStartDate = Date()
        isPaused = false
        
        print("[TimerService] resume")
        
        // Recreate the DispatchSourceTimer exactly as in startSession()
        tickTimer?.cancel()
        tickTimer = nil
        
        tickTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        tickTimer?.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(100))
        tickTimer?.setEventHandler { [weak self] in self?.onTick() }
        tickTimer?.resume()
        
        // Live Activity: Update to show running state
        let total = TimeInterval(getDuration(for: currentPhase) * 60)
        let remaining = max(timeRemaining, 0)
        let progress = total > 0 ? (1.0 - (remaining / total)) : 0.0

        let phaseNameForResume: String = {
            switch currentPhase {
            case .focus: return "Focus"
            case .shortBreak: return "Short Break"
            case .longBreak: return "Long Break"
            }
        }()

        FocusActivityController.shared.updateLiveActivity(
            phase: phaseNameForResume,
            remaining: remaining,
            progress: progress,
            isRunning: true // Show as running again
        )
        
        // Haptic feedback (if enabled)
        if appState?.hapticFeedback == true {
            hapticService.timerStart()
        }
        
        // Update session in Firestore
        updateSessionInFirestore()
    }
    
    func resetSession() {
        print("[TimerService] reset")
        
        // Cancel & nil tickTimer safely
        tickTimer?.cancel()
        tickTimer = nil
        
        isRunning = false
        isPaused = false
        timeRemaining = 0
        accumulatedElapsed = 0
        sessionStartDate = nil
        
        // End Live Activity
        FocusActivityController.shared.endLiveActivity()
        
        // Haptic feedback (if enabled)
        if appState?.hapticFeedback == true {
            hapticService.impact(style: .medium)
        }
        
        // Delete incomplete session from Firestore
        if let session = currentSession, !session.isCompleted {
            deleteSessionFromFirestore(session)
        }
        
        currentSession = nil
    }
    
    func skipToNextPhase() {
        guard let session = currentSession else { return }
        
        // Haptic feedback (if enabled)
        if appState?.hapticFeedback == true {
            hapticService.phaseTransition()
        }
        
        // Complete current session
        completeSession()
        
        // Determine next phase
        let nextPhase: TimerSession.SessionType
        switch session.type {
        case .focus:
            // After focus, alternate between short and long breaks
            let focusCount = completedSessions.filter { $0.type == .focus }.count
            nextPhase = (focusCount % 4 == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            nextPhase = .focus
        }
        
        // Start next phase
        startSession(type: nextPhase)
    }
    
    private func completeSession() {
        guard let session = currentSession else { return }
        
        print("[TimerService] complete")
        
        // Cancel & nil tickTimer safely
        tickTimer?.cancel()
        tickTimer = nil
        
        isRunning = false
        isPaused = false
        accumulatedElapsed = 0
        sessionStartDate = nil
        
        // End Live Activity
        FocusActivityController.shared.endLiveActivity()
        
        // Haptic feedback (if enabled)
        if appState?.hapticFeedback == true {
            hapticService.timerComplete()
        }
        
        // Mark session as completed
        var completedSession = session
        completedSession = TimerSession(
            id: session.id,
            startTime: session.startTime,
            endTime: Date(),
            duration: session.duration,
            type: session.type,
            isCompleted: true,
            taskId: session.taskId,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
        
        // Save completed session to Firestore
        saveCompletedSessionToFirestore(completedSession)
        
        // Add to completed sessions
        completedSessions.append(completedSession)
        
        // Clear current session
        currentSession = nil
        timeRemaining = 0
        
        // Auto-start next phase if enabled
        handleAutoStart(completedPhase: session.type)
    }
    
    private func handleAutoStart(completedPhase: TimerSession.SessionType) {
        guard let appState = appState else { return }
        
        let shouldAutoStart: Bool
        let nextPhase: TimerSession.SessionType
        
        switch completedPhase {
        case .focus:
            // After focus, start break if auto-start break is enabled
            shouldAutoStart = appState.autoStartBreak
            let focusCount = completedSessions.filter { $0.type == .focus }.count
            nextPhase = (focusCount % 4 == 0) ? .longBreak : .shortBreak
            
        case .shortBreak, .longBreak:
            // After break, start focus if auto-start next pomodoro is enabled
            shouldAutoStart = appState.autoStartNextPomodoro
            nextPhase = .focus
        }
        
        if shouldAutoStart {
            print("[TimerService] auto-start \(nextPhase)")
            // Delay slightly to allow UI to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startSession(type: nextPhase)
            }
        } else {
            // Just update the current phase for the UI
            currentPhase = nextPhase
            timeRemaining = TimeInterval(getDuration(for: nextPhase) * 60)
        }
    }
    
    private func getDuration(for type: TimerSession.SessionType) -> Int {
        guard let appState = appState else {
            // Fallback to default values if no appState
            switch type {
            case .focus: return 25
            case .shortBreak: return 5
            case .longBreak: return 15
            }
        }
        
        switch type {
        case .focus: return appState.focusDuration
        case .shortBreak: return appState.shortBreakDuration
        case .longBreak: return appState.longBreakDuration
        }
    }
    
    // MARK: - Firestore Operations
    
    private func saveSessionToFirestore(_ session: TimerSession) {
        guard let userId = userId else { return }
        
        let sessionRef = db.collection("users").document(userId)
            .collection("sessions").document(session.id)
        
        sessionRef.setData(session.firestoreData) { error in
            if let error = error {
                print("[Firebase] save session error: \(error)")
            }
        }
    }
    
    private func updateSessionInFirestore() {
        guard let session = currentSession else { return }
        
        var updatedSession = session
        updatedSession = TimerSession(
            id: session.id,
            startTime: session.startTime,
            endTime: nil,
            duration: session.duration,
            type: session.type,
            isCompleted: false,
            taskId: session.taskId,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
        
        saveSessionToFirestore(updatedSession)
    }
    
    private func saveCompletedSessionToFirestore(_ session: TimerSession) {
        guard let userId = userId else { return }
        
        let sessionRef = db.collection("users").document(userId)
            .collection("sessions").document(session.id)
        
        sessionRef.setData(session.firestoreData) { error in
            if let error = error {
                print("[Firebase] save completed session error: \(error)")
            }
        }
    }
    
    private func deleteSessionFromFirestore(_ session: TimerSession) {
        guard let userId = userId else { return }
        
        let sessionRef = db.collection("users").document(userId)
            .collection("sessions").document(session.id)
        
        sessionRef.delete { error in
            if let error = error {
                print("[Firebase] delete session error: \(error)")
            }
        }
    }
    
    private func loadLastSession() {
        guard let userId = userId else { return }
        
        let sessionsRef = db.collection("users").document(userId)
            .collection("sessions")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
        
        sessionsRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("[Firebase] load session error: \(error)")
                return
            }
            
            guard let document = snapshot?.documents.first else { return }
            
            if let session = TimerSession.fromFirestore(document.data(), id: document.documentID) {
                // Only restore if session is not completed and not too old (within last hour)
                let oneHourAgo = Date().addingTimeInterval(-3600)
                if !session.isCompleted && session.createdAt > oneHourAgo {
                    DispatchQueue.main.async {
                        self?.restoreSession(session)
                    }
                }
            }
        }
    }
    
    private func restoreSession(_ session: TimerSession) {
        currentSession = session
        currentPhase = session.type
        
        // Calculate remaining time
        let elapsed = Date().timeIntervalSince(session.startTime)
        let totalDuration = TimeInterval(session.duration * 60)
        timeRemaining = max(0, totalDuration - elapsed)
        
        // If there's still time remaining, resume the session
        if timeRemaining > 0 {
            isRunning = true
            isPaused = false
            
            // Use the modern DispatchSourceTimer approach
            tickTimer = DispatchSource.makeTimerSource(queue: timerQueue)
            tickTimer?.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(100))
            tickTimer?.setEventHandler { [weak self] in self?.onTick() }
            tickTimer?.resume()
        } else {
            // Session has expired, complete it
            completeSession()
        }
    }
    
    deinit {
        tickTimer?.cancel()
    }
}
