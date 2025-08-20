# Rules for Cursor AI — FocusFlow iOS App

You are building a modern, premium iOS app called **FocusFlow**, inspired by the Pomodoro technique.

## Development Guidelines
- Use **SwiftUI** for all UI.
- Use **MVVM folder structure**:
  - FocusFlowApp/Features/{FeatureName}/
  - FocusFlowApp/Services/
  - FocusFlowApp/Models/
  - FocusFlowApp/Core/
- Write clean, modular Swift code with proper file separation.
- Always use **async/await** for Firestore and Auth calls.
- Favor **ObservableObject + @Published** for state.
- Ensure smooth 60fps animations, micro animations, and premium UI polish.
- All data should be persisted in **Firebase Firestore**, scoped by authenticated user (`uid`).
- Use **Firebase Anonymous Auth** by default. Each user automatically gets a unique `uid` on first launch.
- All Firestore collections must be nested under `users/{uid}/`.

## Firestore Data Model
- `users/{uid}/tasks/{taskId}`
  - id (String)
  - title (String)
  - notes (String)
  - completedPoms (Int)
  - isArchived (Bool)
  - createdAt (Timestamp)

- `users/{uid}/sessions/{sessionId}`
  - id (String)
  - start (Timestamp)
  - end (Timestamp)
  - duration (Int in minutes)
  - type (String: focus | shortBreak | longBreak)
  - completed (Bool)
  - taskId (String, optional)

- `users/{uid}/settings/{settingsId}`
  - focusDuration (Int, minutes)
  - shortBreak (Int, minutes)
  - longBreak (Int, minutes)
  - autoStart (Bool)
  - theme (String: light | dark | system | custom)
  - sound (String)
  - haptics (Bool)
  - dailyGoal (Int, minutes)

## Design Guidelines
- UI must look more premium than [flow.app](https://www.flow.app/features).
- Use **glassmorphism** (blurred frosted backgrounds, neon gradients).
- Apply **micro animations**: button taps, progress rings, card transitions.
- Ensure **accessibility support**: Dynamic Type, VoiceOver, Reduce Motion.
- Add subtle **haptics** where appropriate.
- Keep layouts minimal, modern, and premium.

## Features Overview
- **Timer**: circular countdown with controls (start, pause, skip, extend).
- **Tasks**: CRUD tasks, archive, link to Pomodoro sessions.
- **Stats**: weekly/monthly charts, streak counter, daily goal tracking.
- **Settings**: customizable session durations, themes, sounds, haptics.
- **Persistence**: history stored in Firestore per user.
- **Notifications**: local notifications and Live Activities for session updates.
- **Widgets**: Lock Screen + Home Screen timer widget.