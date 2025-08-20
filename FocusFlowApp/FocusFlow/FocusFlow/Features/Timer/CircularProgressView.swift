import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let timeString: String
    let phaseTitle: String
    let phaseColor: Color
    let showPhaseTransition: Bool
    
    private let lineWidth: CGFloat = 12
    private let size: CGFloat = 280
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [phaseColor.opacity(0.6), phaseColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // Center content
            VStack(spacing: 8) {
                // Phase title with transition animation
                Text(phaseTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(phaseColor)
                    .scaleEffect(showPhaseTransition ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showPhaseTransition)
                
                // Time display
                Text(timeString)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                
                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CircularProgressView(
        progress: 0.3,
        timeString: "17:30",
        phaseTitle: "Focus",
        phaseColor: .blue,
        showPhaseTransition: false
    )
}
