import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

class StatsViewModel: ObservableObject {
    @Published var totalTasksCompleted = 0
    @Published var totalPomodorosCompleted = 0
    @Published var weeklyPomodoros: [DayPomodoro] = []
    @Published var currentStreak = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    
    struct DayPomodoro: Identifiable {
        let id = UUID()
        let day: String
        let count: Int
        let date: Date
    }
    
    init() {
        setupUserId()
    }
    
    private func setupUserId() {
        // Get userId from AuthService or AppState
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
            startListening()
        }
    }
    
    func setUserId(_ uid: String) {
        self.userId = uid
        startListening()
    }
    
    private func startListening() {
        guard let userId = userId else { return }
        
        // Listen to tasks
        listenToTasks(userId: userId)
        
        // Listen to sessions
        listenToSessions(userId: userId)
    }
    
    private func listenToTasks(userId: String) {
        let tasksRef = db.collection("users").document(userId).collection("tasks")
        
        tasksRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                }
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            let completedTasks = snapshot.documents.filter { doc in
                let data = doc.data()
                return data["isCompleted"] as? Bool == true
            }
            
            DispatchQueue.main.async {
                self.totalTasksCompleted = completedTasks.count
            }
        }
    }
    
    private func listenToSessions(userId: String) {
        let sessionsRef = db.collection("users").document(userId).collection("sessions")
        
        sessionsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load sessions: \(error.localizedDescription)"
                }
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            let completedSessions = snapshot.documents.filter { doc in
                let data = doc.data()
                return data["isCompleted"] as? Bool == true
            }
            
            DispatchQueue.main.async {
                self.totalPomodorosCompleted = completedSessions.count
                self.calculateWeeklyStats(from: completedSessions)
                self.calculateStreak(from: completedSessions)
            }
        }
    }
    
    private func calculateWeeklyStats(from sessions: [QueryDocumentSnapshot]) {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        var dayCounts: [String: Int] = [:]
        
        // Initialize all days with 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let dayName = self.dayName(for: date)
                dayCounts[dayName] = 0
            }
        }
        
        // Count pomodoros for each day
        for session in sessions {
            if let timestamp = session.data()["completedAt"] as? Timestamp {
                let date = timestamp.dateValue()
                
                // Check if date is within current week
                if date >= weekStart && date <= now {
                    let dayName = self.dayName(for: date)
                    dayCounts[dayName, default: 0] += 1
                }
            }
        }
        
        // Convert to array and sort by day order
        let dayOrder = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        weeklyPomodoros = dayOrder.compactMap { dayName in
            guard let count = dayCounts[dayName] else { return nil }
            let date = self.dateForDay(dayName, in: weekStart)
            return DayPomodoro(day: dayName, count: count, date: date)
        }
    }
    
    private func calculateStreak(from sessions: [QueryDocumentSnapshot]) {
        let calendar = Calendar.current
        let now = Date()
        var currentDate = now
        var streak = 0
        
        // Sort sessions by completion date (most recent first)
        let sortedSessions = sessions.compactMap { session -> Date? in
            guard let timestamp = session.data()["completedAt"] as? Timestamp else { return nil }
            return timestamp.dateValue()
        }.sorted(by: >)
        
        // Check consecutive days
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            // Check if there's a session on this day
            let hasSessionOnDay = sortedSessions.contains { sessionDate in
                sessionDate >= dayStart && sessionDate < dayEnd
            }
            
            if hasSessionOnDay {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        DispatchQueue.main.async {
            self.currentStreak = streak
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }
    
    private func dateForDay(_ dayName: String, in weekStart: Date) -> Date {
        let calendar = Calendar.current
        let dayOrder = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        guard let dayIndex = dayOrder.firstIndex(of: dayName) else { return weekStart }
        return calendar.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
    }
    
    func refreshStats() {
        guard userId != nil else { return }
        startListening()
    }
}
