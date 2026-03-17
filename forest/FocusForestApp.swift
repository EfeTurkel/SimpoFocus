import SwiftUI
import Combine
import UserNotifications
import StoreKit

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

    @State private var isShowingLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(LocalizationManager.shared)
                    .environmentObject(timerService)
                    .environmentObject(wallet)
                    .environmentObject(market)
                    .environmentObject(room)
                    .environmentObject(bank)
                    .environmentObject(StoreKitService.shared)
                    .environmentObject(EntitlementManager.shared)
                    .onAppear(perform: setupPersistenceObservers)
                    .onAppear {
                        #if canImport(AlarmKit)
                        if #available(iOS 18.0, *) {
                            AlarmService.shared.requestAuthorization()
                        }
                        #endif
                        processPendingAction()
                    }
                    .task {
                        StoreKitService.shared.onCoinsPurchased = { [weak wallet] coins in
                            wallet?.addPurchasedCoins(amount: coins)
                        }
                        StoreKitService.shared.startIfNeeded()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        handleScenePhaseChange(newPhase)
                    }
                    .onOpenURL { url in
                        handleURL(url)
                    }

                if isShowingLaunchScreen {
                    LuxuryLaunchScreen()
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                        .zIndex(2)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isShowingLaunchScreen = false
                }
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        #if DEBUG
        print("App - Received URL: \(url)")
        #endif
        if url.scheme == "forest" {
            switch url.host {
            case "start":
                #if DEBUG
                print("App - Starting timer from URL")
                #endif
                timerService.start()
            case "pause":
                #if DEBUG
                print("App - Pausing timer from URL")
                #endif
                timerService.pause()
            case "resume":
                #if DEBUG
                print("App - Resuming timer from URL")
                #endif
                timerService.resume()
            case "reset":
                #if DEBUG
                print("App - Resetting timer from URL")
                #endif
                timerService.reset()
            default:
                #if DEBUG
                print("App - Unknown URL host: \(url.host ?? "nil")")
                #endif
            }
        }
    }

    private func processPendingAction() {
        guard let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") else {
            timerService.syncFromWidget()
            return
        }

        let action = shared.string(forKey: "pendingAction")
        let actionAt = shared.double(forKey: "pendingActionAt")

        // Always pull latest snapshot first (phase/remaining/isRunning).
        timerService.syncFromWidget()

        // Avoid replaying stale intents (e.g. after reinstall / long time).
        let isFresh = actionAt > 0 && (Date().timeIntervalSince1970 - actionAt) < 60

        if let action, isFresh {
            #if DEBUG
            print("App - Processing pendingAction: \(action)")
            #endif

            DispatchQueue.main.async {
                switch action {
                case "start":
                    self.timerService.start()
                case "pause":
                    self.timerService.pause()
                case "resume":
                    self.timerService.resume()
                case "reset":
                    self.timerService.reset()
                default:
                    break
                }
            }
        }

        shared.removeObject(forKey: "pendingAction")
        shared.removeObject(forKey: "pendingActionAt")
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
            #if DEBUG
            print("App - Became active, restoring state")
            #endif
            processPendingAction()
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

