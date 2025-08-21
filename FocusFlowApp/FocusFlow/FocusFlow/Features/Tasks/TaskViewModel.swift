import Foundation
import SwiftUI
import Combine
import _Concurrency

// Type alias to avoid naming conflict
typealias AsyncTask = _Concurrency.Task

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var showingAddTask = false
    @Published var editingTask: Task?
    @Published var selectedTask: Task?
    
    private var taskService: TaskService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Filtered tasks based on current filter and search query
    var filteredTasks: [Task] {
        var filtered = tasks
        
        // Apply search filter
        if !searchQuery.isEmpty {
            let lowercaseQuery = searchQuery.lowercased()
            filtered = filtered.filter { task in
                task.title.lowercased().contains(lowercaseQuery) ||
                task.notes.lowercased().contains(lowercaseQuery)
            }
        }
        
        // Apply category filter using the new status property
        switch selectedFilter {
        case .all:
            return filtered // Show all tasks
        case .active:
            return filtered.filter { $0.status == .active }
        case .completed:
            return filtered.filter { $0.status == .completed }
        case .archived:
            return filtered.filter { $0.status == .archived }
        }
    }
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case archived = "Archived"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "play.circle"
            case .completed: return "checkmark.circle"
            case .archived: return "archivebox"
            }
        }
    }
    
    init(taskService: TaskService) {
        self.taskService = taskService
        setupBindings()
    }
    
    func updateTaskService(_ newService: TaskService) {
        // Cancel existing subscriptions
        cancellables.removeAll()
        
        // Update the service
        self.taskService = newService
        
        // Setup new bindings
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind task service properties
        taskService.$tasks
            .sink { [weak self] tasks in
                self?.tasks = tasks
            }
            .store(in: &cancellables)
        
        taskService.$isLoading
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
        
        taskService.$errorMessage
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    // Filter management
    func setFilter(_ filter: TaskFilter) {
        selectedFilter = filter
    }
    
    // Local update management (for immediate UI feedback)
    func upsertLocal(_ task: Task) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        } else {
            tasks.insert(task, at: 0)
        }
    }
    
    func removeLocal(id: String) {
        tasks.removeAll { $0.id == id }
    }
    
    // Save task (upsert semantics)
    func save(task: Task) async {
        do {
            try await taskService.saveTask(task)
            // Optionally update local immediately for snappy UI, listener will reconcile:
            await MainActor.run {
                upsertLocal(task)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func createTask(title: String, notes: String, priority: TaskPriority, estimatedPomodoros: Int, dueDate: Date?) {
        print("[TaskViewModel] createTask called")
        
        // Check if we have a userId
        guard taskService.hasUserId else {
            print("[TaskViewModel] no userId available cannot create task")
            errorMessage = "User not authenticated. Please wait for authentication to complete."
            return
        }
        
        let newTask = Task(
            title: title,
            notes: notes,
            priority: priority,
            estimatedPomodoros: estimatedPomodoros,
            dueDate: dueDate
        )
        
        // Use async task to avoid naming conflict
        performAsyncTask {
            try await self.taskService.createTask(newTask)
            await MainActor.run {
                self.showingAddTask = false
            }
        }
    }
    
    func updateTask(_ task: Task) {
        performAsyncTask {
            try await self.taskService.updateTask(task)
            await MainActor.run {
                self.editingTask = nil
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        performAsyncTask {
            try await self.taskService.deleteTask(task)
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        performAsyncTask {
            try await self.taskService.toggleTaskCompletion(task)
        }
    }
    
    func archiveTask(_ task: Task) {
        performAsyncTask {
            try await self.taskService.archiveTask(task)
        }
    }
    
    func unarchiveTask(_ task: Task) {
        performAsyncTask {
            try await self.taskService.unarchiveTask(task)
        }
    }
    
    func incrementPomodoros(for task: Task) {
        performAsyncTask {
            try await self.taskService.incrementPomodoros(for: task)
        }
    }
    
    func linkTaskToSession(_ task: Task, sessionId: String?) {
        performAsyncTask {
            try await self.taskService.linkTaskToSession(task, sessionId: sessionId)
        }
    }
    
    // MARK: - Pomodoro Integration Methods
    
    func getTaskForPomodoro() -> Task? {
        // Return the first active, non-completed task
        return tasks.first { !$0.isCompleted && !$0.isArchived }
    }
    
    func getTasksForPomodoro() -> [Task] {
        // Return all active, non-completed tasks
        return tasks.filter { !$0.isCompleted && !$0.isArchived }
    }
    
    func selectTaskForPomodoro(_ task: Task) {
        selectedTask = task
    }
    
    func clearPomodoroTaskSelection() {
        selectedTask = nil
    }
    
    // MARK: - Private Methods
    
    private func performAsyncTask(_ operation: @escaping () async throws -> Void) {
        // Use AsyncTask type alias to avoid naming conflict
        let _ = AsyncTask {
            do {
                try await operation()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var taskStatistics: TaskStatistics {
        return taskService.getTaskStatistics()
    }
    
    var hasActiveTasks: Bool {
        return !taskService.getActiveTasks().isEmpty
    }
    
    var hasOverdueTasks: Bool {
        return !taskService.getOverdueTasks().isEmpty
    }
    
    var activeTaskCount: Int {
        return taskService.getActiveTasks().count
    }
    
    var completedTaskCount: Int {
        return taskService.getCompletedTasks().count
    }
    
    var totalEstimatedPomodoros: Int {
        return taskService.getActiveTasks().reduce(0) { $0 + $1.estimatedPomodoros }
    }
    
    var totalCompletedPomodoros: Int {
        return tasks.reduce(0) { $0 + $1.completedPomodoros }
    }
    
    var pomodoroCompletionRate: Double {
        let totalEstimated = tasks.reduce(0) { $0 + $1.estimatedPomodoros }
        guard totalEstimated > 0 else { return 0.0 }
        return Double(totalCompletedPomodoros) / Double(totalEstimated)
    }
    
    var completionRate: Double {
        return taskStatistics.completionRate
    }
    
    // MARK: - UI State Management
    
    func showAddTask() {
        showingAddTask = true
    }
    
    func hideAddTask() {
        showingAddTask = false
    }
    
    func editTask(_ task: Task) {
        editingTask = task
    }
    
    func hideEditTask() {
        editingTask = nil
    }
    
    func selectTask(_ task: Task) {
        selectedTask = task
    }
    
    func deselectTask() {
        selectedTask = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}
