import SwiftUI

public enum LiquidGlassStyle {
    case system
    case header
    case card
}

public struct EdgeMask: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let top = EdgeMask(rawValue: 1 << 0)
    public static let bottom = EdgeMask(rawValue: 1 << 1)
    public static let leading = EdgeMask(rawValue: 1 << 2)
    public static let trailing = EdgeMask(rawValue: 1 << 3)
    public static let all: EdgeMask = [.top, .bottom, .leading, .trailing]
}

private struct LiquidGlassBackgroundModifier: ViewModifier {
    let style: LiquidGlassStyle
    let edgeMask: EdgeMask
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .background(materialBackground)
            .overlay(lensingOverlay)
    }

    @ViewBuilder
    private var materialBackground: some View {
        // Use theme-aware background colors instead of system materials
        Rectangle()
            .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
    }

    @ViewBuilder
    private var lensingOverlay: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if edgeMask.contains(.top) {
                    LinearGradient(colors: topHighlightColors,
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .frame(height: max(1, size.height * 0.06))
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                if edgeMask.contains(.bottom) {
                    LinearGradient(colors: bottomHighlightColors,
                                   startPoint: .bottom,
                                   endPoint: .top)
                        .frame(height: max(1, size.height * 0.06))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                if edgeMask.contains(.leading) {
                    LinearGradient(colors: sideHighlightColors,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                        .frame(width: max(1, size.width * 0.06))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if edgeMask.contains(.trailing) {
                    LinearGradient(colors: sideHighlightColors,
                                   startPoint: .trailing,
                                   endPoint: .leading)
                        .frame(width: max(1, size.width * 0.06))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var topHighlightColors: [Color] {
        switch themeManager.currentTheme {
        case .system:
            return colorScheme == .dark
            ? [Color.white.opacity(0.16), Color.white.opacity(0.04), .clear]
            : [Color.white.opacity(0.22), Color.white.opacity(0.08), .clear]
        case .gradient, .oledDark:
            return [Color.white.opacity(0.16), Color.white.opacity(0.04), .clear]
        case .light:
            return [Color.white.opacity(0.3), Color.white.opacity(0.1), .clear]
        }
    }

    private var bottomHighlightColors: [Color] {
        switch themeManager.currentTheme {
        case .system:
            return colorScheme == .dark
            ? [Color.black.opacity(0.25), Color.black.opacity(0.1), .clear]
            : [Color.black.opacity(0.18), Color.black.opacity(0.06), .clear]
        case .gradient, .oledDark:
            return [Color.black.opacity(0.25), Color.black.opacity(0.1), .clear]
        case .light:
            return [Color.black.opacity(0.05), Color.black.opacity(0.02), .clear]
        }
    }

    private var sideHighlightColors: [Color] {
        switch themeManager.currentTheme {
        case .system:
            return colorScheme == .dark
            ? [Color.white.opacity(0.08), Color.white.opacity(0.02), .clear]
            : [Color.white.opacity(0.12), Color.white.opacity(0.04), .clear]
        case .gradient, .oledDark:
            return [Color.white.opacity(0.08), Color.white.opacity(0.02), .clear]
        case .light:
            return [Color.white.opacity(0.2), Color.white.opacity(0.05), .clear]
        }
    }
}

public extension View {
    func liquidGlass(_ style: LiquidGlassStyle = .system, edgeMask: EdgeMask = []) -> some View {
        modifier(LiquidGlassBackgroundModifier(style: style, edgeMask: edgeMask))
    }
}


