import SwiftUI

struct AppTheme {
    // Brand Colors
    static let athleteOrange = Color(red: 0.99, green: 0.30, blue: 0.01)
    static let performanceBlue = Color(red: 0.05, green: 0.45, blue: 0.99)
    static let deepSlate = Color(red: 0.03, green: 0.03, blue: 0.05)
    static let surfaceSlate = Color(red: 0.08, green: 0.08, blue: 0.12)
    
    // Glassmorphism
    static func glassBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    
    static func glassBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? deepSlate : Color(white: 0.96)
    }
    
    // Text Colors
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.65)
    }
    
    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.45) : .black.opacity(0.45)
    }
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [athleteOrange, Color(red: 1.0, green: 0.5, blue: 0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [performanceBlue, Color(red: 0.0, green: 0.8, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [deepSlate, surfaceSlate],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(AppTheme.glassBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.glassBorder(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.1), radius: 15, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func premiumShadow() -> some View {
        self.shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 12)
    }
}

struct PremiumButtonStyle: ButtonStyle {
    var color: Color = AppTheme.athleteOrange
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isEnabled ? color.gradient : Color.gray.gradient)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.glassBorder(for: colorScheme), lineWidth: 1.5)
                    .background(AppTheme.glassBackground(for: colorScheme))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
