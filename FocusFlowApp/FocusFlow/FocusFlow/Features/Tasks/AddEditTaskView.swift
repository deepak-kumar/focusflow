import SwiftUI

struct AddEditTaskView: View {
    let isEditing: Bool
    let task: Task?
    let onSave: (Task) -> Void
    let onCancel: () -> Void
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: Task.Priority = .medium
    @State private var estimatedPomodoros = 1
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool
    
    private let hapticService = HapticService.shared
    
    init(isEditing: Bool = false, task: Task? = nil, onSave: @escaping (Task) -> Void, onCancel: @escaping () -> Void) {
        self.isEditing = isEditing
        self.task = task
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state with existing task data
        if let task = task {
            _title = State(initialValue: task.title)
            _notes = State(initialValue: task.notes)
            _priority = State(initialValue: task.priority)
            _estimatedPomodoros = State(initialValue: task.estimatedPomodoros)
            _hasDueDate = State(initialValue: task.dueDate != nil)
            _dueDate = State(initialValue: task.dueDate ?? Date())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Title Section
                Section {
                    TextField("Task title", text: $title)
                        .font(.headline)
                        .focused($isTitleFocused)
                        .onSubmit {
                            isNotesFocused = true
                        }
                } header: {
                    Text("Title")
                } footer: {
                    if title.isEmpty {
                        Text("Enter a descriptive title for your task")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notes Section
                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .font(.body)
                        .focused($isNotesFocused)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Additional details to help you remember what needs to be done")
                        .foregroundColor(.secondary)
                }
                
                // Priority Section
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                    .foregroundColor(getPriorityColor(priority))
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Priority")
                } footer: {
                    Text("Set the importance level of this task")
                        .foregroundColor(.secondary)
                }
                
                // Pomodoros Section
                Section {
                    Stepper(value: $estimatedPomodoros, in: 1...20) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.blue)
                            Text("Estimated Pomodoros")
                            Spacer()
                            Text("\(estimatedPomodoros)")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Time Estimation")
                } footer: {
                    Text("How many 25-minute focus sessions do you think this task will take?")
                        .foregroundColor(.secondary)
                }
                
                // Due Date Section
                Section {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: dueDate) { newDate in
                            hapticService.impact(style: .light)
                        }
                    }
                } header: {
                    Text("Due Date")
                } footer: {
                    if hasDueDate {
                        Text("Set a deadline to help you stay on track")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Optional: Add a due date to create urgency")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Preview Section
                if !title.isEmpty {
                    Section {
                        TaskPreviewCard(
                            title: title,
                            notes: notes,
                            priority: priority,
                            estimatedPomodoros: estimatedPomodoros,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hapticService.impact(style: .light)
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        hapticService.impact(style: .medium)
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if !isEditing {
                isTitleFocused = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveTask() {
        let newTask = Task(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            estimatedPomodoros: estimatedPomodoros,
            dueDate: hasDueDate ? dueDate : nil
        )
        
        onSave(newTask)
    }
    
    private func getPriorityColor(_ priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct TaskPreviewCard: View {
    let title: String
    let notes: String
    let priority: Task.Priority
    let estimatedPomodoros: Int
    let dueDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Spacer()
                
                // Priority badge
                HStack(spacing: 4) {
                    Image(systemName: priority.icon)
                        .font(.caption)
                        .foregroundColor(getPriorityColor(priority))
                    
                    Text(priority.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(getPriorityColor(priority))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(getPriorityColor(priority).opacity(0.1))
                )
            }
            
            // Notes
            if !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 32)
            }
            
            // Footer
            HStack {
                // Due date
                if let dueDate = dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Pomodoro count
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("\(estimatedPomodoros) Pomodoros")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getPriorityColor(_ priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    AddEditTaskView(
        isEditing: false,
        task: nil,
        onSave: { _ in },
        onCancel: {}
    )
}
