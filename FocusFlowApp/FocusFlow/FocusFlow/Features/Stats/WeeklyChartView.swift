import SwiftUI

struct WeeklyChartView: View {
    let data: [StatsViewModel.DayPomodoro]
    
    private var maxCount: Int {
        data.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(data.reduce(0) { $0 + $1.count }) total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { dayData in
                    VStack(spacing: 8) {
                        // Bar
                        VStack {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: dayData.count))
                                .frame(height: barHeight(for: dayData.count))
                                .animation(.easeInOut(duration: 0.6), value: dayData.count)
                        }
                        .frame(height: 120)
                        
                        // Day label
                        Text(dayData.day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func barHeight(for count: Int) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(count) / CGFloat(maxCount) * 100
    }
    
    private func barColor(for count: Int) -> Color {
        if count == 0 {
            return Color.gray.opacity(0.3)
        } else if count >= 5 {
            return Color.green
        } else if count >= 3 {
            return Color.blue
        } else {
            return Color.orange
        }
    }
}

#Preview {
    WeeklyChartView(data: [
        StatsViewModel.DayPomodoro(day: "Mon", count: 3, date: Date()),
        StatsViewModel.DayPomodoro(day: "Tue", count: 5, date: Date()),
        StatsViewModel.DayPomodoro(day: "Wed", count: 2, date: Date()),
        StatsViewModel.DayPomodoro(day: "Thu", count: 4, date: Date()),
        StatsViewModel.DayPomodoro(day: "Fri", count: 1, date: Date()),
        StatsViewModel.DayPomodoro(day: "Sat", count: 0, date: Date()),
        StatsViewModel.DayPomodoro(day: "Sun", count: 6, date: Date())
    ])
    .padding()
    .background(Color.black.opacity(0.1))
}
