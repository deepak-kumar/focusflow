# FocusFlow Tasks Feature

## Overview
A complete task management system with MVVM architecture, Firestore integration, and glassmorphism design. Tasks can be linked to Pomodoro sessions for productivity tracking.

## Features

### ✅ **Core Task Management**
- **Create, edit, delete** tasks with rich metadata
- **Mark tasks as complete/incomplete** with visual feedback
- **Archive/unarchive** tasks for organization
- **Priority levels** (Low, Medium, High) with color coding
- **Due dates** with overdue detection and smart formatting
- **Notes** for additional task details

### ✅ **Pomodoro Integration**
- **Estimated Pomodoros** for time planning
- **Completed Pomodoros** tracking progress
- **Progress visualization** with percentage and progress bars
- **Link tasks to sessions** for focused work tracking
- **Increment Pomodoros** manually or automatically

### ✅ **Visual Design**
- **Glassmorphism UI** with `.ultraThinMaterial` backgrounds
- **Priority-based color coding** (Green, Orange, Red)
- **Progress indicators** with dynamic colors
- **Micro-animations** for interactions and state changes
- **Responsive cards** with proper spacing and typography

### ✅ **User Experience**
- **Real-time search** with debounced input
- **Smart filtering** (All, Active, Completed, Archived, Overdue, High Priority)
- **Context menus** for quick actions
- **Haptic feedback** for all interactions
- **Empty states** with helpful messaging
- **Statistics overview** with visual progress

### ✅ **Data Persistence**
- **Firestore integration** for real-time sync
- **User-scoped data** under `users/{uid}/tasks/`
- **Automatic updates** across devices
- **Offline support** with local state management

## Architecture

### **MVVM Pattern**
```
TasksView (View)
    ↓
TaskViewModel (ViewModel)
    ↓
TaskService (Service)
    ↓
Firestore + Local State
```

### **Components**

#### **TasksView.swift** - Main View
- Orchestrates all task components
- Manages navigation and sheet presentations
- Handles environment object injection
- Provides search and filtering interface

#### **TaskViewModel.swift** - Business Logic
- Coordinates between View and Service
- Manages UI state and filtering
- Handles user interactions and validation
- Provides computed properties for statistics

#### **TaskService.swift** - Data & Firestore Logic
- Manages CRUD operations
- Handles real-time Firestore listeners
- Provides query methods and statistics
- Manages user authentication state

#### **TaskCard.swift** - Task Display
- Individual task representation
- Interactive elements (completion, edit, archive, delete)
- Progress visualization and priority indicators
- Context menus and confirmation dialogs

#### **AddEditTaskView.swift** - Task Creation/Editing
- Form-based task input
- Real-time preview of task card
- Validation and error handling
- Priority and Pomodoro estimation

#### **TaskStatisticsView.swift** - Progress Overview
- Visual statistics dashboard
- Progress bars and completion rates
- Pomodoro tracking overview
- Glassmorphism card design

#### **Task.swift** - Data Model
- Task data structure
- Firestore serialization/deserialization
- Computed properties and helper methods
- Priority and status enums

## Firestore Structure

### **Tasks Collection**
```
users/{uid}/tasks/{taskId}
├── id: String
├── title: String
├── notes: String
├── isCompleted: Boolean
├── isArchived: Boolean
├── priority: String (low|medium|high)
├── estimatedPomodoros: Int
├── completedPomodoros: Int
├── linkedSessionId: String (optional)
├── dueDate: Timestamp (optional)
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### **Data Relationships**
- **Tasks → Sessions**: Optional linking via `linkedSessionId`
- **User → Tasks**: One-to-many relationship
- **Priority → Visual**: Color-coded priority system
- **Progress → Pomodoros**: Calculated from completed/estimated ratio

## Usage

### **Creating Tasks**
```swift
// Create a new task
viewModel.createTask(
    title: "Complete project",
    notes: "Write documentation and tests",
    priority: .high,
    estimatedPomodoros: 4,
    dueDate: Date().addingTimeInterval(86400)
)
```

### **Managing Tasks**
```swift
// Toggle completion
viewModel.toggleTaskCompletion(task)

// Archive task
viewModel.archiveTask(task)

// Update Pomodoros
viewModel.incrementPomodoros(for: task)

// Link to session
viewModel.linkTaskToSession(task, sessionId: "session123")
```

### **Filtering and Search**
```swift
// Set filter
viewModel.selectedFilter = .active

// Search tasks
viewModel.searchQuery = "project"

// Get filtered results
let activeTasks = viewModel.filteredTasks
```

### **Accessing Statistics**
```swift
// Get task statistics
let stats = viewModel.taskStatistics

// Check counts
let activeCount = viewModel.activeTaskCount
let completedCount = viewModel.completedTaskCount

// Get progress
let completionRate = viewModel.completionRate
```

## Task States

### **Lifecycle**
1. **Active**: Newly created, in progress
2. **Completed**: Marked as done
3. **Archived**: Hidden from main view
4. **Overdue**: Past due date, not completed

### **Priority Levels**
- **Low**: Green, minimal urgency
- **Medium**: Orange, normal priority
- **High**: Red, urgent attention needed

### **Progress Tracking**
- **0-39%**: Red progress bar
- **40-69%**: Orange progress bar
- **70-100%**: Blue progress bar
- **Completed**: Green progress bar

## Integration with Timer

### **Pomodoro Linking**
- Tasks can be linked to active timer sessions
- Automatic Pomodoro counting when sessions complete
- Progress updates based on completed vs. estimated Pomodoros

### **Workflow**
1. Create task with estimated Pomodoros
2. Start Pomodoro session
3. Link session to task (optional)
4. Complete session to increment progress
5. Track completion rate and time estimates

## Customization

### **Visual Themes**
- Glassmorphism backgrounds with `.ultraThinMaterial`
- Priority-based color schemes
- Dynamic progress indicators
- Responsive animations

### **Haptic Feedback**
- Light impact for general interactions
- Medium impact for important actions
- Success/warning notifications for state changes

### **Animations**
- Spring-based transitions for smooth UX
- Scale effects for interactive elements
- Opacity changes for state transitions
- Smooth progress bar updates

## Future Enhancements

### **Planned Features**
- **Task templates** for recurring work
- **Subtasks** for complex task breakdown
- **Task dependencies** and prerequisites
- **Time tracking** with detailed analytics
- **Collaboration** for team tasks
- **Calendar integration** for due date management

### **Advanced Filtering**
- **Date ranges** for historical views
- **Tag system** for categorization
- **Smart suggestions** based on patterns
- **Kanban board** view option

### **Analytics**
- **Productivity trends** over time
- **Pomodoro efficiency** metrics
- **Task completion patterns** analysis
- **Goal tracking** and achievements

## Dependencies

- **Firebase**: Firestore for data persistence
- **SwiftUI**: UI framework
- **Combine**: Reactive programming
- **UIKit**: Haptic feedback and system integration

## Performance

- **Real-time updates** with Firestore listeners
- **Efficient filtering** with debounced search
- **Lazy loading** for large task lists
- **Memory management** with proper cleanup
- **Smooth animations** at 60fps

## Error Handling

- **Network errors** with user-friendly messages
- **Validation errors** for form inputs
- **Authentication errors** for user state
- **Data corruption** protection with fallbacks
