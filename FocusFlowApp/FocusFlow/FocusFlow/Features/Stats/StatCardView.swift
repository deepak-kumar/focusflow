import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            // Value
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Title
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.3), value: value)
    }
}

#Preview {
    HStack(spacing: 16) {
        StatCardView(
            title: "Tasks Completed",
            value: "24",
            subtitle: "This month",
            icon: "checkmark.circle.fill",
            color: .green
        )
        
        StatCardView(
            title: "Pomodoros",
            value: "156",
            subtitle: "Total sessions",
            icon: "timer",
            color: .blue
        )
    }
    .padding()
    .background(Color.black.opacity(0.1))
}
