import SwiftUI

struct TaskCard: View {
    let task: Task
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onIncrementPomodoros: () -> Void
    
    @State private var showingOptions = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with completion toggle and priority
            HStack {
                // Completion checkbox
                Button(action: onToggleCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .scaleEffect(task.isCompleted ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isCompleted)
                }
                
                // Task title
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)
                
                Spacer()
                
                // Priority indicator
                HStack(spacing: 4) {
                    Image(systemName: getPriorityIcon(task.priority))
                        .font(.caption)
                        .foregroundColor(getPriorityColor(task.priority))
                    
                    Text(task.priority.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(getPriorityColor(task.priority))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(getPriorityColor(task.priority).opacity(0.1))
                )
            }
            
            // Notes (if any)
            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 32)
            }
            
            // Progress and Pomodoro info
            HStack {
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(task.progressPercentage)%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    ProgressView(value: task.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: getProgressColor()))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
                
                Spacer()
                
                // Pomodoro counter with progress bar
                VStack(spacing: 6) {
                    HStack {
                        Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Pomodoros")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Pomodoro progress bar
                    ProgressView(value: Double(task.completedPomodoros), total: Double(task.estimatedPomodoros))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Footer with due date and actions
            HStack {
                // Due date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                    
                    Text(task.dueDateString)
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                        .fontWeight(task.isOverdue ? .semibold : .regular)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    // Increment Pomodoros button
                    Button(action: onIncrementPomodoros) {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // More options button
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getProgressColor().opacity(0.3), lineWidth: 1)
                )
        )
        .overlay(
            // Overdue indicator
            Group {
                if task.isOverdue {
                    HStack {
                        Spacer()
                        VStack {
                            Text("OVERDUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red)
                                )
                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
            }
        )
        .contextMenu {
            Button(action: onToggleCompletion) {
                Label(
                    task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                    systemImage: task.isCompleted ? "circle" : "checkmark.circle"
                )
            }
            
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            if task.isArchived {
                Button(action: onArchive) {
                    Label("Unarchive", systemImage: "archivebox")
                }
            } else {
                Button(action: onArchive) {
                    Label("Archive", systemImage: "archivebox")
                }
            }
            
            Button(action: onIncrementPomodoros) {
                Label("Add Pomodoro", systemImage: "plus.circle")
            }
            
            Divider()
            
            Button(action: { showingDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
        .confirmationDialog("Task Options", isPresented: $showingOptions) {
            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                onToggleCompletion()
            }
            
            Button("Edit") {
                onEdit()
            }
            
            if task.isArchived {
                Button("Unarchive") {
                    onArchive()
                }
            } else {
                Button("Archive") {
                    onArchive()
                }
            }
            
            Button("Add Pomodoro") {
                onIncrementPomodoros()
            }
            
            Button("Delete", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPriorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private func getPriorityIcon(_ priority: TaskPriority) -> String {
        switch priority {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        }
    }
    
    private func getProgressColor() -> Color {
        if task.isCompleted {
            return .green
        } else if task.progress >= 0.7 {
            return .blue
        } else if task.progress >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TaskCard(
            task: Task(
                title: "Complete project documentation",
                notes: "Write comprehensive documentation for the new feature including API endpoints and user guides.",
                priority: .high,
                estimatedPomodoros: 4,
                dueDate: Date().addingTimeInterval(86400) // Tomorrow
            ),
            onToggleCompletion: {},
            onEdit: {},
            onArchive: {},
            onDelete: {},
            onIncrementPomodoros: {}
        )
        
        TaskCard(
            task: Task(
                title: "Review code changes",
                notes: "Go through the pull request and provide feedback",
                priority: .medium,
                estimatedPomodoros: 2,
                dueDate: Date().addingTimeInterval(-86400) // Yesterday (overdue)
            ),
            onToggleCompletion: {},
            onEdit: {},
            onArchive: {},
            onDelete: {},
            onIncrementPomodoros: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.1))
}
