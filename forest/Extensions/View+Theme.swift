import SwiftUI

extension View {
    var themeColors: ThemeColors {
        ThemeColors()
    }
    
    /// Foreground color suitable over glass materials for primary text/icons
    func onGlassPrimary() -> some View { modifier(GlassForegroundModifier(level: .primary)) }
    /// Foreground color suitable over glass materials for secondary text/icons
    func onGlassSecondary() -> some View { modifier(GlassForegroundModifier(level: .secondary)) }
    /// Foreground color suitable over glass materials for very subdued text (terms, hints)
    func onGlassTertiary() -> some View { modifier(GlassForegroundModifier(level: .tertiary)) }
}

struct ThemeColors {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var background: LinearGradient {
        themeManager.currentTheme.backgroundGradient(for: colorScheme)
    }
    
    var primaryText: Color {
        themeManager.currentTheme.primaryTextColor(for: colorScheme)
    }
    
    var secondaryText: Color {
        themeManager.currentTheme.secondaryTextColor(for: colorScheme)
    }
    
    var cardBackground: Color {
        themeManager.currentTheme.cardBackground(for: colorScheme)
    }
    
    var cardStroke: Color {
        themeManager.currentTheme.cardStroke(for: colorScheme)
    }
}

private struct GlassForegroundModifier: ViewModifier {
    enum Level { case primary, secondary, tertiary }
    let level: Level
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let color: Color = switch level {
        case .primary: themeManager.currentTheme.glassPrimaryText(for: colorScheme)
        case .secondary: themeManager.currentTheme.glassSecondaryText(for: colorScheme)
        case .tertiary: themeManager.currentTheme.glassTertiaryText(for: colorScheme)
        }
        return content
            .foregroundStyle(color)
            .animation(DS.Animation.themeTransition, value: themeManager.currentTheme)
    }
}

