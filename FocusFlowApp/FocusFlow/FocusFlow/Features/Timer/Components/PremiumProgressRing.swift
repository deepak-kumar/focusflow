import SwiftUI

struct PremiumProgressRing: View {
    var progress: Double      // 0.0 ... 1.0
    var title: String         // "Focus", "Short Break", etc.
    var timeText: String      // "14:32"
    var accent: Color         // brand accent per phase
    var isRunning: Bool

    @State private var anim: CGFloat = 0

    var body: some View {
        ZStack {
            // Glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .blur(radius: 24)
                .opacity(isRunning ? 1 : 0.5)

            // Base track
            Circle()
                .stroke(lineWidth: 14)
                .foregroundStyle(.ultraThinMaterial)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            accent.opacity(0.35),
                            accent,
                            accent.opacity(0.35)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.5), radius: 10, x: 0, y: 0)
                .animation(.easeInOut(duration: 0.35), value: progress)

            // Center content
            VStack(spacing: 6) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(timeText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: timeText)

                Capsule()
                    .fill(isRunning ? accent : .orange)
                    .frame(width: isRunning ? 10 : 8, height: 10)
                    .shadow(color: (isRunning ? accent : .orange).opacity(0.7), radius: 6)
                    .opacity(0.9)
                    .accessibilityHidden(true)
            }
        }
        .padding(24)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { anim = 1 } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) timer")
        .accessibilityValue(timeText)
        .accessibilityHint("Double tap to start or pause using the control bar below.")
    }
}

#Preview {
    PremiumProgressRing(
        progress: 0.7,
        title: "Focus",
        timeText: "14:32",
        accent: Color(hex: "#7C5CFF"),
        isRunning: true
    )
    .frame(width: 300, height: 300)
    .background(.black.opacity(0.1))
}
