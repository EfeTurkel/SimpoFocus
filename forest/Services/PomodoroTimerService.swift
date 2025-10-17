import Foundation
import Combine
import UIKit
import AudioToolbox
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Notification Names for Live Activity
extension Notification.Name {
    static let startTimer = Notification.Name("startTimer")
    static let pauseTimer = Notification.Name("pauseTimer")
    static let resumeTimer = Notification.Name("resumeTimer")
    static let resetTimer = Notification.Name("resetTimer")
}

enum PomodoroPhase: String {
    case idle
    case focus
    case shortBreak
    case longBreak

    func displayName(using localization: LocalizationManager = LocalizationManager.shared) -> String {
        let key: String
        switch self {
        case .idle: key = "TIMER_PHASE_IDLE"
        case .focus: key = "TIMER_PHASE_FOCUS"
        case .shortBreak: key = "TIMER_PHASE_SHORT"
        case .longBreak: key = "TIMER_PHASE_LONG"
        }
        return localization.translate(key)
    }

    var isFocus: Bool {
        self == .focus
    }

    private var fallbackTitle: String {
        switch self {
        case .idle: return "Hazır"
        case .focus: return "Odak"
        case .shortBreak: return "Kısa Mola"
        case .longBreak: return "Uzun Mola"
        }
    }
}

struct FocusReward {
    let coinsReward: Double
    let passiveBoost: Double
}

final class PomodoroTimerService: ObservableObject {
    // MARK: - Published State
    @Published private(set) var phase: PomodoroPhase = .idle
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var completedFocusSessions: Int = 0
    @Published private(set) var lastGoalReset: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var streak: Int = 0
    @Published private(set) var lastFocusStart: Date?
    @Published private(set) var totalCompletedSessions: Int = 0
    @Published private(set) var totalFocusMinutes: Double = 0
    @Published private(set) var focusDays: Set<Date> = []
    @Published private(set) var backgroundRefreshAvailable: Bool = true
    @Published var shouldPromptBackgroundRefresh: Bool = false
    @Published private(set) var sessionHistory: [FocusSession] = []
    @Published var selectedCategory: FocusCategory = .predefined(.untagged)

    // MARK: - Configuration
    @Published var focusDuration: Int = 25 * 60
    @Published var shortBreakDuration: Int = 5 * 60
    @Published var longBreakDuration: Int = 15 * 60
    @Published var sessionsBeforeLongBreak: Int = 4
    @Published var baseRewardPerSession: Double = 25
    @Published var soundEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    @Published var autoStartBreaks: Bool = false
    @Published var tickingEnabled: Bool = true
    @Published var selectedTickSound: TickSound = .classic
    @Published var tickVolume: Double = 0.55 {
        didSet {
#if canImport(AVFoundation)
            tickPlayers.values.forEach { $0.volume = Float(tickVolume) }
#endif
        }
    }
#if canImport(AVFoundation)
    @Published var overrideMute: Bool = false {
        didSet {
            if overrideMute {
                configureAudioSession()
            } else {
                if isRunning {
                    configureAudioSession()
                } else {
                    deactivateAudioSession()
                }
            }
        }
    }
#else
    @Published var overrideMute: Bool = false
#endif
    @Published var notificationsEnabled: Bool = false {
        didSet {
            if notificationsEnabled {
                requestNotificationPermissions()
            } else {
#if canImport(UIKit)
                cancelScheduledNotifications()
                shouldPromptBackgroundRefresh = false
#endif
            }
#if canImport(UIKit)
            promptForBackgroundRefreshIfNeeded()
#endif
        }
    }

    // MARK: - Publishers
    let rewardPublisher = PassthroughSubject<FocusReward, Never>()

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var startedAt: Date?
    private let calendar = Calendar.current
    private var currentLanguage: AppLanguage = LocalizationManager.shared.language
#if canImport(AVFoundation)
    private var tickPlayers: [TickSound: AVAudioPlayer] = [:]
#endif
#if canImport(UIKit)
    private var backgroundEnteredAt: Date?
    private var scheduledNotificationIDs: Set<String> = []
    private var pendingNotificationPhase: PomodoroPhase?
    private var pendingNotificationFireDate: Date?
#endif

