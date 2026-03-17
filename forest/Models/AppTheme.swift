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
    
    var colorSchemeOverride: ColorScheme? {
        switch self {
        case .system: return nil
        case .gradient, .oledDark: return .dark
        case .light: return .light
        }
    }
    
    private static let warmCream = Color(red: 0.98, green: 0.97, blue: 0.96)
    private static let warmLight = Color(red: 0.97, green: 0.96, blue: 0.95)
    private static let warmDark = Color(red: 0.11, green: 0.11, blue: 0.12)
    
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .system:
            return colorScheme == .dark
                ? LinearGradient(colors: [Self.warmDark, Self.warmDark], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Self.warmLight, Self.warmCream], startPoint: .top, endPoint: .bottom)
        case .gradient:
            return LinearGradient(
                colors: [Color("ForestDark"), Color("ForestGreen").opacity(0.35), Color("LakeNight")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .oledDark:
            return LinearGradient(
                colors: [Color.black, Color(red: 0.02, green: 0.06, blue: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .light:
            return LinearGradient(
                colors: [Self.warmCream, Color(red: 0.96, green: 0.95, blue: 0.93)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system: return .primary
        case .gradient, .oledDark: return .white
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13)
        }
    }
    
    func primaryTextColor() -> Color {
        switch self {
        case .system: return .primary
        case .gradient, .oledDark: return .white
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13)
        }
    }
    
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system: return .secondary
        case .gradient, .oledDark: return .white.opacity(0.65)
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.55)
        }
    }
    
    func secondaryTextColor() -> Color {
        switch self {
        case .system: return .secondary
        case .gradient, .oledDark: return .white.opacity(0.65)
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.55)
        }
    }
    
    func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.85)
        case .gradient: return .white.opacity(0.09)
        case .oledDark: return .white.opacity(0.06)
        case .light: return .white.opacity(0.92)
        }
    }
    
    func cardBackground() -> Color {
        switch self {
        case .system: return Color(.systemBackground)
        case .gradient: return .white.opacity(0.09)
        case .oledDark: return .white.opacity(0.06)
        case .light: return .white.opacity(0.92)
        }
    }
    
    func cardStroke(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
        case .gradient: return .white.opacity(0.12)
        case .oledDark: return .white.opacity(0.08)
        case .light: return .black.opacity(0.06)
        }
    }
    
    func cardStroke() -> Color {
        switch self {
        case .system: return Color(.separator)
        case .gradient: return .white.opacity(0.12)
        case .oledDark: return .white.opacity(0.08)
        case .light: return .black.opacity(0.06)
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
    
    func setTheme(_ theme: AppTheme, animated: Bool = true) {
        if animated {
            withAnimation(DS.Animation.themeTransition) {
                currentTheme = theme
            }
        } else {
            currentTheme = theme
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

// MARK: - ColorScheme Independence Helpers
extension AppTheme {
    func getPrimaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system: return primaryTextColor(for: colorScheme)
        case .gradient, .oledDark, .light: return primaryTextColor()
        }
    }
    
    func getSecondaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system: return secondaryTextColor(for: colorScheme)
        case .gradient, .oledDark, .light: return secondaryTextColor()
        }
    }
    
    func getCardBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system: return cardBackground(for: colorScheme)
        case .gradient, .oledDark, .light: return cardBackground()
        }
    }
    
    func getCardStroke(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system: return cardStroke(for: colorScheme)
        case .gradient, .oledDark, .light: return cardStroke()
        }
    }
    
    func getBackgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .system: return backgroundGradient(for: colorScheme)
        case .gradient, .oledDark, .light: return backgroundGradient(for: .light)
        }
    }
}

// MARK: - Liquid Glass aware theme colors
extension AppTheme {
    func glassPrimaryText(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.13)
        case .gradient, .oledDark: return .white
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13)
        }
    }

    func glassSecondaryText(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.65) : Color.black.opacity(0.5)
        case .gradient, .oledDark: return Color.white.opacity(0.65)
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.55)
        }
    }

    func glassStroke(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
        case .gradient: return Color.white.opacity(0.14)
        case .oledDark: return Color.white.opacity(0.1)
        case .light: return Color.black.opacity(0.06)
        }
    }
    
    func glassTint(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.02) : Color(red: 0.98, green: 0.96, blue: 0.93).opacity(0.15)
        case .gradient: return Color("ForestGreen").opacity(0.04)
        case .oledDark: return Color.white.opacity(0.015)
        case .light: return Color(red: 0.98, green: 0.96, blue: 0.93).opacity(0.2)
        }
    }

    func glassTertiaryText(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.3)
        case .gradient, .oledDark: return Color.white.opacity(0.35)
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.3)
        }
    }

    func sheetBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : .white
        case .gradient: return Color(red: 0.05, green: 0.26, blue: 0.16)
        case .oledDark: return Color(red: 0.06, green: 0.06, blue: 0.07)
        case .light: return .white
        }
    }

    func chipBackground(selected: Bool, for colorScheme: ColorScheme) -> Color {
        if selected {
            return glassPrimaryText(for: colorScheme).opacity(0.9)
        }
        return glassPrimaryText(for: colorScheme).opacity(0.12)
    }

    func chipTextColor(selected: Bool, for colorScheme: ColorScheme) -> Color {
        if selected {
            switch self {
            case .system:
                return colorScheme == .dark ? .black : .white
            case .gradient, .oledDark: return .black
            case .light: return .white
            }
        }
        return glassPrimaryText(for: colorScheme).opacity(0.9)
    }
}
