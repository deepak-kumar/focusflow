import SwiftUI

struct TaskStatisticsView: View {
    let statistics: TaskStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Task Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // Main stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Active tasks
                TaskStatCard(
                    title: "Active",
                    value: "\(statistics.activeTasks)",
                    color: .blue,
                    icon: "play.circle.fill"
                )
                
                // Completed tasks
                TaskStatCard(
                    title: "Completed",
                    value: "\(statistics.completedTasks)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                // Overdue tasks
                TaskStatCard(
                    title: "Overdue",
                    value: "\(statistics.overdueTasks)",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                // Total tasks
                TaskStatCard(
                    title: "Total",
                    value: "\(statistics.totalTasks)",
                    color: .purple,
                    icon: "list.bullet"
                )
            }
            
            // Progress section
            VStack(spacing: 12) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(statistics.completionRate * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // Completion progress bar
                ProgressView(value: statistics.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // Pomodoro stats
                HStack(spacing: 20) {
                    PomodoroStatCard(
                        title: "Estimated",
                        value: "\(statistics.totalEstimatedPomodoros)",
                        color: .orange,
                        icon: "timer"
                    )
                    
                    PomodoroStatCard(
                        title: "Completed",
                        value: "\(statistics.totalCompletedPomodoros)",
                        color: .green,
                        icon: "checkmark.circle"
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct TaskStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PomodoroStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TaskStatisticsView(
        statistics: TaskStatistics(
            totalTasks: 12,
            activeTasks: 5,
            completedTasks: 6,
            archivedTasks: 1,
            overdueTasks: 2,
            totalEstimatedPomodoros: 24,
            totalCompletedPomodoros: 18,
            completionRate: 0.5
        )
    )
    .padding()
    .background(Color.black.opacity(0.1))
}
