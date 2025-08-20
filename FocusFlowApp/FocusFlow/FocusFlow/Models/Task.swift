import Foundation
import FirebaseFirestore

// MARK: - Task Status for Filtering
enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case active, completed, archived
    var id: String { rawValue }
}

// MARK: - Task Priority (Enhanced)
enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
}

struct Task: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var notes: String
    var isCompleted: Bool
    var isArchived: Bool
    var priority: TaskPriority
    var estimatedPomodoros: Int
    var completedPomodoros: Int
    var linkedSessionId: String?
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties for Filtering
    
    /// Status derived from existing isCompleted and isArchived flags for backward compatibility
    var status: TaskStatus {
        if isArchived {
            return .archived
        } else if isCompleted {
            return .completed
        } else {
            return .active
        }
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle"
            case .medium: return "minus.circle"
            case .high: return "exclamationmark.circle"
            }
        }
    }
    
    // MARK: - Convenience Initializer
    
    init(title: String, notes: String = "", priority: TaskPriority = .medium, estimatedPomodoros: Int = 1, dueDate: Date? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.isArchived = false
        self.priority = priority
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = 0
        self.linkedSessionId = nil
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Full Initializer (for Firestore)
    init(id: String, title: String, notes: String, isCompleted: Bool, isArchived: Bool, priority: TaskPriority, estimatedPomodoros: Int, completedPomodoros: Int, linkedSessionId: String?, dueDate: Date?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.priority = priority
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = completedPomodoros
        self.linkedSessionId = linkedSessionId
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var progress: Double {
        guard estimatedPomodoros > 0 else { return 0.0 }
        return Double(completedPomodoros) / Double(estimatedPomodoros)
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var dueDateString: String {
        guard let dueDate = dueDate else { return "No due date" }
        
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(dueDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if calendar.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: dueDate)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: dueDate)
        }
    }
    
    // MARK: - Firestore Conversion
    
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "title": title,
            "notes": notes,
            "isCompleted": isCompleted,
            "isArchived": isArchived,
            "priority": priority.rawValue,
            "estimatedPomodoros": estimatedPomodoros,
            "completedPomodoros": completedPomodoros,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let linkedSessionId = linkedSessionId {
            data["linkedSessionId"] = linkedSessionId
        } else {
            data["linkedSessionId"] = NSNull()
        }
        
        if let dueDate = dueDate {
            data["dueDate"] = Timestamp(date: dueDate)
        } else {
            data["dueDate"] = NSNull()
        }
        
        return data
    }
    
    static func fromFirestore(_ data: [String: Any], id: String) -> Task? {
        guard let title = data["title"] as? String,
              let notes = data["notes"] as? String,
              let isCompleted = data["isCompleted"] as? Bool,
              let isArchived = data["isArchived"] as? Bool,
              let priorityRaw = data["priority"] as? String,
              let priority = TaskPriority(rawValue: priorityRaw),
              let estimatedPomodoros = data["estimatedPomodoros"] as? Int,
              let completedPomodoros = data["completedPomodoros"] as? Int,
              let createdAtData = data["createdAt"] as? Timestamp,
              let updatedAtData = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        let linkedSessionId = data["linkedSessionId"] as? String
        let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
        
        return Task(
            id: id,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            isArchived: isArchived,
            priority: priority,
            estimatedPomodoros: estimatedPomodoros,
            completedPomodoros: completedPomodoros,
            linkedSessionId: linkedSessionId,
            dueDate: dueDate,
            createdAt: createdAtData.dateValue(),
            updatedAt: updatedAtData.dateValue()
        )
    }
    
    // MARK: - Mutating Methods
    
    mutating func markAsCompleted() {
        isCompleted = true
        updatedAt = Date()
    }
    
    mutating func markAsIncomplete() {
        isCompleted = false
        updatedAt = Date()
    }
    
    mutating func archive() {
        isArchived = true
        updatedAt = Date()
    }
    
    mutating func unarchive() {
        isArchived = false
        updatedAt = Date()
    }
    
    mutating func incrementCompletedPomodoros() {
        completedPomodoros += 1
        updatedAt = Date()
    }
    
    mutating func linkToSession(_ sessionId: String?) {
        linkedSessionId = sessionId
        updatedAt = Date()
    }
}
