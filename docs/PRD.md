# FocusFlow — iOS Pomodoro App (MVP)

## 1. Goal
Build a **premium focus & productivity app** based on the Pomodoro technique.  
It should combine simplicity with **modern design, smooth micro animations, and cloud persistence**.  
Data is user-specific and stored in **Firebase Firestore** under `users/{uid}/`.

---

## 2. Key Features
1. **Pomodoro Timer**
   - Start, pause, resume, skip, extend focus/break sessions.
   - Circular progress indicator with gradient animation.
   - Save completed sessions to Firestore.

2. **Task Management**
   - Add, edit, delete, archive tasks.
   - Link Pomodoro sessions to tasks.
   - Track task progress via completed Pomodoros.
   - Store in Firestore.

3. **History & Stats**
   - Daily, weekly, monthly focus time.
   - Streak counter for daily goal completion.
   - Bar charts (SwiftUI Charts).
   - Data loaded from Firestore.

4. **User Settings**
   - Customizable durations (focus, short break, long break).
   - Auto-start toggle.
   - Theme selection.
   - Sounds & haptics options.
   - Daily goal target.
   - Persist to Firestore.

5. **Persistence**
   - All user data stored under `users/{uid}/` (via Firebase Auth anonymous login).
   - Syncs automatically across devices if upgraded to real login later.

6. **Notifications & Widgets**
   - Local notifications: session start, 1-min remaining, session complete.
   - Live Activity / Dynamic Island integration.
   - Lock Screen & Home Screen widgets for timer preview and quick start.

---

## 3. Technical Details
- **Language**: Swift (SwiftUI)
- **Architecture**: MVVM
- **Cloud Backend**: Firebase Firestore
- **Auth**: Firebase Anonymous Authentication
- **Persistence Path**: `users/{uid}/tasks`, `users/{uid}/sessions`, `users/{uid}/settings`
- **Charts**: SwiftUI Charts
- **Animations**: SwiftUI spring, implicit animations, custom micro animations
- **Accessibility**: VoiceOver, Dynamic Type, Reduce Motion support

---

## 4. Success Criteria (MVP)
- User can:
  - Run Pomodoro sessions and see progress visually.
  - Save history of sessions automatically.
  - Create/manage tasks linked to Pomodoros.
  - View stats with charts and streaks.
  - Customize timer settings.
- App feels **premium and polished**, with smooth animations and frosted UI.
- Data persists in Firestore and is tied to the user’s unique anonymous account.

---

## 5. Future Enhancements
- Upgrade anonymous users to Apple Sign-In / Google Login.
- Social focus rooms (co-working sessions).
- Advanced gamification (badges, leaderboards).
- Cross-platform (macOS, iPadOS).