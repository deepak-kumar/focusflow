import SwiftUI

struct GlassCard<Content: View>: View {
    var blur: CGFloat = 16
    var corner: CGFloat = 24
    var content: () -> Content

    init(blur: CGFloat = 16, corner: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.blur = blur
        self.corner = corner
        self.content = content
    }

    var body: some View {
        content()
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassCard {
            VStack {
                Text("Premium Glass Card")
                    .font(.headline)
                Text("Beautiful Material Design")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        
        GlassCard(corner: 16) {
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Timer Controls")
                        .font(.headline)
                    Text("Start, pause, and reset")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
    .padding()
    .background(.black.opacity(0.1))
}