    struct Snapshot: Codable {
        let focusDuration: Int
        let shortBreakDuration: Int
        let longBreakDuration: Int
        let sessionsBeforeLongBreak: Int
        let baseRewardPerSession: Double
        let soundEnabled: Bool
        let hapticsEnabled: Bool
        let autoStartBreaks: Bool
        let tickingEnabled: Bool
        let selectedTickSound: TickSound.RawValue
        let overrideMute: Bool
        let tickVolume: Double
        let notificationsEnabled: Bool
        let completedFocusSessions: Int
        let streak: Int
        let totalSessions: Int
        let totalFocusMinutes: Double
        let focusDays: [Date]
        let lastGoalReset: Date?
        let sessionHistory: [FocusSession]
        let selectedCategory: FocusCategory

        init(focusDuration: Int,
             shortBreakDuration: Int,
             longBreakDuration: Int,
             sessionsBeforeLongBreak: Int,
             baseRewardPerSession: Double,
             soundEnabled: Bool,
             hapticsEnabled: Bool,
             autoStartBreaks: Bool,
             tickingEnabled: Bool = true,
             selectedTickSound: TickSound.RawValue = TickSound.classic.rawValue,
             overrideMute: Bool = false,
             tickVolume: Double = 0.55,
             notificationsEnabled: Bool = false,
             completedFocusSessions: Int,
             streak: Int,
             totalSessions: Int,
             totalFocusMinutes: Double,
             focusDays: [Date],
             lastGoalReset: Date? = nil,
             sessionHistory: [FocusSession] = [],
             selectedCategory: FocusCategory = .predefined(.untagged)) {
            self.focusDuration = focusDuration
            self.shortBreakDuration = shortBreakDuration
            self.longBreakDuration = longBreakDuration
            self.sessionsBeforeLongBreak = sessionsBeforeLongBreak
            self.baseRewardPerSession = baseRewardPerSession
            self.soundEnabled = soundEnabled
            self.hapticsEnabled = hapticsEnabled
            self.autoStartBreaks = autoStartBreaks
            self.tickingEnabled = tickingEnabled
            self.selectedTickSound = selectedTickSound
            self.overrideMute = overrideMute
            self.tickVolume = tickVolume
            self.notificationsEnabled = notificationsEnabled
            self.completedFocusSessions = completedFocusSessions
            self.streak = streak
            self.totalSessions = totalSessions
            self.totalFocusMinutes = totalFocusMinutes
            self.focusDays = focusDays
            self.lastGoalReset = lastGoalReset
            self.sessionHistory = sessionHistory
            self.selectedCategory = selectedCategory
        }
    }

    init(snapshot: Snapshot? = nil) {
        if let snapshot {
            focusDuration = sanitizeDuration(snapshot.focusDuration, minimumMinutes: 1)
            shortBreakDuration = sanitizeDuration(snapshot.shortBreakDuration, minimumMinutes: 1)
            longBreakDuration = sanitizeDuration(snapshot.longBreakDuration, minimumMinutes: 1)
            sessionsBeforeLongBreak = snapshot.sessionsBeforeLongBreak
            baseRewardPerSession = snapshot.baseRewardPerSession
            soundEnabled = snapshot.soundEnabled
            hapticsEnabled = snapshot.hapticsEnabled
            autoStartBreaks = snapshot.autoStartBreaks
            tickingEnabled = snapshot.tickingEnabled
            selectedTickSound = TickSound(rawValue: snapshot.selectedTickSound) ?? .classic
            overrideMute = snapshot.overrideMute
            tickVolume = snapshot.tickVolume
            notificationsEnabled = snapshot.notificationsEnabled
            completedFocusSessions = snapshot.completedFocusSessions
            streak = snapshot.streak
            totalCompletedSessions = snapshot.totalSessions
            totalFocusMinutes = snapshot.totalFocusMinutes
            focusDays = Set(snapshot.focusDays)
            lastGoalReset = snapshot.lastGoalReset ?? calendar.startOfDay(for: Date())
            sessionHistory = snapshot.sessionHistory
            selectedCategory = snapshot.selectedCategory
            remainingSeconds = focusDuration
        } else {
            lastGoalReset = calendar.startOfDay(for: Date())
            remainingSeconds = focusDuration
        }

        resetDailyProgressIfNeeded()

#if canImport(UIKit)
        LocalizationManager.shared.$language
            .sink { [weak self] _ in
                self?.handleLanguageChange()
            }
            .store(in: &cancellables)

        updateBackgroundRefreshStatus()
        promptForBackgroundRefreshIfNeeded()

        setupLifecycleObservers()
        setupNotificationObservers()
        
        // Initialize shared data for widget
        print("App init - Initial phase: \(phase), remainingSeconds: \(remainingSeconds), isRunning: \(isRunning)")
        updateSharedData()
        
        // Test reading back the data
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        let testPhase = sharedDefaults?.string(forKey: "currentPhase")
        let testRemaining = sharedDefaults?.integer(forKey: "remainingSeconds")
        let testRunning = sharedDefaults?.bool(forKey: "isRunning")
        print("App init - Test read back - Phase: \(testPhase ?? "nil"), Remaining: \(testRemaining ?? -1), Running: \(testRunning ?? false)")
        
        // Force widget reload
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        print("App init - Forced widget reload")
        #endif
        #endif
    }

