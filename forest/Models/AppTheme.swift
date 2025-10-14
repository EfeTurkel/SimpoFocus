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
        switch self {
        case .system:
            return colorScheme == .dark ? 
                LinearGradient(colors: [Color.black, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
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
        switch self {
        case .system:
            return colorScheme == .dark ? .white : .black
        case .gradient, .oledDark:
            return .white
        case .light:
            return .black
        }
    }
    
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.65)
        case .gradient, .oledDark:
            return .white.opacity(0.7)
        case .light:
            return .black.opacity(0.65)
        }
    }
    
    func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.08)
        case .gradient:
            return .white.opacity(0.08)
        case .oledDark:
            return .white.opacity(0.05)
        case .light:
            return .black.opacity(0.08)
        }
    }
    
    func cardStroke(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.25)
        case .gradient:
            return .white.opacity(0.12)
        case .oledDark:
            return .white.opacity(0.1)
        case .light:
            return .black.opacity(0.25)
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

