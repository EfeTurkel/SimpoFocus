import Foundation
import Combine

final class RootViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .forest {
        didSet {
            UserDefaults.standard.set(selectedTab.rawValue, forKey: "selectedTab")
        }
    }
    
    private let storageKey = "selectedTab"
    
    init() {
        // Restore selected tab from UserDefaults
        if let savedTab = UserDefaults.standard.string(forKey: storageKey),
           let tab = AppTab(rawValue: savedTab) {
            selectedTab = tab
        }
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case forest
    case finance

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .forest: return "TAB_FOCUS"
        case .finance: return "TAB_FINANCE"
        }
    }

    var defaultTitle: String {
        switch self {
        case .forest: return "Odak"
        case .finance: return "Finans"
        }
    }

    var icon: String {
        switch self {
        case .forest: return "leaf.circle"
        case .finance: return "banknote"
        }
    }

    var filledIcon: String {
        switch self {
        case .forest: return "leaf.circle.fill"
        case .finance: return "banknote.fill"
        }
    }
}

