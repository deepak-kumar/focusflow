# FocusFlow iOS App

## Firebase Setup Instructions

### 1. Add Firebase Dependencies via Swift Package Manager

1. Open `FocusFlow.xcodeproj` in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Add the following Firebase packages:

#### FirebaseAuth
- URL: `https://github.com/firebase/firebase-ios-sdk`
- Dependency Rule: Up to Next Major Version
- Select only: `FirebaseAuth`

#### FirebaseFirestore
- URL: `https://github.com/firebase/firebase-ios-sdk`
- Dependency Rule: Up to Next Major Version
- Select only: `FirebaseFirestore`

### 2. Add GoogleService-Info.plist

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to your Xcode project root (same level as `FocusFlowApp.swift`)
3. Make sure it's added to your target

### 3. Build and Run

The app will automatically:
- Configure Firebase on launch
- Sign in anonymously
- Create user document in Firestore
- Set up default settings
- Navigate to the main tab interface

## Project Structure

```
FocusFlowApp/
├── FocusFlow/
│   ├── Core/
│   │   ├── AppState.swift          # Global app state
│   │   └── MainTabView.swift       # Tab navigation
│   ├── Services/
│   │   └── AuthService.swift       # Firebase authentication
│   ├── Features/
│   │   ├── Timer/TimerView.swift
│   │   ├── Tasks/TasksView.swift
│   │   ├── Stats/StatsView.swift
│   │   └── Settings/SettingsView.swift
│   ├── FocusFlowApp.swift          # App entry point
│   └── ContentView.swift           # Main content view
```

## Firestore Structure

All user data is stored under `users/{uid}/`:
- `users/{uid}/settings/default` - User preferences
- `users/{uid}/tasks/{taskId}` - User tasks
- `users/{uid}/sessions/{sessionId}` - Pomodoro sessions

## Features

- **Timer**: Pomodoro timer (placeholder)
- **Tasks**: Task management (placeholder)
- **Stats**: Statistics and charts (placeholder)
- **Settings**: App preferences (placeholder)

All views use glassmorphism styling with `.ultraThinMaterial` backgrounds.
