import SwiftUI

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case gradient
    case oledDark
    case light
    
    var id: String { rawValue }
    
    var displayName: String {
        LocalizationManager.shared.translate("THEME_\(rawValue.uppercased())")
    }
    
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        // Always use theme-specific gradients, ignore system colorScheme
        switch self {
        case .system:
            // For system theme, use a neutral background that adapts
            return LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gradient:
            return LinearGradient(
                colors: [Color("ForestGreen"), Color("LakeNight")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .oledDark:
            return LinearGradient(
                colors: [Color.black, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            return LinearGradient(
                colors: [Color.white, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        // Always use theme-specific colors, ignore system colorScheme
        switch self {
        case .system:
            // For system theme, use a neutral approach
            return .primary
        case .gradient, .oledDark:
            return .white
        case .light:
            return .black.opacity(0.9)
        }
    }
    
    func primaryTextColor() -> Color {
        switch self {
        case .system:
            return .primary
        case .gradient, .oledDark:
            return .white
        case .light:
            return .black.opacity(0.9)
        }
    }
    
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        // Always use theme-specific colors, ignore system colorScheme
        switch self {
        case .system:
            // For system theme, use a neutral approach
            return .secondary
        case .gradient, .oledDark:
            return .white.opacity(0.7)
        case .light:
            return .black.opacity(0.7)
        }
    }
    
    func secondaryTextColor() -> Color {
        switch self {
        case .system:
            return .secondary
        case .gradient, .oledDark:
            return .white.opacity(0.7)
        case .light:
            return .black.opacity(0.7)
        }
    }
    
    func cardBackground(for colorScheme: ColorScheme) -> Color {
        // Always use theme-specific colors, ignore system colorScheme
        switch self {
        case .system:
            // For system theme, use a neutral approach
            return Color(.systemBackground).opacity(0.8)
        case .gradient:
            return .white.opacity(0.08)
        case .oledDark:
            return .white.opacity(0.05)
        case .light:
            return .white.opacity(0.95)
        }
    }
    
    func cardBackground() -> Color {
        switch self {
        case .system:
            return Color(.systemBackground)
        case .gradient:
            return .white.opacity(0.08)
        case .oledDark:
            return .white.opacity(0.05)
        case .light:
            return .white.opacity(0.95)
        }
    }
    
    func cardStroke(for colorScheme: ColorScheme) -> Color {
        // Always use theme-specific colors, ignore system colorScheme
        switch self {
        case .system:
            // For system theme, use a neutral approach
            return Color(.separator)
        case .gradient:
            return .white.opacity(0.12)
        case .oledDark:
            return .white.opacity(0.1)
        case .light:
            return .black.opacity(0.15)
        }
    }
    
    func cardStroke() -> Color {
        switch self {
        case .system:
            return Color(.separator)
        case .gradient:
            return .white.opacity(0.12)
        case .oledDark:
            return .white.opacity(0.1)
        case .light:
            return .black.opacity(0.15)
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }
    
    private init() {
        if let stored = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: stored) {
            currentTheme = theme
        } else {
            currentTheme = .system
        }
    }
}

// MARK: - Helper Extension for ColorScheme Independence
extension AppTheme {
    /// Returns the appropriate color method based on theme type
    /// For system theme, uses colorScheme parameter; for others, ignores it
    func getPrimaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return primaryTextColor(for: colorScheme)
        case .gradient, .oledDark, .light:
            // For non-system themes, ignore colorScheme and use theme-specific colors
            return primaryTextColor()
        }
    }
    
    func getSecondaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return secondaryTextColor(for: colorScheme)
        case .gradient, .oledDark, .light:
            return secondaryTextColor()
        }
    }
    
    func getCardBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return cardBackground(for: colorScheme)
        case .gradient, .oledDark, .light:
            return cardBackground()
        }
    }
    
    func getCardStroke(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return cardStroke(for: colorScheme)
        case .gradient, .oledDark, .light:
            return cardStroke()
        }
    }
    
    func getBackgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .system:
            return backgroundGradient(for: colorScheme)
        case .gradient, .oledDark, .light:
            // For non-system themes, ignore colorScheme and use theme-specific gradients
            return backgroundGradient(for: .light) // Pass .light as dummy, will be ignored
        }
    }
}

// MARK: - Liquid Glass aware theme colors
extension AppTheme {
    /// Primary text/icon color tuned for readability over Liquid Glass
    func glassPrimaryText(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? .white : .black
        case .gradient, .oledDark:
            return .white
        case .light:
            return .black.opacity(0.9)
        }
    }

    /// Secondary text/icon color tuned for readability over Liquid Glass
    func glassSecondaryText(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.65)
        case .gradient, .oledDark:
            return Color.white.opacity(0.75)
        case .light:
            return Color.black.opacity(0.7)
        }
    }

    /// Subtle stroke color to outline glass elements when needed
    func glassStroke(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.2)
        case .gradient:
            return Color.white.opacity(0.18)
        case .oledDark:
            return Color.white.opacity(0.14)
        case .light:
            return Color.black.opacity(0.12)
        }
    }
}

