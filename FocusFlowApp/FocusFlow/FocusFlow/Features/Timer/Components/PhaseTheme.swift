import SwiftUI

enum PhaseTheme {
    static func color(for phaseName: String) -> Color {
        switch phaseName {
        case "Focus":       return Color(hex: "#7C5CFF")
        case "Short Break": return Color(hex: "#22C55E")
        case "Long Break":  return Color(hex: "#0EA5E9")
        default:            return .accentColor
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 120, 120, 120)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            colorSwatch("Focus", PhaseTheme.color(for: "Focus"))
            colorSwatch("Short Break", PhaseTheme.color(for: "Short Break"))
            colorSwatch("Long Break", PhaseTheme.color(for: "Long Break"))
        }
        
        HStack(spacing: 16) {
            colorSwatch("Default", PhaseTheme.color(for: "Unknown"))
            colorSwatch("Accent", .accentColor)
        }
    }
    .padding()
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 8) {
        Circle()
            .fill(color)
            .frame(width: 50, height: 50)
            .shadow(color: color.opacity(0.5), radius: 8)
        
        Text(name)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
