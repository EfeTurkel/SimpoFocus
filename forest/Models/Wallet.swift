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

    struct Snapshot: Codable {
        let balance: Double
        let passiveIncomeBoost: Double
        let transactions: [WalletTransaction]
        let stakedBalance: Double
        let stakingAccruedInterest: Double
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

    func snapshot() -> Snapshot {
        Snapshot(balance: balance,
                 passiveIncomeBoost: passiveIncomeBoost,
                 transactions: transactions,
                 stakedBalance: stakedBalance,
                 stakingAccruedInterest: stakingAccruedInterest)
    }

    func apply(_ snapshot: Snapshot) {
        balance = snapshot.balance
        passiveIncomeBoost = snapshot.passiveIncomeBoost
        transactions = snapshot.transactions
        stakedBalance = snapshot.stakedBalance
        stakingAccruedInterest = snapshot.stakingAccruedInterest
    }
}

