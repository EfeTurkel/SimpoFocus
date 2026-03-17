import Foundation

struct WalletTransaction: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let amount: Double
    let type: TransactionType
    let description: String

    enum TransactionType: String, Codable, Hashable {
        case earned
        case spent
        case market
    }
}

final class WalletViewModel: ObservableObject {
    @Published private(set) var balance: Double = 0
    @Published private(set) var passiveIncomeBoost: Double = 0
    @Published var transactions: [WalletTransaction] = []
    @Published private(set) var stakedBalance: Double = 0
    @Published private(set) var stakingAccruedInterest: Double = 0
    @Published private(set) var earningMultiplier: Double = 1.0
    @Published private(set) var earningMultiplierExpiresAt: Date?
    @Published private(set) var bankBoostMultiplier: Double = 1.0
    @Published private(set) var bankBoostExpiresAt: Date?
    @Published private(set) var marketRefreshCredits: Int = 0
    @Published private(set) var marketRefreshCreditsExpiresAt: Date?

    struct Snapshot: Codable {
        let balance: Double
        let passiveIncomeBoost: Double
        let transactions: [WalletTransaction]
        let stakedBalance: Double
        let stakingAccruedInterest: Double
        let earningMultiplier: Double
        let earningMultiplierExpiresAt: Date?
        let bankBoostMultiplier: Double
        let bankBoostExpiresAt: Date?
        let marketRefreshCredits: Int
        let marketRefreshCreditsExpiresAt: Date?

        init(balance: Double,
             passiveIncomeBoost: Double,
             transactions: [WalletTransaction],
             stakedBalance: Double,
             stakingAccruedInterest: Double,
             earningMultiplier: Double,
             earningMultiplierExpiresAt: Date?,
             bankBoostMultiplier: Double,
             bankBoostExpiresAt: Date?,
             marketRefreshCredits: Int,
             marketRefreshCreditsExpiresAt: Date?) {
            self.balance = balance
            self.passiveIncomeBoost = passiveIncomeBoost
            self.transactions = transactions
            self.stakedBalance = stakedBalance
            self.stakingAccruedInterest = stakingAccruedInterest
            self.earningMultiplier = earningMultiplier
            self.earningMultiplierExpiresAt = earningMultiplierExpiresAt
            self.bankBoostMultiplier = bankBoostMultiplier
            self.bankBoostExpiresAt = bankBoostExpiresAt
            self.marketRefreshCredits = marketRefreshCredits
            self.marketRefreshCreditsExpiresAt = marketRefreshCreditsExpiresAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            balance = try container.decode(Double.self, forKey: .balance)
            passiveIncomeBoost = try container.decode(Double.self, forKey: .passiveIncomeBoost)
            transactions = try container.decode([WalletTransaction].self, forKey: .transactions)
            stakedBalance = try container.decode(Double.self, forKey: .stakedBalance)
            stakingAccruedInterest = try container.decode(Double.self, forKey: .stakingAccruedInterest)
            earningMultiplier = try container.decodeIfPresent(Double.self, forKey: .earningMultiplier) ?? 1.0
            earningMultiplierExpiresAt = try container.decodeIfPresent(Date.self, forKey: .earningMultiplierExpiresAt)
            bankBoostMultiplier = try container.decodeIfPresent(Double.self, forKey: .bankBoostMultiplier) ?? 1.0
            bankBoostExpiresAt = try container.decodeIfPresent(Date.self, forKey: .bankBoostExpiresAt)
            marketRefreshCredits = try container.decodeIfPresent(Int.self, forKey: .marketRefreshCredits) ?? 0
            marketRefreshCreditsExpiresAt = try container.decodeIfPresent(Date.self, forKey: .marketRefreshCreditsExpiresAt)
        }
    }

    init(snapshot: Snapshot? = nil) {
        if let snapshot {
            apply(snapshot)
        }
    }

    func earn(amount: Double, description: String) {
        balance += amount
        let key = description.isEmpty ? "TXN_REWARD_POMODORO" : description
        append(amount: amount, type: .earned, descriptionKey: key)
    }

