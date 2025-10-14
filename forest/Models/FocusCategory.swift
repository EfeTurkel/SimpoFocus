import Foundation
import SwiftUI

enum FocusCategory: String, Codable, CaseIterable, Identifiable {
    case untagged
    case coding
    case algorithms
    case physics
    case business
    case misc
    
    var id: String { rawValue }
    
    var displayName: String {
        LocalizationManager.shared.translate("CATEGORY_\(rawValue.uppercased())")
    }
    
    var icon: String {
        switch self {
        case .untagged: return "circle"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .algorithms: return "function"
        case .physics: return "atom"
        case .business: return "chart.line.uptrend.xyaxis"
        case .misc: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .untagged: return Color.blue.opacity(0.7)
        case .coding: return Color.purple
        case .algorithms: return Color.green
        case .physics: return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .business: return Color.pink
        case .misc: return Color.orange
        }
    }
}

