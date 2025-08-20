import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Progress")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track your productivity journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCardView(
                            title: "Tasks Completed",
                            value: "\(viewModel.totalTasksCompleted)",
                            subtitle: "Total completed",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCardView(
                            title: "Pomodoros",
                            value: "\(viewModel.totalPomodorosCompleted)",
                            subtitle: "Total sessions",
                            icon: "timer",
                            color: .blue
                        )
                        
                        StatCardView(
                            title: "Current Streak",
                            value: "\(viewModel.currentStreak)",
                            subtitle: "Consecutive days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        StatCardView(
                            title: "Weekly Total",
                            value: "\(viewModel.weeklyPomodoros.reduce(0) { $0 + $1.count })",
                            subtitle: "This week",
                            icon: "chart.bar.fill",
                            color: .purple
                        )
                    }
                    
                    // Weekly Chart
                    if !viewModel.weeklyPomodoros.isEmpty {
                        WeeklyChartView(data: viewModel.weeklyPomodoros)
                    } else {
                        // Placeholder when no data
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text("No data yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Complete some Pomodoros to see your weekly progress")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Material.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .refreshable {
                viewModel.refreshStats()
            }
        }
        .onAppear {
            if let userId = appState.currentUser?.uid {
                viewModel.setUserId(userId)
            }
        }
        .onChange(of: appState.currentUser?.uid) { newUserId in
            if let userId = newUserId {
                viewModel.setUserId(userId)
            }
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(AppState())
}
