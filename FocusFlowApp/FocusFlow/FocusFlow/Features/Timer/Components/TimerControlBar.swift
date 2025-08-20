import SwiftUI

struct TimerControlBar: View {
    var isRunning: Bool
    var canPause: Bool
    var onStart: () -> Void
    var onPause: () -> Void
    var onReset: () -> Void
    var onSkip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            button(label: "Skip", system: "forward.end.fill", role: .tertiary, action: onSkip)
            Spacer(minLength: 0)
            if isRunning, canPause {
                button(label: "Pause", system: "pause.fill", role: .primary, action: onPause)
            } else {
                button(label: "Start", system: "play.fill", role: .primary, action: onStart)
            }
            Spacer(minLength: 0)
            button(label: "Reset", system: "arrow.counterclockwise", role: .secondary, action: onReset)
        }
        .padding(.horizontal)
    }

    enum Role { case primary, secondary, tertiary }

    @ViewBuilder
    private func button(label: String, system: String, role: Role, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: system).font(.headline)
                Text(label).font(.headline)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
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
    }

    private func background(_ r: Role) -> some ShapeStyle {
        switch r {
        case .primary:   AnyShapeStyle(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .secondary: AnyShapeStyle(Color.secondary.opacity(0.12))
        case .tertiary:  AnyShapeStyle(Color.secondary.opacity(0.08))
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
        TimerControlBar(
            isRunning: false,
            canPause: true,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onReset: { print("Reset") },
            onSkip: { print("Skip") }
        )
        
        TimerControlBar(
            isRunning: true,
            canPause: true,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onReset: { print("Reset") },
            onSkip: { print("Skip") }
        )
    }
    .padding()
    .background(.black.opacity(0.1))
}
