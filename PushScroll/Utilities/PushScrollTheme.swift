import SwiftUI

/// Central design tokens — dark, energetic, motivational aesthetic.
enum PushScrollTheme {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "14141C")
    static let surfaceElevated = Color(hex: "1E1E2A")
    static let accent = Color(hex: "FF6B35")
    static let accentSecondary = Color(hex: "F7C548")
    static let success = Color(hex: "3DDC97")
    static let danger = Color(hex: "FF4757")
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "9898A6")

    static let heroGradient = LinearGradient(
        colors: [Color(hex: "FF6B35"), Color(hex: "FF3D77"), Color(hex: "7B2FF7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color(hex: "1E1E2A"), Color(hex: "14141C")],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

struct GlowButtonStyle: ButtonStyle {
    var color: Color = PushScrollTheme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(PushScrollTheme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.7 : 1))
                    .shadow(color: color.opacity(0.45), radius: configuration.isPressed ? 4 : 14, y: 6)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(PushScrollTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func pushScrollCard() -> some View {
        modifier(CardModifier())
    }
}