import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission Management
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            // If already authorized, return true
            if settings.authorizationStatus == .authorized {
                completion(true)
                return
            }
            
            // Request permission
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("[NotificationManager] Permission request failed: \(error)")
                }
                completion(granted)
            }
        }
    }
    
    // MARK: - Session Completion Notifications
    
    func scheduleSessionCompletionNotification(for sessionType: TimerSession.SessionType) {
        requestNotificationPermission { [weak self] granted in
            guard granted else {
                print("[NotificationManager] Notifications not authorized")
                return
            }
            
            guard let self = self else { return }
            
            let content = self.createNotificationContent(for: sessionType)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "session-completion-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("[NotificationManager] Failed to schedule notification: \(error)")
                } else {
                    print("[NotificationManager] Scheduled \(sessionType) completion notification")
                }
            }
        }
    }
    
    private func createNotificationContent(for sessionType: TimerSession.SessionType) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        
        switch sessionType {
        case .focus:
            content.title = "Focus Complete"
            content.body = "Great job! Time to take a break."
            content.sound = .default
        case .shortBreak:
            content.title = "Short Break Over"
            content.body = "Let's get back to focus."
            content.sound = .default
        case .longBreak:
            content.title = "Long Break Over"
            content.body = "Ready to tackle your next focus session?"
            content.sound = .default
        }
        
        return content
    }
    
    // MARK: - Cleanup
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("[NotificationManager] Removed all pending notifications")
    }
    
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("[NotificationManager] Removed all delivered notifications")
    }
}
