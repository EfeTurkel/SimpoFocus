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
                .onAppear {
                    // Request AlarmKit permissions/setup when available (iOS 18+) and present
                    #if canImport(AlarmKit)
                    if #available(iOS 18.0, *) {
                        AlarmService.shared.requestAuthorization()
                    }
                    #endif
                    processPendingAction()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }
    
    private func handleURL(_ url: URL) {
        print("App - Received URL: \(url)")
        if url.scheme == "forest" {
            switch url.host {
            case "start":
                print("App - Starting timer from URL")
                timerService.start()
            case "pause":
                print("App - Pausing timer from URL")
                timerService.pause()
            case "resume":
                print("App - Resuming timer from URL")
                timerService.resume()
            case "reset":
                print("App - Resetting timer from URL")
                timerService.reset()
            default:
                print("App - Unknown URL host: \(url.host ?? "nil")")
            }
        }
    }

    private func processPendingAction() {
        guard let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") else { 
            print("App - processPendingAction: Failed to access shared UserDefaults")
            return 
        }
        let action = shared.string(forKey: "pendingAction")
        guard let action else { 
            print("App - processPendingAction: No pending action found")
            return 
        }
        print("App - Processing pending action: \(action)")
        switch action {
        case "start":
            print("App - Executing start action")
            timerService.start()
        case "pause":
            print("App - Executing pause action")
            timerService.pause()
        case "resume":
            print("App - Executing resume action")
            timerService.resume()
        case "reset":
            print("App - Executing reset action")
            timerService.reset()
        default:
            print("App - Unknown pending action: \(action)")
            break
        }
        shared.removeObject(forKey: "pendingAction")
        shared.removeObject(forKey: "pendingActionAt")
        print("App - Cleared pending action")
    }

    private func setupPersistenceObservers() {
        persistence.setupWalletPersistence(wallet, cancellables: &cancellables)
        persistence.setupMarketPersistence(market, cancellables: &cancellables)
        persistence.setupBankPersistence(bank, cancellables: &cancellables)
        persistence.setupTimerPersistence(timerService, cancellables: &cancellables)
        persistence.setupRoomPersistence(room, cancellables: &cancellables)
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            // Save data when app goes to background
            persistence.saveWallet(wallet)
            persistence.saveMarket(market)
            persistence.saveBank(bank)
            persistence.saveTimer(timerService)
            persistence.saveRoom(room)
        case .active:
            // App became active - restore state if needed
            print("App - Became active, restoring state")
        @unknown default:
            break
        }
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

