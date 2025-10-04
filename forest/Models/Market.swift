import Foundation

struct Coin: Identifiable, Codable {
    let id: UUID
    let name: String
    let symbol: String
    let iconName: String
    var quantity: Double
    var currentPrice: Double
    var averagePrice: Double
    let maxSupply: Double

    var marketValue: Double {
        currentPrice * maxSupply
    }

    var unrealizedGain: Double {
        (currentPrice - averagePrice) * quantity
    }
}

struct CoinPriceSnapshot: Codable {
    let timestamp: Date
    let price: Double
}

final class MarketViewModel: ObservableObject {
    @Published private(set) var coins: [Coin]
    @Published private(set) var priceHistory: [String: [CoinPriceSnapshot]] = [:]
    @Published var dailyTarget: Int = 4
    @Published private(set) var lastRefreshDate: Date = .distantPast

    struct Snapshot: Codable {
        let coins: [Coin]
        let priceHistory: [String: [CoinPriceSnapshot]]
        let dailyTarget: Int
        let lastRefreshDate: Date
    }

    init(snapshot: Snapshot? = nil) {
        if let snapshot {
            coins = snapshot.coins
            priceHistory = snapshot.priceHistory
            dailyTarget = snapshot.dailyTarget
            lastRefreshDate = snapshot.lastRefreshDate
        } else {
            coins = [
                Coin(id: UUID(), name: "Focus Leaf", symbol: "LEAF", iconName: "leaf.fill", quantity: 0, currentPrice: 1.0, averagePrice: 1.0, maxSupply: 1_000_000_000),
                Coin(id: UUID(), name: "Deep Root", symbol: "ROOT", iconName: "tree.fill", quantity: 0, currentPrice: 1.5, averagePrice: 1.5, maxSupply: 1_000_000_000),
                Coin(id: UUID(), name: "Serenity Bark", symbol: "BARK", iconName: "sparkles", quantity: 0, currentPrice: 0.75, averagePrice: 0.75, maxSupply: 1_000_000_000)
            ]
        }
        seedInitialHistoryIfNeeded()
    }

    func refreshPrices(force: Bool = false) {
        let calendar = Calendar.current
        if !force,
           calendar.isDate(Date(), inSameDayAs: lastRefreshDate) {
            return
        }

        coins = coins.map { coin in
            var updated = coin
            let randomShift = Double.random(in: -0.08...0.12)
            let newPrice = max(0.2, coin.currentPrice * (1 + randomShift))
            updated.currentPrice = newPrice
            let snapshot = CoinPriceSnapshot(timestamp: Date(), price: newPrice)
            var history = priceHistory[coin.symbol, default: []]
            history.append(snapshot)
            priceHistory[coin.symbol] = Array(history.suffix(60))
            return updated
        }
        lastRefreshDate = Date()
    }

    func buy(symbol: String, amount: Double, wallet: WalletViewModel) -> Double? {
        guard let index = coins.firstIndex(where: { $0.symbol == symbol }) else { return nil }
        let coin = coins[index]
        guard wallet.balance >= amount else { return nil }

        let quantityToBuy = amount / coin.currentPrice
        wallet.updateBalance(wallet.balance - amount)
        wallet.addMarketTransaction(amount: -amount, description: "TXN_MARKET_BUY", arguments: [coin.symbol])

        var updatedCoin = coin
        let totalCost = coin.averagePrice * coin.quantity + amount
        updatedCoin.quantity += quantityToBuy
        if updatedCoin.quantity > 0 {
            updatedCoin.averagePrice = totalCost / updatedCoin.quantity
        }
        coins[index] = updatedCoin
        return amount
    }

    func sell(symbol: String, quantity: Double, wallet: WalletViewModel) -> Bool {
        guard let index = coins.firstIndex(where: { $0.symbol == symbol }) else { return false }
        var coin = coins[index]
        guard coin.quantity >= quantity else { return false }

        let proceeds = quantity * coin.currentPrice
        coin.quantity -= quantity
        coins[index] = coin
        wallet.updateBalance(wallet.balance + proceeds)
        wallet.addMarketTransaction(amount: proceeds, description: "TXN_MARKET_SELL", arguments: [coin.symbol])
        return true
    }
    
    func snapshot() -> Snapshot {
        Snapshot(coins: coins,
                 priceHistory: priceHistory,
                 dailyTarget: dailyTarget,
                 lastRefreshDate: lastRefreshDate)
    }

    private func seedInitialHistoryIfNeeded() {
        let now = Date()
        for coin in coins {
            if priceHistory[coin.symbol]?.isEmpty ?? true {
                priceHistory[coin.symbol] = [
                    CoinPriceSnapshot(timestamp: now, price: coin.currentPrice)
                ]
            }
        }
    }
}