    func spend(amount: Double, description: String) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        let key = descriptionKey(for: description)
        append(amount: -amount, type: .spent, descriptionKey: key)
        return true
    }

    func applyPassiveBoost(_ boost: Double) {
        passiveIncomeBoost += boost
    }

    func addMarketTransaction(amount: Double, description: String, arguments: [CVarArg] = []) {
        append(amount: amount, type: .market, descriptionKey: description, arguments: arguments)
    }

    func stake(amount: Double, description: String) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        stakedBalance += amount
        let key = descriptionKey(for: description)
        append(amount: -amount, type: .market, descriptionKey: key)
        return true
    }

    func unstake(amount: Double, description: String) -> Bool {
        guard stakedBalance >= amount else { return false }
        stakedBalance -= amount
        balance += amount
        let key = descriptionKey(for: description)
        append(amount: amount, type: .market, descriptionKey: key)
        return true
    }

    func depositInterest(amount: Double) {
        stakingAccruedInterest += amount
        stakedBalance += amount
        append(amount: amount, type: .earned, descriptionKey: "TXN_INTEREST_GAIN")
    }

    func resetAccruedInterest() {
        stakingAccruedInterest = 0
    }

    func addPurchasedCoins(amount: Double) {
        balance += amount
        append(amount: amount, type: .earned, descriptionKey: "TXN_COIN_PACK_PURCHASED")
    }

    var currentEarningMultiplier: Double {
        refreshExpiredPerksIfNeeded()
        return max(1, earningMultiplier)
    }

    var currentBankBoostMultiplier: Double {
        refreshExpiredPerksIfNeeded()
        return max(1, bankBoostMultiplier)
    }

    var hasActiveEarningMultiplier: Bool {
        refreshExpiredPerksIfNeeded()
        return currentEarningMultiplier > 1
    }

    var hasActiveBankBoost: Bool {
        refreshExpiredPerksIfNeeded()
        return currentBankBoostMultiplier > 1
    }

    var hasActiveMarketPerk: Bool {
        refreshExpiredPerksIfNeeded()
        return marketRefreshCredits > 0
    }

    func activateEarningMultiplier(multiplier: Double, duration: TimeInterval, cost: Double) -> Bool {
        guard spend(amount: cost, description: "TXN_TOKEN_UTILITY_MULTIPLIER") else { return false }
        let expiresAt = Date().addingTimeInterval(duration)
        earningMultiplier = max(1, multiplier)
        earningMultiplierExpiresAt = expiresAt
        return true
    }

    func activateBankBoost(multiplier: Double, duration: TimeInterval, cost: Double) -> Bool {
        guard spend(amount: cost, description: "TXN_TOKEN_UTILITY_BANK") else { return false }
        let expiresAt = Date().addingTimeInterval(duration)
        bankBoostMultiplier = max(1, multiplier)
        bankBoostExpiresAt = expiresAt
        return true
    }

    func activateMarketRefreshCredits(count: Int, duration: TimeInterval, cost: Double) -> Bool {
        guard spend(amount: cost, description: "TXN_TOKEN_UTILITY_MARKET") else { return false }
        refreshExpiredPerksIfNeeded()
        marketRefreshCredits += max(0, count)
        marketRefreshCreditsExpiresAt = Date().addingTimeInterval(duration)
        return true
    }

    func consumeMarketRefreshCreditIfAvailable() -> Bool {
        refreshExpiredPerksIfNeeded()
        guard marketRefreshCredits > 0 else { return false }
        marketRefreshCredits -= 1
        return true
    }

    var availableBalance: Double {
        balance
    }

    var totalBalance: Double {
        balance + stakedBalance
    }

    var earnedFromInterest: Double {
        stakingAccruedInterest
    }

    func updateBalance(_ newValue: Double) {
        balance = newValue
    }

    private func descriptionKey(for raw: String) -> String {
        switch raw {
        case "TXN_REWARD_POMODORO",
             "TXN_INTEREST_GAIN",
             "TXN_STAKE_DEPOSIT",
             "TXN_STAKE_WITHDRAW",
             "TXN_THEME_UNLOCK",
             "TXN_MARKET_BUY",
             "TXN_MARKET_SELL":
            return raw
        case "Faize yatırıldı":
            return "TXN_STAKE_DEPOSIT"
        case "Faiz hesabından çekildi":
            return "TXN_STAKE_WITHDRAW"
        case "Faiz kazancı":
            return "TXN_INTEREST_GAIN"
        case "Pomodoro ödülü":
            return "TXN_REWARD_POMODORO"
        default:
            return raw
        }
    }

    private func append(amount: Double, type: WalletTransaction.TransactionType, descriptionKey: String, arguments: [CVarArg] = []) {
        let text: String
        if descriptionKey.starts(with: "TXN_") {
            text = LocalizationManager.shared.translate(descriptionKey, arguments: arguments)
        } else {
            text = LocalizationManager.shared.translate(descriptionKey, fallback: descriptionKey, arguments: arguments)
        }
        let entry = WalletTransaction(id: UUID(), date: Date(), amount: amount, type: type, description: text)
        var updated = transactions
        updated.insert(entry, at: 0)
        if updated.count > 250 {
            updated = Array(updated.prefix(250))
        }
        if updated != transactions {
            transactions = updated
        } else {
            transactions = updated
        }
    }

    private func refreshExpiredPerksIfNeeded() {
        let now = Date()
        if let expiresAt = earningMultiplierExpiresAt, now >= expiresAt {
            earningMultiplier = 1.0
            earningMultiplierExpiresAt = nil
        }
        if let expiresAt = bankBoostExpiresAt, now >= expiresAt {
            bankBoostMultiplier = 1.0
            bankBoostExpiresAt = nil
        }
        if let expiresAt = marketRefreshCreditsExpiresAt, now >= expiresAt {
            marketRefreshCredits = 0
            marketRefreshCreditsExpiresAt = nil
        }
    }

    func snapshot() -> Snapshot {
        Snapshot(balance: balance,
                 passiveIncomeBoost: passiveIncomeBoost,
                 transactions: transactions,
                 stakedBalance: stakedBalance,
                 stakingAccruedInterest: stakingAccruedInterest,
                 earningMultiplier: earningMultiplier,
                 earningMultiplierExpiresAt: earningMultiplierExpiresAt,
                 bankBoostMultiplier: bankBoostMultiplier,
                 bankBoostExpiresAt: bankBoostExpiresAt,
                 marketRefreshCredits: marketRefreshCredits,
                 marketRefreshCreditsExpiresAt: marketRefreshCreditsExpiresAt)
    }

    func apply(_ snapshot: Snapshot) {
        balance = snapshot.balance
        passiveIncomeBoost = snapshot.passiveIncomeBoost
        transactions = snapshot.transactions
        stakedBalance = snapshot.stakedBalance
        stakingAccruedInterest = snapshot.stakingAccruedInterest
        earningMultiplier = snapshot.earningMultiplier
        earningMultiplierExpiresAt = snapshot.earningMultiplierExpiresAt
        bankBoostMultiplier = snapshot.bankBoostMultiplier
        bankBoostExpiresAt = snapshot.bankBoostExpiresAt
        marketRefreshCredits = snapshot.marketRefreshCredits
        marketRefreshCreditsExpiresAt = snapshot.marketRefreshCreditsExpiresAt
        refreshExpiredPerksIfNeeded()
    }
}

