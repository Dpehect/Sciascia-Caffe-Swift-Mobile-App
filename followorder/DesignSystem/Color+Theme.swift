import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Core Sciascia Caffè High-Contrast Light Backgrounds
    static let themeBackground = Color(hex: "#F8F4ED") // Warm Cream
    static let themeCardBase = Color(hex: "#FFFFFF")   // White Card Base
    
    // Primary & Accent Brand Colors
    static let espressoBrown = Color(hex: "#3C2A20") // Espresso Accent
    static let warmOrange = Color(hex: "#FF6B00")    // Vibrant Orange
    
    // High Contrast Semantic Text Colors
    static let textPrimary = Color(hex: "#2C2118")   // Deep Brown (Excellent readability)
    static let textSecondary = Color(hex: "#44403C") // Dark Gray (Highly readable body)
    
    // Accent Highlights
    static let goldenYellow = Color(hex: "#D97706")  // Dark Gold Accent
    static let softMatcha = Color(hex: "#4A7043")    // Forest Green / Soft Green Accent
    static let creamyLatte = Color(hex: "#F5EDE4")   // Soft Beige Accent
    
    // Semantic Maps
    static let neonPurple = Color.espressoBrown
    static let neonOrange = Color.warmOrange
    static let neonCyan = Color.goldenYellow
    static let neonLime = Color.softMatcha
    static let neonMagenta = Color.warmOrange
    static let neonBlue = Color.creamyLatte
    
    // Status Colors (Vibrant & High-Contrast in Light Theme)
    static let statusPreparing = Color(hex: "#C2410C") // Rust / Amber Orange
    static let statusReady = Color(hex: "#047857")     // Emerald Green
    static let statusDelivered = Color(hex: "#1D4ED8") // Royal Blue
    static let statusCancelled = Color(hex: "#B91C1C") // Crimson Red
}

// Lüks İtalyan Degradeleri
struct ThemeGradients {
    static let espresso = LinearGradient(colors: [.espressoBrown, Color(hex: "#5C3E30")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let orange = LinearGradient(colors: [.warmOrange, Color(hex: "#FF8C3A")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let golden = LinearGradient(colors: [.goldenYellow, Color(hex: "#F59E0B")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let matcha = LinearGradient(colors: [.softMatcha, Color(hex: "#6F9967")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cream = LinearGradient(colors: [.creamyLatte, Color(hex: "#EFE5DA")], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    // Legacy maps for theme manager safety
    static let purple = espresso
    static let cyan = golden
    static let lime = matcha
}