    // MARK: - Intent
    func start() {
        guard phase == .idle else {
            resume()
            return
        }
        startFocusSession()
    }

    func pause() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false
        
        // Update shared data for widget
        updateSharedData()
        
#if canImport(UIKit)
        cancelScheduledNotifications()
#endif
        if #available(iOS 16.1, *) {
            let currentLanguage = LocalizationManager.shared.language.rawValue
            let phaseName: String
            switch phase {
            case .idle: 
                phaseName = currentLanguage == "tr" ? "Hazır" : 
                           currentLanguage == "de" ? "Bereit" : "Ready"
            case .focus: 
                phaseName = currentLanguage == "tr" ? "Odak" : 
                           currentLanguage == "de" ? "Fokus" : "Focus"
            case .shortBreak: 
                phaseName = currentLanguage == "tr" ? "Kısa Mola" : 
                           currentLanguage == "de" ? "Kurze Pause" : "Short Break"
            case .longBreak: 
                phaseName = currentLanguage == "tr" ? "Uzun Mola" : 
                           currentLanguage == "de" ? "Lange Pause" : "Long Break"
            }
            
            LiveActivityService.shared.pause(phase: phaseName, remainingSeconds: remainingSeconds)
        }
    }

    func resume() {
        guard !isRunning, remainingSeconds > 0 else { return }
        remainingSeconds = min(remainingSeconds, duration(for: phase))
        beginTicking()
        
        // Update shared data for widget
        updateSharedData()
        
        // Resume Live Activity
        if #available(iOS 16.1, *) {
            let currentLanguage = LocalizationManager.shared.language.rawValue
            let phaseName: String
            switch phase {
            case .idle: 
                phaseName = currentLanguage == "tr" ? "Hazır" : 
                           currentLanguage == "de" ? "Bereit" : "Ready"
            case .focus: 
                phaseName = currentLanguage == "tr" ? "Odak" : 
                           currentLanguage == "de" ? "Fokus" : "Focus"
            case .shortBreak: 
                phaseName = currentLanguage == "tr" ? "Kısa Mola" : 
                           currentLanguage == "de" ? "Kurze Pause" : "Short Break"
            case .longBreak: 
                phaseName = currentLanguage == "tr" ? "Uzun Mola" : 
                           currentLanguage == "de" ? "Lange Pause" : "Long Break"
            }
            
            LiveActivityService.shared.startOrUpdate(
                phase: phaseName,
                endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
                isPaused: false,
                remainingSeconds: remainingSeconds
            )
        }
    }

    func skipPhase() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false

        switch phase {
        case .focus:
            streak = 0
            remainingSeconds = 0
            lastFocusStart = nil
            startBreak(long: false)
        case .shortBreak, .longBreak:
        remainingSeconds = 0
            startFocusSession()
        case .idle:
            break
        }
    }

    func reset() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false
        lastFocusStart = nil
        remainingSeconds = duration(for: phase)
#if canImport(UIKit)
        cancelScheduledNotifications()
