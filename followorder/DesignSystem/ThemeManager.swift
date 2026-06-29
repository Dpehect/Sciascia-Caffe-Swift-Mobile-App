import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case boutique = "boutique"   // Latte
    case food = "food"           // Espresso
    case industry = "industry"   // Golden
    case organic = "organic"     // Matcha
    
    var name: String {
        switch self {
        case .boutique: return "Creamy Latte (Luxurious Beige)"
        case .food: return "Espresso Orange (Vibrant Orange)"
        case .industry: return "Golden Rome (Imperial Gold)"
        case .organic: return "Soft Matcha (Forest Green)"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .boutique: return .espressoBrown
        case .food: return .warmOrange
        case .industry: return .goldenYellow
        case .organic: return .softMatcha
        }
    }
    
    var themeGradient: LinearGradient {
        switch self {
        case .boutique: return ThemeGradients.espresso
        case .food: return ThemeGradients.orange
        case .industry: return ThemeGradients.golden
        case .organic: return ThemeGradients.matcha
        }
    }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selected_theme")
        }
    }
    
    private init() {
        if let savedThemeRaw = UserDefaults.standard.string(forKey: "selected_theme"),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            self.currentTheme = savedTheme
        } else {
            self.currentTheme = .industry // Default theme for Sciascia Caffè is Golden Rome!
        }
    }
}
