import Foundation

final class BankService: ObservableObject {
    @Published private(set) var annualInterestRate: Double
    @Published private(set) var lastRateUpdate: Date
    @Published private(set) var lastInterestApplied: Date

    private let calendar = Calendar.current

    init(snapshot: BankSnapshot? = nil) {
        if let snapshot {
            annualInterestRate = snapshot.annualInterestRate
            lastRateUpdate = snapshot.lastRateUpdate
            lastInterestApplied = snapshot.lastInterestApplied
        } else {
            annualInterestRate = Double.random(in: 0.05...0.08)
            lastRateUpdate = Date()
            lastInterestApplied = Date()
        }
    }

    func updateWeeklyRateIfNeeded() {
        guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: lastRateUpdate), Date() >= nextWeek else { return }
        annualInterestRate = Double.random(in: 0.05...0.08)
        lastRateUpdate = Date()
    }

    func applyDailyInterest(to wallet: WalletViewModel) {
        let dailyRate = annualInterestRate / 365
        let interest = wallet.stakedBalance * dailyRate
        guard interest > 0 else { return }
        wallet.depositInterest(amount: interest)
        lastInterestApplied = Date()
    }

    func applyDailyInterestIfNeeded(to wallet: WalletViewModel) {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: lastInterestApplied), Date() >= nextDay else { return }
        applyDailyInterest(to: wallet)
    }

    func forceApplyInterest(to wallet: WalletViewModel) {
        applyDailyInterest(to: wallet)
    }

    func snapshot() -> BankSnapshot {
        BankSnapshot(annualInterestRate: annualInterestRate,
                     lastRateUpdate: lastRateUpdate,
                     lastInterestApplied: lastInterestApplied)
    }
}

