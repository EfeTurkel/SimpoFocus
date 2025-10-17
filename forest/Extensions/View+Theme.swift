import SwiftUI

extension View {
    var themeColors: ThemeColors {
        ThemeColors()
    }
    
    /// Foreground color suitable over glass materials for primary text/icons
    func onGlassPrimary() -> some View { modifier(GlassForegroundModifier(primary: true)) }
    /// Foreground color suitable over glass materials for secondary text/icons
    func onGlassSecondary() -> some View { modifier(GlassForegroundModifier(primary: false)) }
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
    let primary: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let color: Color = primary
            ? themeManager.currentTheme.glassPrimaryText(for: colorScheme)
            : themeManager.currentTheme.glassSecondaryText(for: colorScheme)
        return content.foregroundStyle(color)
    }
}

