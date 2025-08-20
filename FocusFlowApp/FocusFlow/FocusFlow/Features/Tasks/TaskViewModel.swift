import Foundation
import SwiftUI
import Combine
import _Concurrency

// Type alias to avoid naming conflict
typealias AsyncTask = _Concurrency.Task

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var showingAddTask = false
    @Published var editingTask: Task?
    @Published var selectedTask: Task?
    
    private var taskService: TaskService
    private var cancellables = Set<AnyCancellable>()
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case archived = "Archived"
        case overdue = "Overdue"
        case highPriority = "High Priority"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "play.circle"
            case .completed: return "checkmark.circle"
            case .archived: return "archivebox"
            case .overdue: return "exclamationmark.triangle"
            case .highPriority: return "exclamationmark.circle"
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
                self?.applyFilters()
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
        
        // Bind search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Bind filter changes
        $selectedFilter
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func createTask(title: String, notes: String, priority: Task.Priority, estimatedPomodoros: Int, dueDate: Date?) {
        print("TaskViewModel: createTask called")
        
        // Check if we have a userId
        guard taskService.hasUserId else {
            print("TaskViewModel: No userId available, cannot create task")
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
    
    private func applyFilters() {
        var filtered = tasks
        
        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = taskService.searchTasks(query: searchQuery)
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            filtered = filtered.filter { !$0.isArchived }
        case .active:
            filtered = filtered.filter { !$0.isArchived && !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { !$0.isArchived && $0.isCompleted }
        case .archived:
            filtered = filtered.filter { $0.isArchived }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue && !$0.isArchived }
        case .highPriority:
            filtered = filtered.filter { $0.priority == .high && !$0.isArchived }
        }
        
        DispatchQueue.main.async {
            self.filteredTasks = filtered
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
