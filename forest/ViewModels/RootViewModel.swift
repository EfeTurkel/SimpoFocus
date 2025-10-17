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
    case bank
    case wallet
    case home

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .forest: return "TAB_FOCUS"
        case .bank: return "TAB_BANK"
        case .wallet: return "TAB_WALLET"
        case .home: return "TAB_HOME"
        }
    }

    var defaultTitle: String {
        switch self {
        case .forest: return "Odak"
        case .bank: return "Banka"
        case .wallet: return "Cüzdan"
        case .home: return "Ev"
        }
    }

    var icon: String {
        switch self {
        case .forest: return "leaf.circle"
        case .bank: return "building.columns"
        case .wallet: return "wallet.bifold"
        case .home: return "house.fill"
        }
    }
}