#endif
        if #available(iOS 16.1, *) {
            LiveActivityService.shared.end()
        }
    }

    func adjustDurations(focus: Int? = nil, shortBreak: Int? = nil, longBreak: Int? = nil) {
        if let focus { focusDuration = sanitizeDuration(focus, minimumMinutes: 1) }
        if let shortBreak { shortBreakDuration = sanitizeDuration(shortBreak, minimumMinutes: 1) }
        if let longBreak { longBreakDuration = sanitizeDuration(longBreak, minimumMinutes: 1) }

        if !isRunning {
            remainingSeconds = duration(for: phase)
        }
    }

    private func resetDailyProgressIfNeeded(referenceDate: Date = Date()) {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        guard startOfDay != lastGoalReset else { return }

        if startOfDay > lastGoalReset {
            completedFocusSessions = 0
        }

        lastGoalReset = startOfDay
    }

    // MARK: - Private Helpers
    private func startFocusSession() {
        phase = .focus
        remainingSeconds = duration(for: .focus)
        lastFocusStart = Date()
        beginTicking()
#if canImport(AVFoundation)
        configureAudioSession()
        prepareTickPlayer(for: selectedTickSound)
#endif
        // Update shared data for widget
        updateSharedData()
        
        // Live Activity
        if #available(iOS 16.1, *) {
            let currentLanguage = LocalizationManager.shared.language.rawValue
            let phaseName = currentLanguage == "tr" ? "Odak" : 
                           currentLanguage == "de" ? "Fokus" : "Focus"
            LiveActivityService.shared.startOrUpdate(
                phase: phaseName,
                endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
                isPaused: false,
                remainingSeconds: remainingSeconds
            )
        }
        // AlarmKit countdown sync
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            let end = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            let label = LocalizationManager.shared.translate("TIMER_PHASE_FOCUS")
            AlarmService.shared.startOrUpdateCountdown(start: Date(), end: end, label: label)
        }
        #endif
    }

    private func startBreak(long: Bool) {
        phase = long ? .longBreak : .shortBreak
        remainingSeconds = duration(for: phase)
        beginTicking()
        
        // Update shared data for widget
        updateSharedData()
        
        if #available(iOS 16.1, *) {
            let end = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            let label = long ? LocalizationManager.shared.translate("TIMER_PHASE_LONG") : LocalizationManager.shared.translate("TIMER_PHASE_SHORT")
            LiveActivityService.shared.startOrUpdate(
                phase: label,
                endDate: end,
                isPaused: false,
                remainingSeconds: remainingSeconds
            )
        }
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            let end = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            let label = long ? LocalizationManager.shared.translate("TIMER_PHASE_LONG") : LocalizationManager.shared.translate("TIMER_PHASE_SHORT")
            AlarmService.shared.startOrUpdateCountdown(start: Date(), end: end, label: label)
        }
        #endif
    }

    private func beginTicking() {
        startedAt = Date()
        isRunning = true
        timerCancellable?.cancel()

#if canImport(AVFoundation)
        configureAudioSession()
        prepareTickPlayer(for: selectedTickSound)
#endif

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning else { return }
        guard remainingSeconds > 0 else {
            finishPhase()
            return
        }
        remainingSeconds -= 1
        
        // Update shared data for widget
        updateSharedData()
        
        // Update Live Activity with current remaining time
        if #available(iOS 16.1, *) {
            let currentLanguage = LocalizationManager.shared.language.rawValue
            let phaseName: String
            switch phase {
            case .idle: 
                phaseName = currentLanguage == "tr" ? "Hazır" : 
                           currentLanguage == "de" ? "Bereit" : "Ready"
            case .focus: 
                phaseName = currentLanguage == "tr" ? "Odak" : 
                           currentLanguage == "de" ? "Fokus" : "Focus"
            case .shortBreak: 
                phaseName = currentLanguage == "tr" ? "Kısa Mola" : 
                           currentLanguage == "de" ? "Kurze Pause" : "Short Break"
            case .longBreak: 
                phaseName = currentLanguage == "tr" ? "Uzun Mola" : 
                           currentLanguage == "de" ? "Lange Pause" : "Long Break"
            }
            
            LiveActivityService.shared.startOrUpdate(
                phase: phaseName,
                endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
                isPaused: false,
                remainingSeconds: remainingSeconds
            )
        }
#if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            // Optional: could update alarm label or progress if AlarmKit supports live updates.
        }
#endif
#if canImport(AVFoundation)
        if tickingEnabled, isRunning {
            playTickSound(for: selectedTickSound)
        }
