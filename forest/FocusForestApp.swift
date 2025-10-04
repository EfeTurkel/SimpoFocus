import SwiftUI
import Combine
import UserNotifications

@main
struct FocusForestApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var timerService: PomodoroTimerService
    @StateObject private var wallet: WalletViewModel
    @StateObject private var market: MarketViewModel
    @StateObject private var room: RoomViewModel
    @StateObject private var bank: BankService

    @State private var cancellables = Set<AnyCancellable>()
    private let persistence = PersistenceController.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        let walletVM = WalletViewModel(snapshot: persistence.loadWallet())
        let marketVM = MarketViewModel(snapshot: persistence.loadMarket())
        let bankService = BankService(snapshot: persistence.loadBank())
        let timerSnapshot = persistence.loadTimer()
        let timerService = PomodoroTimerService(snapshot: timerSnapshot)
        let roomService = RoomViewModel(snapshot: persistence.loadRoom())

        _wallet = StateObject(wrappedValue: walletVM)
        _market = StateObject(wrappedValue: marketVM)
        _bank = StateObject(wrappedValue: bankService)
        _timerService = StateObject(wrappedValue: timerService)
        _room = StateObject(wrappedValue: roomService)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                    .environmentObject(LocalizationManager.shared)
                .environmentObject(timerService)
                .environmentObject(wallet)
                .environmentObject(market)
                .environmentObject(room)
                .environmentObject(bank)
                .onAppear(perform: setupPersistenceObservers)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }

    private func setupPersistenceObservers() {
        persistence.setupWalletPersistence(wallet, cancellables: &cancellables)
        persistence.setupMarketPersistence(market, cancellables: &cancellables)
        persistence.setupBankPersistence(bank, cancellables: &cancellables)
        persistence.setupTimerPersistence(timerService, cancellables: &cancellables)
        persistence.setupRoomPersistence(room, cancellables: &cancellables)
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard phase == .background || phase == .inactive else { return }
        persistence.saveWallet(wallet)
        persistence.saveMarket(market)
        persistence.saveBank(bank)
        persistence.saveTimer(timerService)
        persistence.saveRoom(room)
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

