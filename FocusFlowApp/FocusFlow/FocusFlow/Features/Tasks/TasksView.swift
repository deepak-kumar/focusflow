import SwiftUI

struct TasksView: View {
    @EnvironmentObject var taskService: TaskService
    @StateObject private var viewModel: TaskViewModel
    @EnvironmentObject var appState: AppState
    
    init() {
        // Initialize with a temporary service, will be replaced by environment object
        let tempService = TaskService()
        self._viewModel = StateObject(wrappedValue: TaskViewModel(taskService: tempService))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with search and add button
                    headerSection
                    
                    // Statistics overview
                    if !viewModel.tasks.isEmpty {
                        TaskStatisticsView(statistics: viewModel.taskStatistics)
                            .padding(.horizontal, 20)
                    }
                    
                    // Filter tabs
                    filterTabsSection
                    
                    // Task list
                    taskListSection
                    
                    // Empty state
                    if viewModel.filteredTasks.isEmpty && !viewModel.isLoading {
                        emptyStateSection
                    }
                }
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddTask) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddEditTaskView(
                    isEditing: false,
                    task: nil,
                    onSave: { task in
                        viewModel.createTask(
                            title: task.title,
                            notes: task.notes,
                            priority: task.priority,
                            estimatedPomodoros: task.estimatedPomodoros,
                            dueDate: task.dueDate
                        )
                    },
                    onCancel: viewModel.hideAddTask
                )
            }
            .sheet(item: $viewModel.editingTask) { task in
                AddEditTaskView(
                    isEditing: true,
                    task: task,
                    onSave: { updatedTask in
                        viewModel.updateTask(updatedTask)
                    },
                    onCancel: viewModel.hideEditTask
                )
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onAppear {
            // Update viewModel with the injected taskService
            viewModel.updateTaskService(taskService)
            
            // Set user ID when view appears
            if let userId = appState.currentUser?.uid {
                print("[TasksView] setting userId:\(userId) on appear")
                taskService.setUserId(userId)
            } else {
                print("[TasksView] no userId available on appear")
            }
        }
        .onChange(of: appState.currentUser?.uid) { newUserId in
            if let userId = newUserId {
                print("[TasksView] setting userId:\(userId) on change")
                taskService.setUserId(userId)
            } else {
                print("[TasksView] userId changed to nil")
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search tasks...", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            
            // Quick stats row
            HStack(spacing: 20) {
                QuickStatItem(
                    title: "Active",
                    value: "\(viewModel.activeTaskCount)",
                    color: .blue,
                    icon: "play.circle.fill"
                )
                
                QuickStatItem(
                    title: "Completed",
                    value: "\(viewModel.completedTaskCount)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                QuickStatItem(
                    title: "Pomodoros",
                    value: "\(viewModel.totalCompletedPomodoros)",
                    color: .orange,
                    icon: "timer"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskViewModel.TaskFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: viewModel.selectedFilter == filter,
                        action: { viewModel.selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var taskListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredTasks) { task in
                TaskCard(
                    task: task,
                    onToggleCompletion: {
                        viewModel.toggleTaskCompletion(task)
                    },
                    onEdit: {
                        viewModel.editTask(task)
                    },
                    onArchive: {
                        if task.isArchived {
                            viewModel.unarchiveTask(task)
                        } else {
                            viewModel.archiveTask(task)
                        }
                    },
                    onDelete: {
                        viewModel.deleteTask(task)
                    },
                    onIncrementPomodoros: {
                        viewModel.incrementPomodoros(for: task)
                    }
                )
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.filteredTasks)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(getEmptyStateTitle())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(getEmptyStateMessage())
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if viewModel.selectedFilter == .all {
                Button(action: viewModel.showAddTask) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Your First Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Methods
    
    private func getEmptyStateIcon() -> String {
        switch viewModel.selectedFilter {
        case .all: return "checklist"
        case .active: return "play.circle"
        case .completed: return "checkmark.circle"
        case .archived: return "archivebox"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch viewModel.selectedFilter {
        case .all: return "No Tasks Yet"
        case .active: return "No Active Tasks"
        case .completed: return "No Completed Tasks"
        case .archived: return "No Archived Tasks"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch viewModel.selectedFilter {
        case .all: return "Start organizing your work by creating your first task. Break it down into manageable Pomodoro sessions."
        case .active: return "All your tasks are either completed or archived. Great job staying on top of things!"
        case .completed: return "Complete some tasks to see them here. You're doing great!"
        case .archived: return "No tasks have been archived yet. Keep your task list clean and organized."
        }
    }
}

// MARK: - Supporting Views

struct QuickStatItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FilterTab: View {
    let filter: TaskViewModel.TaskFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Material.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    TasksView()
        .environmentObject(AppState())
        .environmentObject(TaskService())
}