#endif
    }

    private func finishPhase() {
        resetDailyProgressIfNeeded()
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false

#if canImport(AVFoundation)
        deactivateAudioSession()
#endif

        switch phase {
        case .focus:
            completedFocusSessions += 1
            totalCompletedSessions += 1
            if let start = lastFocusStart {
                // Use actual focus duration, not elapsed time
                // This prevents incorrect time when app is opened hours later
                let actualDuration = Double(focusDuration) / 60.0 // Convert to minutes
                
                // Note: totalFocusMinutes is kept for backward compatibility but not updated anymore
                // All new data goes into sessionHistory
                let day = calendar.startOfDay(for: start)
                // Update focusDays in a way that properly triggers @Published
                var updatedFocusDays = focusDays
                updatedFocusDays.insert(day)
                focusDays = updatedFocusDays
                
                // Create and save session history with actual duration
                let coinsEarned = rewardAmountForCurrentStreak()
                let session = FocusSession(
                    date: start,
                    durationMinutes: actualDuration,
                    category: selectedCategory,
                    coinsEarned: coinsEarned
                )
                // Update sessionHistory in a way that properly triggers @Published
                var updatedHistory = sessionHistory
                updatedHistory.append(session)
                sessionHistory = updatedHistory
            }
            streak += 1
            let reward = FocusReward(
                coinsReward: rewardAmountForCurrentStreak(),
                passiveBoost: passiveBoostForStreak()
            )
            rewardPublisher.send(reward)
            playCompletionCue()
            schedulePhaseNotification(for: .focus)
            scheduleAlarmIfAvailable(for: .focus)
        if #available(iOS 16.1, *) {
            let label = phase.displayName(using: LocalizationManager.shared)
            LiveActivityService.shared.pause(phase: label, remainingSeconds: remainingSeconds)
        }

            let shouldLongBreak = completedFocusSessions % sessionsBeforeLongBreak == 0
            if autoStartBreaks {
            startBreak(long: shouldLongBreak)
            } else {
                phase = shouldLongBreak ? .longBreak : .shortBreak
                remainingSeconds = duration(for: phase)
                isRunning = false
                lastFocusStart = nil
            }
        case .shortBreak, .longBreak:
            playPhaseTransitionCue()
            schedulePhaseNotification(for: phase)
            scheduleAlarmIfAvailable(for: phase)
            if #available(iOS 16.1, *) {
                LiveActivityService.shared.end()
            }
            if autoStartBreaks {
            startFocusSession()
            } else {
                phase = .focus
                remainingSeconds = duration(for: .focus)
                isRunning = false
                lastFocusStart = nil
            }
        case .idle:
            break
        }
    }

    private func finishIdle() {
        lastFocusStart = nil
#if canImport(AVFoundation)
        deactivateAudioSession()
#endif
    }

#if canImport(UIKit)
    private func setupLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.handleWillResignActive() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.handleDidBecomeActive() }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .startTimer)
            .sink { [weak self] _ in
                print("App - Received startTimer notification")
                DispatchQueue.main.async {
                    print("App - Calling start() method")
                    self?.start()
                }
            }
            .store(in: &cancellables)
        
        // Also listen for direct notification
        NotificationCenter.default.addObserver(
            forName: .startTimer,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("App - Direct notification received for startTimer")
            self?.start()
        }
        
        // Listen for app becoming active to sync with widget
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("App - Became active, syncing with widget")
            self?.updateSharedData()
        }
        
        // Listen for language changes to update widget
        LocalizationManager.shared.$language
            .sink { [weak self] _ in
                print("App - Language changed, updating widget")
                DispatchQueue.main.async {
                    self?.updateSharedData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .pauseTimer)
            .sink { [weak self] _ in
                print("App - Received pauseTimer notification")
                DispatchQueue.main.async {
                    print("App - Calling pause() method")
                    self?.pause()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .resumeTimer)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.resume()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .resetTimer)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.reset()
                }
            }
            .store(in: &cancellables)
    }

    private func handleWillResignActive() {
        guard isRunning else { return }
        backgroundEnteredAt = Date()
        timerCancellable?.cancel()
        timerCancellable = nil

        if notificationsEnabled && remainingSeconds > 0 {
            let interval = TimeInterval(max(remainingSeconds, 1))
            schedulePhaseNotification(for: phase, customInterval: interval)
        }
    }

    private func handleDidBecomeActive() {
        cancelScheduledNotifications()
        guard let entered = backgroundEnteredAt else { return }
        backgroundEnteredAt = nil

        promptForBackgroundRefreshIfNeeded()

        if isRunning {
            let elapsed = Int(Date().timeIntervalSince(entered))
            if elapsed > 0 {
                remainingSeconds = max(remainingSeconds - elapsed, 0)
            }
        }

        if remainingSeconds > 0 {
            if isRunning {
                beginTicking()
            }
        } else {
            finishPhase()
        }
    }
