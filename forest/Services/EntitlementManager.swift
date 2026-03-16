import Foundation
import Combine

final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()

    private let storeKit = StoreKitService.shared
    private var cancellables = Set<AnyCancellable>()

    @MainActor @Published private(set) var isPro: Bool = false {
        didSet {
            UserDefaults.standard.set(isPro, forKey: cacheKey)
        }
    }

    private let cacheKey = "entitlement_isPro"
    private let maxFreeCategories = 3

    private init() {
        let cached = UserDefaults.standard.bool(forKey: cacheKey)
        _isPro = Published(initialValue: cached)

        storeKit.$purchasedSubscriptions
            .receive(on: RunLoop.main)
            .sink { [weak self] subs in
                Task { @MainActor in
                    self?.isPro = !subs.isEmpty
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func refresh() async {
        await storeKit.updatePurchasedSubscriptions()
    }

    @MainActor
    func canAddCategory(currentCount: Int) -> Bool {
        isPro || currentCount < maxFreeCategories
    }

    var maxFreeCategoryCount: Int { maxFreeCategories }

    @MainActor var hasAdvancedAnalytics: Bool { isPro }

    @MainActor var hasAllThemes: Bool { isPro }

    @MainActor var hasAdvancedTimerSettings: Bool { isPro }

    @MainActor var coinMultiplier: Double { isPro ? 2.0 : 1.0 }
}
