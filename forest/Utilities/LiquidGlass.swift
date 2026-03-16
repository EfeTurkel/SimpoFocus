import SwiftUI

public enum LiquidGlassStyle {
    case system
    case hero
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

    private var isHero: Bool { style == .hero }

    func body(content: Content) -> some View {
        content
            .background(materialBackground)
            .overlay(lensingOverlay)
            .animation(DS.Animation.themeTransition, value: themeManager.currentTheme)
    }

    @ViewBuilder
    private var materialBackground: some View {
        ZStack {
            Rectangle()
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
            Rectangle()
                .fill(themeManager.currentTheme.glassTint(for: colorScheme))
        }
    }

    @ViewBuilder
    private var lensingOverlay: some View {
        let edgeHeight: CGFloat = isHero ? 0.04 : 0.03
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if edgeMask.contains(.top) {
                    LinearGradient(colors: topHighlightColors,
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .frame(height: max(1, size.height * edgeHeight))
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                if isHero && edgeMask.contains(.top) {
                    LinearGradient(colors: heroInnerGlow,
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .frame(height: max(1, size.height * 0.15))
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                if edgeMask.contains(.bottom) {
                    LinearGradient(colors: bottomHighlightColors,
                                   startPoint: .bottom,
                                   endPoint: .top)
                        .frame(height: max(1, size.height * edgeHeight))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var heroInnerGlow: [Color] {
        switch themeManager.currentTheme {
        case .system:
            return colorScheme == .dark
            ? [Color.white.opacity(0.04), .clear]
            : [Color.white.opacity(0.25), .clear]
        case .gradient:
            return [Color("ForestGreen").opacity(0.06), .clear]
        case .oledDark:
            return [Color.white.opacity(0.03), .clear]
        case .light:
            return [Color.white.opacity(0.3), .clear]
        }
    }

    private var topHighlightColors: [Color] {
        let multiplier: CGFloat = isHero ? 1.5 : 1.0
        switch themeManager.currentTheme {
        case .system:
            return colorScheme == .dark
            ? [Color.white.opacity(0.10 * multiplier), Color.white.opacity(0.03), .clear]
            : [Color.white.opacity(0.15 * multiplier), Color.white.opacity(0.05), .clear]
        case .gradient, .oledDark:
            return [Color.white.opacity(0.10 * multiplier), Color.white.opacity(0.03), .clear]
        case .light:
            return [Color.white.opacity(0.20 * multiplier), Color.white.opacity(0.06), .clear]
        }
    }

    private var bottomHighlightColors: [Color] {
        switch themeManager.currentTheme {
        case .system:
            return colorScheme == .dark
            ? [Color.black.opacity(0.12), Color.black.opacity(0.04), .clear]
            : [Color.black.opacity(0.06), Color.black.opacity(0.02), .clear]
        case .gradient, .oledDark:
            return [Color.black.opacity(0.12), Color.black.opacity(0.04), .clear]
        case .light:
            return [Color.black.opacity(0.03), Color.black.opacity(0.01), .clear]
        }
    }
}

public extension View {
    func liquidGlass(_ style: LiquidGlassStyle = .system, edgeMask: EdgeMask = []) -> some View {
        modifier(LiquidGlassBackgroundModifier(style: style, edgeMask: edgeMask))
    }
}