#endif

    private func duration(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus:
            return sanitizeDuration(focusDuration, minimumMinutes: 1)
        case .shortBreak:
            return sanitizeDuration(shortBreakDuration, minimumMinutes: 1)
        case .longBreak:
            return sanitizeDuration(longBreakDuration, minimumMinutes: 1)
        case .idle:
            return sanitizeDuration(focusDuration, minimumMinutes: 1)
        }
    }

    private func sanitizeDuration(_ seconds: Int, minimumMinutes: Int = 1) -> Int {
        let minutes = max(seconds / 60, minimumMinutes)
        return minutes * 60
    }
    
    private func updateSharedData() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        
        // Get current language from LocalizationManager
        let currentLanguage = LocalizationManager.shared.language.rawValue
        
        // Use localized phase names for widget compatibility
        let phaseName: String
        switch phase {
        case .idle: 
            phaseName = currentLanguage == "tr" ? "Hazır" : 
                       currentLanguage == "de" ? "Bereit" : "Ready"
        case .focus: 
            phaseName = currentLanguage == "tr" ? "Odak" : 
                       currentLanguage == "de" ? "Fokus" : "Focus"
        case .shortBreak: 
            phaseName = currentLanguage == "tr" ? "Kısa Mola" : 
                       currentLanguage == "de" ? "Kurze Pause" : "Short Break"
        case .longBreak: 
            phaseName = currentLanguage == "tr" ? "Uzun Mola" : 
                       currentLanguage == "de" ? "Lange Pause" : "Long Break"
        }
        
        print("App updateSharedData - Language: \(currentLanguage), Phase: \(phaseName), Remaining: \(remainingSeconds), Running: \(isRunning)")
        
        sharedDefaults?.set(phaseName, forKey: "currentPhase")
        sharedDefaults?.set(remainingSeconds, forKey: "remainingSeconds")
        sharedDefaults?.set(isRunning, forKey: "isRunning")
        sharedDefaults?.set(currentLanguage, forKey: "app_language")
        
        // Force synchronization
        sharedDefaults?.synchronize()
        
        // Verify the data was written
        let savedPhase = sharedDefaults?.string(forKey: "currentPhase")
        let savedRemaining = sharedDefaults?.integer(forKey: "remainingSeconds")
        let savedRunning = sharedDefaults?.bool(forKey: "isRunning")
        let savedLanguage = sharedDefaults?.string(forKey: "app_language")
        print("App verify - Saved Phase: \(savedPhase ?? "nil"), Remaining: \(savedRemaining ?? -1), Running: \(savedRunning ?? false), Language: \(savedLanguage ?? "nil")")
        
        // Update widget timeline
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
        print("App - Widget timeline reloaded")
        #endif
    }

    private func playCompletionCue() {
#if canImport(AVFoundation)
        configureAudioSession()
#endif
#if canImport(UIKit)
        notifyCompletion()
        playPhaseTransitionCue()
#endif
    }

    private func playPhaseTransitionCue() {
#if canImport(UIKit)
        let transitionID = SystemSoundID(1117)
        if overrideMute {
            AudioServicesPlaySystemSoundWithCompletion(transitionID, nil)
        } else {
            AudioServicesPlaySystemSound(transitionID)
        }
#endif
    }

    private func rewardAmountForCurrentStreak() -> Double {
        let minutes = Double(focusDuration) / 60.0
        let streakMultiplier = 1 + Double(streak - 1) * 0.15
        return minutes * max(streakMultiplier, 1)
    }

    private func passiveBoostForStreak() -> Double {
        Double(streak) * 0.02
    }

    private func advancePhase() {
        switch phase {
        case .focus:
            finishPhase()
        case .shortBreak, .longBreak:
            if autoStartBreaks {
            streak = 0
            startFocusSession()
            } else {
                phase = .idle
                remainingSeconds = 0
            }
        case .idle:
            break
        }
    }

    func snapshot() -> Snapshot {
        Snapshot(focusDuration: focusDuration,
                 shortBreakDuration: shortBreakDuration,
                 longBreakDuration: longBreakDuration,
                 sessionsBeforeLongBreak: sessionsBeforeLongBreak,
                 baseRewardPerSession: baseRewardPerSession,
                 soundEnabled: soundEnabled,
                 hapticsEnabled: hapticsEnabled,
                 autoStartBreaks: autoStartBreaks,
                 tickingEnabled: tickingEnabled,
                 selectedTickSound: selectedTickSound.rawValue,
                 overrideMute: overrideMute,
                 tickVolume: tickVolume,
                 notificationsEnabled: notificationsEnabled,
                 completedFocusSessions: completedFocusSessions,
                 streak: streak,
                 totalSessions: totalCompletedSessions,
                 totalFocusMinutes: totalFocusMinutes,
                 focusDays: Array(focusDays),
                 lastGoalReset: lastGoalReset,
                 sessionHistory: sessionHistory,
                 selectedCategory: selectedCategory)
    }
    
    private func notifyCompletion() {
#if canImport(UIKit)
        if soundEnabled {
            AudioServicesPlaySystemSound(SystemSoundID(1005))
        }
        if hapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
#endif
    }

    func toggleTicking() {
        tickingEnabled.toggle()
#if canImport(AVFoundation)
        if tickingEnabled {
            configureAudioSession()
            prepareTickPlayer(for: selectedTickSound)
        } else {
            deactivateAudioSession()
        }
#endif
    }

    func setTickSound(_ sound: TickSound) {
        selectedTickSound = sound
#if canImport(AVFoundation)
        prepareTickPlayer(for: sound)
#endif
    }

    func previewTick() {
#if canImport(UIKit)
        playTickSound(for: selectedTickSound)
#endif
    }

    private func requestNotificationPermissions() {
#if canImport(UIKit)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
#endif
    }

    private func schedulePhaseNotification(for completedPhase: PomodoroPhase, customInterval: TimeInterval? = nil) {
#if canImport(UIKit)
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch completedPhase {
        case .focus:
            content.title = LocalizationManager.shared.translate("NOTIF_FOCUS_DONE_TITLE")
            content.body = LocalizationManager.shared.translate("NOTIF_FOCUS_DONE_BODY")
        case .shortBreak, .longBreak:
            content.title = LocalizationManager.shared.translate("NOTIF_BREAK_DONE_TITLE")
            content.body = LocalizationManager.shared.translate("NOTIF_BREAK_DONE_BODY")
        case .idle:
            return
        }

        let interval: TimeInterval
        if let customInterval {
            interval = max(customInterval, 0.5)
        } else if let entered = backgroundEnteredAt {
            let elapsed = Date().timeIntervalSince(entered)
            let remainingTime = max(Double(remainingSeconds) - elapsed, 0)
            interval = max(remainingTime, 0.5)
        } else {
            interval = 0.1
        }

        let fireDate = Date().addingTimeInterval(interval)
        cancelScheduledNotifications(resetPending: false)

        let identifier = UUID().uuidString
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        scheduledNotificationIDs = [identifier]
        pendingNotificationPhase = completedPhase
        pendingNotificationFireDate = fireDate
#endif
    }

    // MARK: - AlarmKit (iOS 18+ placeholder integration)
    private func scheduleAlarmIfAvailable(for completedPhase: PomodoroPhase) {
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            guard notificationsEnabled else { return }
            let interval: TimeInterval
            if let entered = backgroundEnteredAt, isRunning == false {
                let elapsed = Date().timeIntervalSince(entered)
                let remaining = max(Double(remainingSeconds) - elapsed, 0)
                interval = max(remaining, 0.5)
            } else {
                interval = 0.1
            }
            let fireDate = Date().addingTimeInterval(interval)
            let title: String
            let body: String
            switch completedPhase {
            case .focus:
                title = LocalizationManager.shared.translate("NOTIF_FOCUS_DONE_TITLE")
                body = LocalizationManager.shared.translate("NOTIF_FOCUS_DONE_BODY")
            case .shortBreak, .longBreak:
                title = LocalizationManager.shared.translate("NOTIF_BREAK_DONE_TITLE")
                body = LocalizationManager.shared.translate("NOTIF_BREAK_DONE_BODY")
            case .idle:
                return
            }
            AlarmService.shared.scheduleAlarm(id: UUID().uuidString, date: fireDate, title: title, body: body)
        }
        #endif
    }

    private func handleLanguageChange() {
        let newLanguage = LocalizationManager.shared.language
        guard newLanguage != currentLanguage else { return }
        currentLanguage = newLanguage

#if canImport(UIKit)
        guard notificationsEnabled else { return }

        let phase = pendingNotificationPhase
        let fireDate = pendingNotificationFireDate

        cancelScheduledNotifications()

        if let phase, let fireDate {
            let remaining = fireDate.timeIntervalSinceNow
            if remaining > 0.5 {
                schedulePhaseNotification(for: phase, customInterval: remaining)
            }
        }

        promptForBackgroundRefreshIfNeeded()
#endif
    }

