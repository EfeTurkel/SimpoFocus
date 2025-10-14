import SwiftUI

extension View {
    var themeColors: ThemeColors {
        ThemeColors()
    }
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

