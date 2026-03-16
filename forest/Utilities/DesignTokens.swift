import SwiftUI

enum DS {

    enum Radius {
        static let small: CGFloat = 14
        static let medium: CGFloat = 20
        static let large: CGFloat = 28
        static let xl: CGFloat = 36
    }

    enum Padding {
        static let screen: CGFloat = 24
        static let card: CGFloat = 20
        static let section: CGFloat = 16
        static let element: CGFloat = 12
        static let xl: CGFloat = 32
    }

    enum IconSize {
        static let small: CGFloat = 32
        static let medium: CGFloat = 44
        static let large: CGFloat = 60
    }

    enum Typography {
        static let heroTimer = Font.system(size: 72, weight: .bold, design: .rounded)
        static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
        static let micro = Font.system(size: 11, weight: .medium, design: .rounded)
    }

    enum Animation {
        static let springResponse: Double = 0.35
        static let springDamping: Double = 0.82
        static let defaultSpring = SwiftUI.Animation.spring(response: springResponse, dampingFraction: springDamping)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let slowSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85)
        static let themeTransition = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let breathing = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        static func staggerDelay(index: Int, base: Double = 0.05) -> Double {
            Double(index) * base
        }
    }
}