#if canImport(UIKit)
    private func cancelScheduledNotifications(resetPending: Bool = true) {
        guard !scheduledNotificationIDs.isEmpty else {
            if resetPending {
                pendingNotificationPhase = nil
                pendingNotificationFireDate = nil
            }
            return
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Array(scheduledNotificationIDs))
        scheduledNotificationIDs.removeAll()

        if resetPending {
            pendingNotificationPhase = nil
            pendingNotificationFireDate = nil
        }
    }

    private func updateBackgroundRefreshStatus() {
        DispatchQueue.main.async {
            let status = UIApplication.shared.backgroundRefreshStatus
            self.backgroundRefreshAvailable = status == .available
        }
    }

    private func promptForBackgroundRefreshIfNeeded() {
        updateBackgroundRefreshStatus()
        DispatchQueue.main.async {
            if self.notificationsEnabled && !self.backgroundRefreshAvailable {
                self.shouldPromptBackgroundRefresh = true
            } else {
                self.shouldPromptBackgroundRefresh = false
            }
        }
    }
#endif

#if canImport(UIKit)
    func acknowledgeBackgroundRefreshPrompt() {
        shouldPromptBackgroundRefresh = false
    }
#endif
}

extension PomodoroTimerService {
    enum TickSound: String, Codable, CaseIterable, Identifiable {
        case classic
        case wood
        case digital
        case loFi
        case glass

