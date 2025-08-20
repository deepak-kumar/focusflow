import SwiftUI
import ActivityKit

struct LiveActivityDebugView: View {
    @State private var areActivitiesEnabled = false
    @State private var activeActivitiesCount = 0
    @State private var lastActionResult = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Live Activity Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Activities Enabled:")
                            Spacer()
                            Text(areActivitiesEnabled ? "✅ YES" : "❌ NO")
                                .foregroundColor(areActivitiesEnabled ? .green : .red)
                        }
                        
                        HStack {
                            Text("Active Activities:")
                            Spacer()
                            Text("\(activeActivitiesCount)")
                                .foregroundColor(activeActivitiesCount > 0 ? .orange : .gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Action Buttons Section
                VStack(spacing: 15) {
                    Text("Test Actions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: startTestActivity) {
                        Label("Start Test Activity (2m)", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: endAllActivities) {
                        Label("End All Activities", systemImage: "stop.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                // Result Section
                if !lastActionResult.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Last Action Result")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(lastActionResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Refresh Button
                Button(action: refreshStatus) {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Live Activity Debug")
            .onAppear {
                refreshStatus()
            }
        }
    }
    
    private func refreshStatus() {
        areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        activeActivitiesCount = Activity<Include_Live_ActivityAttributes>.activities.count
        
        print("🔍 LiveActivityDebug: Activities enabled: \(areActivitiesEnabled)")
        print("🔍 LiveActivityDebug: Active activities count: \(activeActivitiesCount)")
        
        lastActionResult = "Status refreshed at \(Date().formatted(date: .omitted, time: .standard))"
    }
    
    private func startTestActivity() {
        print("🧪 LiveActivityDebug: Starting test activity...")
        
        lastActionResult = "Starting test activity..."
        
        FocusActivityController.shared.startLiveActivity(
            phase: "Test",
            totalDuration: 120 // 2 minutes
        )
        
        // Refresh status after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshStatus()
            lastActionResult = "Test activity started at \(Date().formatted(date: .omitted, time: .standard))"
        }
        
        print("🧪 LiveActivityDebug: Test activity start requested")
    }
    
    private func endAllActivities() {
        print("🧪 LiveActivityDebug: Ending all activities...")
        
        let activities = Activity<Include_Live_ActivityAttributes>.activities
        lastActionResult = "Ending \(activities.count) activities..."
        
        print("🧪 LiveActivityDebug: Found \(activities.count) activities to end")
        
        if activities.isEmpty {
            lastActionResult = "No activities to end"
            print("🧪 LiveActivityDebug: No activities found to end")
            return
        }
        
        for activity in activities {
            print("🧪 LiveActivityDebug: Ending activity with ID: \(activity.id)")
            
            let asyncTask = _Concurrency.Task {
                do {
                    await activity.end(
                        .init(state: activity.content.state, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                    print("🧪 LiveActivityDebug: Successfully ended activity: \(activity.id)")
                } catch {
                    print("🧪 LiveActivityDebug: Failed to end activity \(activity.id): \(error)")
                }
            }
            _ = asyncTask
        }
        
        // Also call our controller's end method
        FocusActivityController.shared.endLiveActivity()
        
        // Refresh status after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            refreshStatus()
            lastActionResult = "All activities ended at \(Date().formatted(date: .omitted, time: .standard))"
        }
        
        print("🧪 LiveActivityDebug: All activities end requested")
    }
}

#Preview {
    LiveActivityDebugView()
}
