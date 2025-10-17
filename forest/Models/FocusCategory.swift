import Foundation
import SwiftUI

struct CustomCategory: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let color: CategoryColor
    
    init(id: UUID = UUID(), name: String, icon: String, color: CategoryColor) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
    
    var displayName: String { name }
    var iconName: String { icon }
    var categoryColor: Color { color.color }
}

enum CategoryColor: String, CaseIterable, Codable {
    case blue, purple, green, orange, pink, red, indigo, teal, cyan, mint
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        case .indigo: return .indigo
        case .teal: return .teal
        case .cyan: return .cyan
        case .mint: return .mint
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .green: return "Green"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .red: return "Red"
        case .indigo: return "Indigo"
        case .teal: return "Teal"
        case .cyan: return "Cyan"
        case .mint: return "Mint"
        }
    }
}

enum FocusCategory: Codable, Identifiable, Hashable {
    case predefined(PredefinedCategory)
    case custom(CustomCategory)
    
    enum PredefinedCategory: String, CaseIterable, Codable {
        case untagged
        case coding
        case algorithms
        case physics
        case business
        case misc
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case type
        case predefined
        case custom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "predefined":
            let predefined = try container.decode(PredefinedCategory.self, forKey: .predefined)
            self = .predefined(predefined)
        case "custom":
            let custom = try container.decode(CustomCategory.self, forKey: .custom)
            self = .custom(custom)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown FocusCategory type: \(type)"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .predefined(let predefined):
            try container.encode("predefined", forKey: .type)
            try container.encode(predefined, forKey: .predefined)
        case .custom(let custom):
            try container.encode("custom", forKey: .type)
            try container.encode(custom, forKey: .custom)
        }
    }
    
    var id: String {
        switch self {
        case .predefined(let category): return category.rawValue
        case .custom(let category): return category.id.uuidString
        }
    }
    
    var displayName: String {
        switch self {
        case .predefined(let category):
            return LocalizationManager.shared.translate("CATEGORY_\(category.rawValue.uppercased())")
        case .custom(let category):
            return category.displayName
        }
    }
    
    var icon: String {
        switch self {
        case .predefined(let category):
            switch category {
            case .untagged: return "circle"
            case .coding: return "chevron.left.forwardslash.chevron.right"
            case .algorithms: return "function"
            case .physics: return "atom"
            case .business: return "chart.line.uptrend.xyaxis"
            case .misc: return "star.fill"
            }
        case .custom(let category):
            return category.iconName
        }
    }
    
    var color: Color {
        switch self {
        case .predefined(let category):
            switch category {
            case .untagged: return Color.blue.opacity(0.7)
            case .coding: return Color.purple
            case .algorithms: return Color.green
            case .physics: return Color(red: 0.4, green: 0.6, blue: 0.9)
            case .business: return Color.pink
            case .misc: return Color.orange
            }
        case .custom(let category):
            return category.categoryColor
        }
    }
    
    static var allCases: [FocusCategory] {
        PredefinedCategory.allCases.map { .predefined($0) }
    }
    
    static func == (lhs: FocusCategory, rhs: FocusCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