        var id: String { rawValue }

        var displayName: String {
            LocalizationManager.shared.translate("TICK_SOUND_\(rawValue)")
        }

    var frequency: Double {
        switch self {
        case .classic: return 950
        case .wood: return 650
        case .digital: return 1200
        case .loFi: return 420
        case .glass: return 1500
        }
    }

#if canImport(UIKit)
        var soundID: SystemSoundID {
            switch self {
            case .classic:
                return 1106 // Tock
            case .wood:
                return 1104 // Key press wood
            case .digital:
                return 1114 // Beep short
            case .loFi:
                return 1054 // Pop
            case .glass:
                return 1153 // Glass tap
            }
        }

        func play() {
#if targetEnvironment(simulator)
            AudioServicesPlaySystemSound(SystemSoundID(1106))
#else
            AudioServicesPlaySystemSoundWithCompletion(soundID, nil)
#endif
        }
#endif
    }
}

#if canImport(AVFoundation)
private extension PomodoroTimerService {
    func playTickSound(for sound: TickSound) {
        configureAudioSession()
        guard let player = tickPlayer(for: sound) else { return }
        player.currentTime = 0
        player.play()
    }

    func tickPlayer(for sound: TickSound) -> AVAudioPlayer? {
        if let existing = tickPlayers[sound] {
            existing.volume = Float(tickVolume)
            return existing
        }

        do {
            let player = try AVAudioPlayer(data: sound.audioData)
            player.volume = Float(tickVolume)
            player.prepareToPlay()
            tickPlayers[sound] = player
            return player
        } catch {
            print("Failed to prepare tick sound: \(error)")
            return nil
        }
    }

    func prepareTickPlayer(for sound: TickSound) {
        _ = tickPlayer(for: sound)
    }

    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        let category: AVAudioSession.Category = overrideMute ? .playback : .ambient
        let options: AVAudioSession.CategoryOptions = overrideMute ? [.mixWithOthers, .duckOthers] : [.mixWithOthers]

        do {
            try session.setCategory(category, options: options)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // ignore
        }
        tickPlayers.values.forEach { $0.stop() }
        tickPlayers.removeAll()
    }
}

private extension PomodoroTimerService.TickSound {
    private static var cache: [PomodoroTimerService.TickSound: Data] = [:]

    static func generateSineWave(frequency: Double, duration: Double = 0.12, sampleRate: Int = 44_100) -> Data {
        let frameCount = Int(Double(sampleRate) * duration)
        let amplitude = Double(Int16.max) * 0.45

        var data = Data()
        data.reserveCapacity(44 + frameCount * MemoryLayout<Int16>.size)

        func append<T>(_ value: T) {
            var v = value
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        append(UInt32(36 + frameCount * 2))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        append(UInt32(16)) // Subchunk1Size
        append(UInt16(1)) // PCM
        append(UInt16(1)) // Mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2)) // ByteRate
        append(UInt16(2)) // BlockAlign
        append(UInt16(16)) // Bits per sample
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        append(UInt32(frameCount * 2))

        for n in 0..<frameCount {
            let sample = sin(2.0 * .pi * frequency * Double(n) / Double(sampleRate))
            let value = Int16(sample * amplitude)
            append(value)
        }

        return data
    }

    var audioData: Data {
        if let cached = Self.cache[self] {
            return cached
        }
        let data = Self.generateSineWave(frequency: frequency)
        Self.cache[self] = data
        return data
    }
}
#endif

