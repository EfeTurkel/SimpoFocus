import Foundation
import Combine

final class RootViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .forest
}

enum AppTab: String, CaseIterable, Identifiable {
    case forest
    case market
    case bank
    case wallet
    case home

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .forest: return "TAB_FOCUS"
        case .market: return "TAB_MARKET"
        case .bank: return "TAB_BANK"
        case .wallet: return "TAB_WALLET"
        case .home: return "TAB_HOME"
        }
    }

    var defaultTitle: String {
        switch self {
        case .forest: return "Odak"
        case .market: return "Pazar"
        case .bank: return "Banka"
        case .wallet: return "Cüzdan"
        case .home: return "Ev"
        }
    }

    var icon: String {
        switch self {
        case .forest: return "leaf.circle"
        case .market: return "chart.line.uptrend.xyaxis"
        case .bank: return "building.columns"
        case .wallet: return "wallet.bifold"
        case .home: return "house.fill"
        }
    }
}

