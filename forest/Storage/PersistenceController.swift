import Foundation
import Combine

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    @Published var lastSaveError: String?
    @Published private(set) var didFinishInitialCloudSync: Bool = false
    @Published private(set) var lastCloudSyncAt: Date?

    private let walletKey = "wallet_snapshot"
    private let marketKey = "market_snapshot"
    private let bankKey = "bank_snapshot"
    private let timerKey = "timer_snapshot"
    private let roomKey = "room_snapshot"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let cloudUpdatedAtKey = "cloud_sync_last_updated_at"
    private let cloudDeviceIDKey = "cloud_sync_device_id"
    private var cloudPushWorkItem: DispatchWorkItem?
    private var isApplyingCloudState = false
    private var isHandlingDefaultsChange = false
    private var defaultsObserver: AnyCancellable?
    private let cloudQueue = DispatchQueue(label: "com.efeturkel.simpoapp.cloudsync")

    func saveWallet(_ wallet: WalletViewModel) {
        do {
            let data = try encoder.encode(wallet.snapshot())
            UserDefaults.standard.set(data, forKey: walletKey)
            markLocalDataUpdated()
        } catch {
            lastSaveError = error.localizedDescription
            #if DEBUG
            print("Failed to save wallet: \(error)")
            #endif
        }
    }

    func loadWallet() -> WalletViewModel.Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: walletKey) else { return nil }
        do {
            return try decoder.decode(WalletViewModel.Snapshot.self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode wallet: \(error)")
            #endif
            return nil
        }
    }

    func saveMarket(_ market: MarketViewModel) {
        do {
            let data = try encoder.encode(market.snapshot())
            UserDefaults.standard.set(data, forKey: marketKey)
            markLocalDataUpdated()
        } catch {
            lastSaveError = error.localizedDescription
            #if DEBUG
            print("Failed to save market: \(error)")
            #endif
        }
    }

    func loadMarket() -> MarketViewModel.Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: marketKey) else { return nil }
        do {
            return try decoder.decode(MarketViewModel.Snapshot.self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode market: \(error)")
            #endif
            return nil
        }
    }

    func saveBank(_ bank: BankService) {
        do {
            let data = try encoder.encode(bank.snapshot())
            UserDefaults.standard.set(data, forKey: bankKey)
            markLocalDataUpdated()
        } catch {
            lastSaveError = error.localizedDescription
            #if DEBUG
            print("Failed to save bank: \(error)")
            #endif
        }
    }

    func loadBank() -> BankSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: bankKey) else { return nil }
        do {
            return try decoder.decode(BankSnapshot.self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode bank: \(error)")
            #endif
            return nil
        }
    }

    func saveTimer(_ timer: PomodoroTimerService) {
        do {
            let data = try encoder.encode(timer.snapshot())
            UserDefaults.standard.set(data, forKey: timerKey)
            markLocalDataUpdated()
        } catch {
            lastSaveError = error.localizedDescription
            #if DEBUG
            print("Failed to save timer: \(error)")
            #endif
        }
    }

    func loadTimer() -> PomodoroTimerService.Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: timerKey) else { return nil }
        do {
            return try decoder.decode(PomodoroTimerService.Snapshot.self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode timer: \(error)")
            #endif
            return nil
        }
    }

    func saveRoom(_ room: RoomViewModel) {
        do {
            let data = try encoder.encode(room.snapshot())
            UserDefaults.standard.set(data, forKey: roomKey)
            markLocalDataUpdated()
        } catch {
            lastSaveError = error.localizedDescription
            #if DEBUG
            print("Failed to save room: \(error)")
            #endif
        }
    }

    func loadRoom() -> RoomSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: roomKey) else { return nil }
        do {
            return try decoder.decode(RoomSnapshot.self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode room: \(error)")
            #endif
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

        wallet.$earningMultiplier
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$earningMultiplierExpiresAt
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$bankBoostMultiplier
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$bankBoostExpiresAt
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$marketRefreshCredits
            .sink { [weak self] _ in self?.saveWallet(wallet) }
            .store(in: &cancellables)

        wallet.$marketRefreshCreditsExpiresAt
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

    func setupCloudSyncObservers() {
        defaultsObserver?.cancel()
        defaultsObserver = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.scheduleCloudPushIfPossible()
            }
    }

    @MainActor
    func syncFromCloudIfNeeded(wallet: WalletViewModel,
                               market: MarketViewModel,
                               bank: BankService,
                               timer: PomodoroTimerService,
                               room: RoomViewModel) async {
        defer {
            didFinishInitialCloudSync = true
        }
        do {
            guard let remote = try await CloudKitSyncService.shared.pullLatest() else { return }
            let localStored = makeStoredSnapshot(updatedAt: lastCloudUpdatedAt())
            let shouldApplyRemote: Bool
            if let localStored {
                shouldApplyRemote = isSnapshot(remote, betterThan: localStored)
                    || remote.updatedAt > lastCloudUpdatedAt()
            } else {
                shouldApplyRemote = true
            }
            guard shouldApplyRemote else { return }

            isApplyingCloudState = true
            wallet.apply(remote.wallet)
            market.apply(remote.market)
            bank.apply(remote.bank)
            timer.apply(remote.timer)
            room.apply(remote.room)
            apply(remote.appSettings)
            setCloudUpdatedAt(remote.updatedAt)
            isApplyingCloudState = false

            saveWallet(wallet)
            saveMarket(market)
            saveBank(bank)
            saveTimer(timer)
            saveRoom(room)
        } catch {
            #if DEBUG
            print("Cloud pull failed: \(error)")
            #endif
        }
    }

    func pushCurrentStateToCloud(wallet: WalletViewModel,
                                 market: MarketViewModel,
                                 bank: BankService,
                                 timer: PomodoroTimerService,
                                 room: RoomViewModel) {
        guard !isApplyingCloudState else { return }
        cloudPushWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let updatedAt = Date()
            self.setCloudUpdatedAt(updatedAt)
            let snapshot = UserStateSnapshot(
                wallet: wallet.snapshot(),
                market: market.snapshot(),
                bank: bank.snapshot(),
                timer: timer.snapshot(),
                room: room.snapshot(),
                appSettings: self.currentAppSettings(),
                updatedAt: updatedAt,
                deviceId: self.cloudDeviceID()
            )

            Task {
                do {
                    if let remote = try await CloudKitSyncService.shared.pullLatest(),
                       self.isSnapshot(remote, betterThan: snapshot) {
                        await self.syncFromCloudIfNeeded(wallet: wallet, market: market, bank: bank, timer: timer, room: room)
                        return
                    }
                    try await CloudKitSyncService.shared.push(snapshot: snapshot)
                } catch {
                    #if DEBUG
                    print("Cloud push failed: \(error)")
                    #endif
                }
            }
        }
        cloudPushWorkItem = workItem
        cloudQueue.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }

    private func scheduleCloudPushIfPossible() {
        guard !isApplyingCloudState else { return }
        guard !isHandlingDefaultsChange else { return }
        isHandlingDefaultsChange = true
        defer { isHandlingDefaultsChange = false }
        // We only push when app state has already been persisted by save* methods.
        // This observer is mainly for @AppStorage and UserDefaults-only settings.
        markLocalDataUpdated()
    }

    private func markLocalDataUpdated() {
        guard !isApplyingCloudState else { return }
        let updatedAt = Date()
        setCloudUpdatedAt(updatedAt)
        queueCloudPushFromStoredState(updatedAt: updatedAt)
    }

    private func setCloudUpdatedAt(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: cloudUpdatedAtKey)
        DispatchQueue.main.async {
            self.lastCloudSyncAt = date
        }
    }

    private func lastCloudUpdatedAt() -> Date {
        let ts = UserDefaults.standard.double(forKey: cloudUpdatedAtKey)
        guard ts > 0 else { return .distantPast }
        return Date(timeIntervalSince1970: ts)
    }

    func refreshLastCloudSyncAtFromDefaults() {
        let date = lastCloudUpdatedAt()
        DispatchQueue.main.async {
            self.lastCloudSyncAt = (date == .distantPast) ? nil : date
        }
    }

    private func cloudDeviceID() -> String {
        if let existing = UserDefaults.standard.string(forKey: cloudDeviceIDKey), !existing.isEmpty {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: cloudDeviceIDKey)
        return newID
    }

    private func currentAppSettings() -> SyncedAppSettings {
        let defaults = UserDefaults.standard
        return SyncedAppSettings(
            onboardingCompleted: defaults.bool(forKey: "onboardingCompleted"),
            userName: defaults.string(forKey: "userName") ?? "",
            paywallLaunchCount: defaults.integer(forKey: "paywallLaunchCount"),
            paywallLastShownDate: defaults.string(forKey: "paywallLastShownDate") ?? "",
            specialOfferLastMilestoneShown: defaults.integer(forKey: "specialOfferLastMilestoneShown"),
            specialOfferMilestoneShowCount: defaults.integer(forKey: "specialOfferMilestoneShowCount"),
            lifetimeOfferShown: defaults.bool(forKey: "lifetimeOfferShown"),
            proWelcomeBonusGranted: defaults.bool(forKey: "proWelcomeBonusGranted"),
            proMonthlyBonusLastYearMonth: defaults.string(forKey: "proMonthlyBonusLastYearMonth") ?? "",
            sessionsSinceLastProNudge: defaults.integer(forKey: "sessionsSinceLastProNudge"),
            selectedTab: defaults.string(forKey: "selectedTab") ?? "forest",
            appLanguage: defaults.string(forKey: "app_language") ?? "en",
            appTheme: defaults.string(forKey: "app_theme") ?? "system",
            entitlementIsPro: defaults.bool(forKey: "entitlement_isPro"),
            customCategoriesData: defaults.data(forKey: "custom_categories")
        )
    }

    private func queueCloudPushFromStoredState(updatedAt: Date) {
        cloudPushWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard let snapshot = self.makeStoredSnapshot(updatedAt: updatedAt) else { return }
            Task {
                do {
                    try await CloudKitSyncService.shared.push(snapshot: snapshot)
                } catch {
                    #if DEBUG
                    print("Cloud push failed: \(error)")
                    #endif
                }
            }
        }
        cloudPushWorkItem = workItem
        cloudQueue.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }

    private func makeStoredSnapshot(updatedAt: Date) -> UserStateSnapshot? {
        guard let wallet = loadWallet(),
              let market = loadMarket(),
              let bank = loadBank(),
              let timer = loadTimer(),
              let room = loadRoom() else {
            return nil
        }
        return UserStateSnapshot(
            wallet: wallet,
            market: market,
            bank: bank,
            timer: timer,
            room: room,
            appSettings: currentAppSettings(),
            updatedAt: updatedAt,
            deviceId: cloudDeviceID()
        )
    }

    private func apply(_ settings: SyncedAppSettings) {
        let defaults = UserDefaults.standard
        defaults.set(settings.onboardingCompleted, forKey: "onboardingCompleted")
        defaults.set(settings.userName, forKey: "userName")
        defaults.set(settings.paywallLaunchCount, forKey: "paywallLaunchCount")
        defaults.set(settings.paywallLastShownDate, forKey: "paywallLastShownDate")
        defaults.set(settings.specialOfferLastMilestoneShown, forKey: "specialOfferLastMilestoneShown")
        defaults.set(settings.specialOfferMilestoneShowCount, forKey: "specialOfferMilestoneShowCount")
        defaults.set(settings.lifetimeOfferShown, forKey: "lifetimeOfferShown")
        defaults.set(settings.proWelcomeBonusGranted, forKey: "proWelcomeBonusGranted")
        defaults.set(settings.proMonthlyBonusLastYearMonth, forKey: "proMonthlyBonusLastYearMonth")
        defaults.set(settings.sessionsSinceLastProNudge, forKey: "sessionsSinceLastProNudge")
        defaults.set(settings.selectedTab, forKey: "selectedTab")
        defaults.set(settings.appLanguage, forKey: "app_language")
        defaults.set(settings.appTheme, forKey: "app_theme")
        defaults.set(settings.entitlementIsPro, forKey: "entitlement_isPro")
        if let customCategories = settings.customCategoriesData {
            defaults.set(customCategories, forKey: "custom_categories")
        }
        if let language = AppLanguage(rawValue: settings.appLanguage) {
            LocalizationManager.shared.language = language
        }
        if let theme = AppTheme(rawValue: settings.appTheme) {
            ThemeManager.shared.setTheme(theme, animated: false)
        }
    }

    private func isSnapshot(_ a: UserStateSnapshot, betterThan b: UserStateSnapshot) -> Bool {
        let ar = progressRank(for: a)
        let br = progressRank(for: b)
        if ar.tokens != br.tokens { return ar.tokens > br.tokens }
        if ar.totalSessions != br.totalSessions { return ar.totalSessions > br.totalSessions }
        if ar.sessionCount != br.sessionCount { return ar.sessionCount > br.sessionCount }
        return a.updatedAt > b.updatedAt
    }

    private func progressRank(for snapshot: UserStateSnapshot) -> (tokens: Double, totalSessions: Int, sessionCount: Int) {
        let tokens = snapshot.wallet.balance
        let totalSessions = snapshot.timer.totalSessions
        let sessionCount = snapshot.timer.sessionHistory.count
        return (tokens, totalSessions, sessionCount)
    }
}

