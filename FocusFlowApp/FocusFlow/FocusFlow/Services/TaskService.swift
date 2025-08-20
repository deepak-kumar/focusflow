import Foundation
import FirebaseFirestore
import Combine

class TaskService: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var userId: String?
    private var listenerRegistration: ListenerRegistration?
    private let hapticService = HapticService.shared
    
    // MARK: - Computed Properties
    
    var hasUserId: Bool {
        return userId != nil
    }
    
    // MARK: - Initialization
    
    init() {}
    
    func setUserId(_ uid: String) {
        print("TaskService: Setting userId to \(uid)")
        self.userId = uid
        setupRealtimeListener()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    // MARK: - Realtime Firestore Listener
    
    private func setupRealtimeListener() {
        guard let userId = userId else { return }
        
        // Remove existing listener
        listenerRegistration?.remove()
        
        let tasksRef = db.collection("users").document(userId).collection("tasks")
        
        listenerRegistration = tasksRef
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Error loading tasks: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self?.tasks = []
                    }
                    return
                }
                
                let loadedTasks = documents.compactMap { document -> Task? in
                    Task.fromFirestore(document.data(), id: document.documentID)
                }
                
                DispatchQueue.main.async {
                    self?.tasks = loadedTasks
                    self?.errorMessage = nil
                }
            }
    }
    
    // MARK: - CRUD Operations
    
    func createTask(_ task: Task) async throws {
        guard let userId = userId else {
            print("TaskService: User not authenticated - userId is nil")
            throw TaskError.userNotAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let taskRef = db.collection("users").document(userId)
            .collection("tasks").document(task.id)
        
        // Use merge: false for create to ensure new document
        try await taskRef.setData(task.firestoreData, merge: false)
        
        hapticService.impact(style: .light)
    }
    
    func updateTask(_ task: Task) async throws {
        guard let userId = userId else {
            throw TaskError.userNotAuthenticated
        }
        
        // Ensure updatedAt is current
        var updated = task
        updated.updatedAt = Date()
        
        let taskRef = db.collection("users").document(userId)
            .collection("tasks").document(task.id)
        
        // Use merge: true for updates to avoid overwriting
        try await taskRef.setData(updated.firestoreData, merge: true)
        
        hapticService.impact(style: .light)
    }
    
    // Upsert: If task exists, update; otherwise create
    func saveTask(_ task: Task) async throws {
        guard let userId = userId else {
            throw TaskError.userNotAuthenticated
        }
        
        let taskRef = db.collection("users").document(userId)
            .collection("tasks").document(task.id)
        
        // Check if document exists
        let snapshot = try await taskRef.getDocument()
        
        if snapshot.exists {
            try await updateTask(task)
        } else {
            try await createTask(task)
        }
    }
    
    func deleteTask(_ task: Task) async throws {
        guard let userId = userId else {
            throw TaskError.userNotAuthenticated
        }
        
        let taskRef = db.collection("users").document(userId)
            .collection("tasks").document(task.id)
        
        try await taskRef.delete()
        
        hapticService.impact(style: .medium)
    }
    
    func toggleTaskCompletion(_ task: Task) async throws {
        var updatedTask = task
        if task.isCompleted {
            updatedTask.markAsIncomplete()
        } else {
            updatedTask.markAsCompleted()
        }
        
        try await updateTask(updatedTask)
        
        hapticService.notification(type: updatedTask.isCompleted ? .success : .warning)
    }
    
    func archiveTask(_ task: Task) async throws {
        var updatedTask = task
        updatedTask.archive()
        try await updateTask(updatedTask)
        
        hapticService.impact(style: .light)
    }
    
    func unarchiveTask(_ task: Task) async throws {
        var updatedTask = task
        updatedTask.unarchive()
        try await updateTask(updatedTask)
        
        hapticService.impact(style: .light)
    }
    
    func incrementPomodoros(for task: Task) async throws {
        var updatedTask = task
        updatedTask.incrementCompletedPomodoros()
        try await updateTask(updatedTask)
        
        hapticService.impact(style: .light)
    }
    
    func linkTaskToSession(_ task: Task, sessionId: String?) async throws {
        var updatedTask = task
        updatedTask.linkToSession(sessionId)
        try await updateTask(updatedTask)
        
        hapticService.impact(style: .light)
    }
    
    // MARK: - Query Methods
    
    func getActiveTasks() -> [Task] {
        return tasks.filter { !$0.isArchived && !$0.isCompleted }
    }
    
    func getCompletedTasks() -> [Task] {
        return tasks.filter { !$0.isArchived && $0.isCompleted }
    }
    
    func getArchivedTasks() -> [Task] {
        return tasks.filter { $0.isArchived }
    }
    
    func getTasksByPriority(_ priority: TaskPriority) -> [Task] {
        return tasks.filter { $0.priority == priority && !$0.isArchived }
    }
    
    func getOverdueTasks() -> [Task] {
        return tasks.filter { $0.isOverdue && !$0.isArchived }
    }
    
    func searchTasks(query: String) -> [Task] {
        guard !query.isEmpty else { return tasks }
        
        let lowercaseQuery = query.lowercased()
        return tasks.filter { task in
            task.title.lowercased().contains(lowercaseQuery) ||
            task.notes.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Statistics
    
    func getTaskStatistics() -> TaskStatistics {
        let activeTasks = getActiveTasks()
        let completedTasks = getCompletedTasks()
        let overdueTasks = getOverdueTasks()
        
        let totalEstimatedPomodoros = activeTasks.reduce(0) { $0 + $1.estimatedPomodoros }
        let totalCompletedPomodoros = tasks.reduce(0) { $0 + $1.completedPomodoros }
        
        return TaskStatistics(
            totalTasks: tasks.count,
            activeTasks: activeTasks.count,
            completedTasks: completedTasks.count,
            archivedTasks: getArchivedTasks().count,
            overdueTasks: overdueTasks.count,
            totalEstimatedPomodoros: totalEstimatedPomodoros,
            totalCompletedPomodoros: totalCompletedPomodoros,
            completionRate: tasks.isEmpty ? 0 : Double(completedTasks.count) / Double(tasks.count)
        )
    }
}

// MARK: - Supporting Types

struct TaskStatistics {
    let totalTasks: Int
    let activeTasks: Int
    let completedTasks: Int
    let archivedTasks: Int
    let overdueTasks: Int
    let totalEstimatedPomodoros: Int
    let totalCompletedPomodoros: Int
    let completionRate: Double
}

enum TaskError: LocalizedError {
    case userNotAuthenticated
    case taskNotFound
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .taskNotFound:
            return "Task not found"
        case .invalidData:
            return "Invalid task data"
        case .networkError:
            return "Network error occurred"
        }
    }
}
