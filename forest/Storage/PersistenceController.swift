import Foundation
import Combine

final class PersistenceController {
    static let shared = PersistenceController()

    private let walletKey = "wallet_snapshot"
    private let marketKey = "market_snapshot"
    private let bankKey = "bank_snapshot"
    private let timerKey = "timer_snapshot"
    private let roomKey = "room_snapshot"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func saveWallet(_ wallet: WalletViewModel) {
        do {
            let data = try encoder.encode(wallet.snapshot())
            UserDefaults.standard.set(data, forKey: walletKey)
        } catch {
            print("Failed to save wallet: \(error)")
        }
    }

    func loadWallet() -> WalletViewModel.Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: walletKey) else { return nil }
        do {
            return try decoder.decode(WalletViewModel.Snapshot.self, from: data)
        } catch {
            print("Failed to decode wallet: \(error)")
            return nil
        }
    }

    func saveMarket(_ market: MarketViewModel) {
        do {
            let data = try encoder.encode(market.snapshot())
            UserDefaults.standard.set(data, forKey: marketKey)
        } catch {
            print("Failed to save market: \(error)")
        }
    }

    func loadMarket() -> MarketViewModel.Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: marketKey) else { return nil }
        do {
            return try decoder.decode(MarketViewModel.Snapshot.self, from: data)
        } catch {
            print("Failed to decode market: \(error)")
            return nil
        }
    }

    func saveBank(_ bank: BankService) {
        do {
            let data = try encoder.encode(bank.snapshot())
            UserDefaults.standard.set(data, forKey: bankKey)
        } catch {
            print("Failed to save bank: \(error)")
        }
    }

    func loadBank() -> BankSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: bankKey) else { return nil }
        do {
            return try decoder.decode(BankSnapshot.self, from: data)
        } catch {
            print("Failed to decode bank: \(error)")
            return nil
        }
    }

    func saveTimer(_ timer: PomodoroTimerService) {
        do {
            let data = try encoder.encode(timer.snapshot())
            UserDefaults.standard.set(data, forKey: timerKey)
        } catch {
            print("Failed to save timer: \(error)")
        }
    }

    func loadTimer() -> PomodoroTimerService.Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: timerKey) else { return nil }
        do {
            return try decoder.decode(PomodoroTimerService.Snapshot.self, from: data)
        } catch {
            print("Failed to decode timer: \(error)")
            return nil
        }
    }

    func saveRoom(_ room: RoomViewModel) {
        do {
            let data = try encoder.encode(room.snapshot())
            UserDefaults.standard.set(data, forKey: roomKey)
        } catch {
            print("Failed to save room: \(error)")
        }
    }

    func loadRoom() -> RoomSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: roomKey) else { return nil }
        do {
            return try decoder.decode(RoomSnapshot.self, from: data)
        } catch {
            print("Failed to decode room: \(error)")
            return nil
        }
    }

    func setupWalletPersistence(_ wallet: WalletViewModel, cancellables: inout Set<AnyCancellable>) {
        wallet.$balance
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$transactions
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$stakedBalance
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$stakingAccruedInterest
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)
    }

    func setupMarketPersistence(_ market: MarketViewModel, cancellables: inout Set<AnyCancellable>) {
        market.$coins
            .sink { [weak self] _ in self?.saveMarket(market) }
            .store(in: &cancellables)

        market.$dailyTarget
            .sink { [weak self] _ in self?.saveMarket(market) }
            .store(in: &cancellables)

        market.$lastRefreshDate
            .sink { [weak self] _ in self?.saveMarket(market) }
            .store(in: &cancellables)
    }

    func setupBankPersistence(_ bank: BankService, cancellables: inout Set<AnyCancellable>) {
        bank.$annualInterestRate
            .sink { [weak self] _ in self?.saveBank(bank) }
            .store(in: &cancellables)

        bank.$lastInterestApplied
            .sink { [weak self] _ in self?.saveBank(bank) }
            .store(in: &cancellables)

        bank.$lastRateUpdate
            .sink { [weak self] _ in self?.saveBank(bank) }
            .store(in: &cancellables)
    }

    func setupTimerPersistence(_ timer: PomodoroTimerService, cancellables: inout Set<AnyCancellable>) {
        timer.$focusDuration
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$shortBreakDuration
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$longBreakDuration
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$sessionsBeforeLongBreak
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$baseRewardPerSession
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$soundEnabled
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$hapticsEnabled
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$autoStartBreaks
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$tickingEnabled
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$selectedTickSound
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$overrideMute
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$tickVolume
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$notificationsEnabled
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$completedFocusSessions
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$streak
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$totalCompletedSessions
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$totalFocusMinutes
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$focusDays
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$sessionHistory
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)

        timer.$selectedCategory
            .sink { [weak self] _ in self?.saveTimer(timer) }
            .store(in: &cancellables)
    }

    func setupRoomPersistence(_ room: RoomViewModel, cancellables: inout Set<AnyCancellable>) {
        room.changePublisher
            .sink { [weak self] in self?.saveRoom(room) }
            .store(in: &cancellables)
    }
}

