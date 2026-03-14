import SwiftUI

/// Sistema de Diseño de RehApp.
/// Define la paleta de colores, gradientes y componentes visuales reutilizables.
/// Sigue una estética "Glassmorphism" (efecto cristal) para un look premium y moderno.
struct AppTheme {
    // Colores de Marca (Brand) - Optimizados para pantallas OLED/DCI-P3
    static let athleteOrange = Color(hue: 0.05, saturation: 0.95, brightness: 1.0) // Naranja eléctrico
    static let performanceBlue = Color(hue: 0.60, saturation: 0.85, brightness: 1.0) // Azul vibrante
    static let clinicalGreen = Color(hue: 0.40, saturation: 0.70, brightness: 0.90) // Verde clínico
    static let deepSlate = Color(white: 0.02) // Negro profundo para OLED
    static let surfaceSlate = Color(white: 0.08) // Gris superficie
    
    // Layout Constants
    static let horizontalPadding: CGFloat = 24
    
    // Configuración de Glassmorphism (Efecto Cristal)
    static func glassBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    
    static func glassBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? deepSlate : Color(white: 0.96)
    }
    
    // Colores de Texto Adaptativos
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.65)
    }
    
    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.45) : .black.opacity(0.45)
    }
    
    // Gradientes Premium
    static let primaryGradient = LinearGradient(
        colors: [athleteOrange, Color(red: 1.0, green: 0.5, blue: 0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [performanceBlue, Color(hue: 0.55, saturation: 0.60, brightness: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let vibrantGradient = LinearGradient(
        colors: [athleteOrange, performanceBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Modificador que aplica el efecto de tarjeta de cristal (Glassmorphism).
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial) // Efecto de desenfoque nativo de Apple
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
    /// Aplica el diseño de tarjeta de cristal a cualquier vista.
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    /// Aplica una sombra profunda y elegante.
    func premiumShadow() -> some View {
        self.shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 12)
    }
}

/// Estilo de botón principal con animaciones suaves y gradientes.
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1) // Feedback táctil visual
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
