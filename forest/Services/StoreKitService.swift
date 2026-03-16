import Foundation
import StoreKit

final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    static let proWeeklyID   = "com.efeturkel.simpoapp.pro.weekly"
    static let proMonthlyID  = "com.efeturkel.simpoapp.pro.monthly"
    static let proYearlyID   = "com.efeturkel.simpoapp.pro.yearly"
    static let coinsSmallID  = "com.efeturkel.simpoapp.coins.small"
    static let coinsMediumID = "com.efeturkel.simpoapp.coins.medium"
    static let coinsLargeID  = "com.efeturkel.simpoapp.coins.large"

    static let subscriptionIDs: Set<String> = [proWeeklyID, proMonthlyID, proYearlyID]
    static let consumableIDs: Set<String> = [coinsSmallID, coinsMediumID, coinsLargeID]
    static let allProductIDs: Set<String> = subscriptionIDs.union(consumableIDs)

    static let coinAmounts: [String: Double] = [
        coinsSmallID: 500,
        coinsMediumID: 1500,
        coinsLargeID: 5000
    ]

    @MainActor @Published private(set) var subscriptionProducts: [Product] = []
    @MainActor @Published private(set) var coinProducts: [Product] = []
    @MainActor @Published private(set) var purchasedSubscriptions: [Product] = []
    @MainActor @Published private(set) var isLoading = false
    @MainActor @Published var loadError: String?

    var onCoinsPurchased: ((Double) -> Void)?

    private var transactionListener: Task<Void, Error>?
    private var didStartLoading = false

    private init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Call once from .task {} on the root view to kick off product loading.
    @MainActor
    func startIfNeeded() {
        guard !didStartLoading else { return }
        didStartLoading = true
        Task { await loadProducts() }
    }

    @MainActor
    func loadProducts() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: Self.allProductIDs)

            subscriptionProducts = products
                .filter { Self.subscriptionIDs.contains($0.id) }
                .sorted { $0.price < $1.price }

            coinProducts = products
                .filter { Self.consumableIDs.contains($0.id) }
                .sorted { $0.price < $1.price }

            await updatePurchasedSubscriptions()
        } catch {
            loadError = error.localizedDescription
            #if DEBUG
            print("StoreKitService: Failed to load products: \(error)")
            #endif
        }
    }

    @MainActor
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            if Self.consumableIDs.contains(product.id) {
                let coins = Self.coinAmounts[product.id] ?? 0
                onCoinsPurchased?(coins)
            }

            await transaction.finish()
            await updatePurchasedSubscriptions()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    @MainActor
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedSubscriptions()
    }

    @MainActor
    var isPro: Bool {
        !purchasedSubscriptions.isEmpty
    }

    @MainActor
    func updatePurchasedSubscriptions() async {
        var active: [Product] = []

        for product in subscriptionProducts {
            guard let statuses = try? await product.subscription?.status else { continue }
            for status in statuses {
                guard case .verified(let transaction) = status.transaction,
                      transaction.revocationDate == nil else { continue }

                if status.state == .subscribed || status.state == .inGracePeriod {
                    active.append(product)
                    break
                }
            }
        }

        purchasedSubscriptions = active
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)

                    if Self.consumableIDs.contains(transaction.productID) {
                        let coins = Self.coinAmounts[transaction.productID] ?? 0
                        await MainActor.run { self.onCoinsPurchased?(coins) }
                    }

                    await transaction.finish()
                    await MainActor.run {
                        Task { await self.updatePurchasedSubscriptions() }
                    }
                } catch {
                    #if DEBUG
                    print("StoreKitService: Transaction verification failed: \(error)")
                    #endif
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
