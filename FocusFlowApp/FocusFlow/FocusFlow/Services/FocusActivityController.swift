import Foundation
import ActivityKit

/// Bridges the app timer to ActivityKit (Include_Live_ActivityAttributes).
final class FocusActivityController: ObservableObject {
    static let shared = FocusActivityController()

    // Keep a handle to the currently running Live Activity
    private var currentActivity: Activity<Include_Live_ActivityAttributes>?

    private init() {}

    // MARK: - Public API

    /// Start a Live Activity for the given phase and total duration (seconds).
    func startLiveActivity(phase: String, totalDuration: TimeInterval) {
        // System-level setting
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("🔕 Live Activities disabled at system level")
            return
        }

        // End any existing one we track
        if let act = currentActivity {
            let asyncTask = _Concurrency.Task { await act.end(dismissalPolicy: .immediate) }
            _ = asyncTask
            currentActivity = nil
        }

        let attributes = Include_Live_ActivityAttributes(
            sessionTitle: "Pomodoro Session"
        )

        let content = Include_Live_ActivityAttributes.ContentState(
            phase: phase,
            remainingTime: totalDuration, // start full
            progress: 0.0,
            isRunning: true
        )

        print("🚀 FocusActivityController: Starting Live Activity")
        print("📊 areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        print("🎯 phase: \(phase), totalDuration: \(totalDuration)s")

        do {
            let activity = try Activity<Include_Live_ActivityAttributes>.request(
                attributes: attributes,
                contentState: content,
                pushType: nil
            )
            currentActivity = activity
            print("✅ Live activity started with id: \(activity.id)")
        } catch {
            print("❌ Failed to start live activity: \(error.localizedDescription)")
        }
    }

    /// Update the Live Activity each tick.
    func updateLiveActivity(phase: String,
                            remaining: TimeInterval,
                            progress: Double,
                            isRunning: Bool)
    {
        guard let activity = currentActivity else {
            // Nothing to update
            return
        }

        let content = Include_Live_ActivityAttributes.ContentState(
            phase: phase,
            remainingTime: max(remaining, 0),
            progress: min(max(progress, 0), 1),
            isRunning: isRunning
        )

        let asyncTask = _Concurrency.Task {
            await activity.update(using: content)
        }
        _ = asyncTask
    }

    /// End the Live Activity (e.g. on completion/cancel).
    func endLiveActivity() {
        guard let activity = currentActivity else {
            print("ℹ️ No tracked Live Activity to end")
            return
        }
        let asyncTask = _Concurrency.Task {
            await activity.end(dismissalPolicy: .immediate)
            print("🛑 Live Activity ended: \(activity.id)")
        }
        _ = asyncTask
        currentActivity = nil
    }
}