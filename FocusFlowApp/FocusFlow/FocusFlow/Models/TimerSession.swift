import Foundation
import FirebaseFirestore

struct TimerSession: Identifiable, Codable {
    let id: String
    let startTime: Date
    let endTime: Date?
    let duration: Int // in minutes
    let type: SessionType
    let isCompleted: Bool
    let taskId: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum SessionType: String, Codable, CaseIterable {
        case focus = "focus"
        case shortBreak = "shortBreak"
        case longBreak = "longBreak"
        
        var displayName: String {
            switch self {
            case .focus: return "Focus"
            case .shortBreak: return "Short Break"
            case .longBreak: return "Long Break"
            }
        }
        
        var defaultDuration: Int {
            switch self {
            case .focus: return 25
            case .shortBreak: return 5
            case .longBreak: return 15
            }
        }
        
        var color: String {
            switch self {
            case .focus: return "blue"
            case .shortBreak: return "green"
            case .longBreak: return "purple"
            }
        }
    }
    
    init(id: String = UUID().uuidString,
         startTime: Date = Date(),
         endTime: Date? = nil,
         duration: Int,
         type: SessionType,
         isCompleted: Bool = false,
         taskId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.type = type
        self.isCompleted = isCompleted
        self.taskId = taskId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Firestore conversion
    var firestoreData: [String: Any] {
        return [
            "id": id,
            "startTime": Timestamp(date: startTime),
            "endTime": endTime != nil ? Timestamp(date: endTime!) : NSNull(),
            "duration": duration,
            "type": type.rawValue,
            "isCompleted": isCompleted,
            "taskId": taskId ?? NSNull(),
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    static func fromFirestore(_ data: [String: Any], id: String) -> TimerSession? {
        guard let startTimeData = data["startTime"] as? Timestamp,
              let duration = data["duration"] as? Int,
              let typeRaw = data["type"] as? String,
              let type = SessionType(rawValue: typeRaw),
              let isCompleted = data["isCompleted"] as? Bool,
              let createdAtData = data["createdAt"] as? Timestamp,
              let updatedAtData = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        let endTime = (data["endTime"] as? Timestamp)?.dateValue()
        let taskId = data["taskId"] as? String
        
        return TimerSession(
            id: id,
            startTime: startTimeData.dateValue(),
            endTime: endTime,
            duration: duration,
            type: type,
            isCompleted: isCompleted,
            taskId: taskId,
            createdAt: createdAtData.dateValue(),
            updatedAt: updatedAtData.dateValue()
        )
    }
}
