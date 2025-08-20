import Foundation
import UserNotifications

class FocusActivityController: ObservableObject {
    static let shared = FocusActivityController()
    
    private init() {}
    
    // MARK: - Live Activity Management (Placeholder)
    
    func startLiveActivity(phase: String, duration: TimeInterval) {
        print("Live Activity not implemented yet - Phase: \(phase), Duration: \(duration)")
        // For now, just schedule a notification as fallback
        NotificationService.shared.scheduleCompletionNotification(
            title: "Focus Session",
            body: "\(phase) session completed!",
            timeInterval: duration
        )
    }
    
    func updateLiveActivity(remaining: TimeInterval) {
        print("Live Activity update not implemented yet - Remaining: \(remaining)")
    }
    
    func endLiveActivity() {
        print("Live Activity end not implemented yet")
        NotificationService.shared.cancelCompletionNotification()
    }
    
    // MARK: - Helper Methods
    
    var hasActiveActivity: Bool {
        return false
    }
    
    var currentActivityId: String? {
        return nil
    }
}

// MARK: - Notification Service (Fallback)

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func scheduleCompletionNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "pomodoro-completion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Completion notification scheduled for \(Int(timeInterval)) seconds")
            }
        }
    }
    
    func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoro-completion"]
        )
        print("Completion notification cancelled")
    }
}