import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var accentColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.themeCardBase.opacity(0.65))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.6),
                                accentColor.opacity(0.3),
                                .white.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: accentColor.opacity(0.08), radius: 10, x: 0, y: 5)
            .shadow(color: Color.espressoBrown.opacity(0.05), radius: 15, x: 0, y: 8)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, accentColor: Color = ThemeManager.shared.currentTheme.accentColor) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, accentColor: accentColor))
    }
}

struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var accentColor: Color = ThemeManager.shared.currentTheme.accentColor
    let content: () -> Content
    
    init(cornerRadius: CGFloat = 16, accentColor: Color = ThemeManager.shared.currentTheme.accentColor, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .glassCard(cornerRadius: cornerRadius, accentColor: accentColor)
    }
}
