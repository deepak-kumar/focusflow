import SwiftUI

/// Control bar that NEVER wraps button titles into 2 lines.
/// It adjusts with `.lineLimit(1)` and `.minimumScaleFactor` while keeping a premium look.
/// It calls into the existing TimerService actions supplied via closures.
struct PremiumTimerControlBar: View {
    var isRunning: Bool
    var isPaused: Bool

    var onStart: () -> Void
    var onPause: () -> Void
    var onResume: () -> Void
    var onReset: () -> Void
    var onSkip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            controlButton(
                label: "Skip",
                system: "forward.end.fill",
                role: .tertiary,
                action: onSkip
            )

            Spacer(minLength: 0)

            if isRunning && !isPaused {
                controlButton(
                    label: "Pause",
                    system: "pause.fill",
                    role: .primary,
                    action: onPause
                )
            } else if isRunning && isPaused {
                controlButton(
                    label: "Resume",
                    system: "playpause.fill",
                    role: .primary,
                    action: onResume
                )
            } else {
                controlButton(
                    label: "Start",
                    system: "play.fill",
                    role: .primary,
                    action: onStart
                )
            }

            Spacer(minLength: 0)

            controlButton(
                label: "Reset",
                system: "arrow.counterclockwise",
                role: .secondary,
                action: onReset
            )
        }
        .padding(.horizontal)
    }

    enum Role { case primary, secondary, tertiary }

    @ViewBuilder
    private func controlButton(
        label: String,
        system: String,
        role: Role,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: system).font(.headline)
                Text(label)
                    .font(.headline)
                    .lineLimit(1)               // <— never wrap
                    .minimumScaleFactor(0.85)   // <— shrink instead of wrap
                    .allowsTightening(true)
                    .layoutPriority(1)
                    .truncationMode(.tail)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .frame(minWidth: 108)               // <— give enough width to avoid wrapping
            .background(
                Capsule(style: .continuous)
                    .fill(background(role))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(border(role), lineWidth: role == .primary ? 0 : 1)
            )
            .foregroundStyle(foreground(role))
            .shadow(color: shadow(role), radius: role == .primary ? 16 : 0, x: 0, y: 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(role == .primary ? .isButton : .isStaticText)
    }

    private func background(_ r: Role) -> some ShapeStyle {
        switch r {
        case .primary:
            AnyShapeStyle(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.75)],
                           startPoint: .topLeading, endPoint: .bottomTrailing))
        case .secondary:
            AnyShapeStyle(Color.secondary.opacity(0.14))
        case .tertiary:
            AnyShapeStyle(Color.secondary.opacity(0.1))
        }
    }
    private func border(_ r: Role) -> Color {
        switch r {
        case .primary:   .clear
        case .secondary: .white.opacity(0.08)
        case .tertiary:  .white.opacity(0.06)
        }
    }
    private func foreground(_ r: Role) -> Color {
        switch r {
        case .primary:   .white
        case .secondary: .primary
        case .tertiary:  .primary
        }
    }
    private func shadow(_ r: Role) -> Color {
        r == .primary ? .accentColor.opacity(0.45) : .clear
    }
}

#Preview {
    VStack(spacing: 20) {
        PremiumTimerControlBar(
            isRunning: false,
            isPaused: false,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onResume: { print("Resume") },
            onReset: { print("Reset") },
            onSkip: { print("Skip") }
        )
        
        PremiumTimerControlBar(
            isRunning: true,
            isPaused: false,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onResume: { print("Resume") },
            onReset: { print("Reset") },
            onSkip: { print("Skip") }
        )
        
        PremiumTimerControlBar(
            isRunning: true,
            isPaused: true,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onResume: { print("Resume") },
            onReset: { print("Reset") },
            onSkip: { print("Skip") }
        )
    }
    .padding()
    .background(.black.opacity(0.1))
}
