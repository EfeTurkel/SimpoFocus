//
//  AppIntent.swift
//  Simpofocuswidget
//
//  Created by Efe Türkel on 17.10.2025.
//

import WidgetKit
import AppIntents
import Foundation
import UIKit
import ActivityKit

// MARK: - Live Activity Helper
@available(iOS 16.2, *)
func updateLiveActivity(isRunning: Bool, remainingSeconds: Int, endsAtTimestamp: Double) async {
    let endsAt = endsAtTimestamp > 0 ? Date(timeIntervalSince1970: endsAtTimestamp) : Date().addingTimeInterval(Double(remainingSeconds))
    for activity in Activity<FocusActivityAttributes>.activities {
        let current = activity.content.state
        let updated = FocusActivityAttributes.ContentState(
            phase: current.phase,
            endDate: endsAt,
            isPaused: !isRunning,
            remainingSeconds: remainingSeconds
        )
        await activity.update(ActivityContent(state: updated, staleDate: nil))
    }
}

// MARK: - Timer Control Intents
struct PauseTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description: IntentDescription = "Pause focus or break timer"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            shared.set(false, forKey: "isRunning")
            
            // Calculate remaining seconds if previously running
            let endsAt = shared.double(forKey: "running_ends_at")
            var remaining = shared.integer(forKey: "remainingSeconds")
            
            if endsAt > 0 {
                // If it was running, it had an endDate. We must figure out how much is left right now:
                remaining = max(0, Int(endsAt - Date().timeIntervalSince1970))
            }
            // Always save back the newly calculated remaining time!
            shared.set(remaining, forKey: "remainingSeconds")
            // Also nullify ends_at so the widget knows it's truly stopped
            shared.set(0.0, forKey: "running_ends_at")
            
            shared.set("pause", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
            
            #if DEBUG
            print("Widget - PauseTimerIntent: Set remaining=\(remaining), isRunning=false")
            #endif
        }
        
        // Force widget reload
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
        #endif
        
        return .result()
    }
}

struct ResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description: IntentDescription = "Resume paused timer"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            let selectedPhase = shared.string(forKey: "currentPhase") ?? "Odak"
            var remaining = shared.integer(forKey: "remainingSeconds")
            
            // If remainder is <= 0 or missing, fallback to defaults depending on phase
            if remaining <= 0 {
                let isBreak = selectedPhase.lowercased().contains("mola") || selectedPhase.lowercased().contains("break")
                remaining = isBreak ? 300 : 1500
                shared.set(remaining, forKey: "remainingSeconds")
            }
            
            shared.set(true, forKey: "isRunning")
            let endsAt = Date().timeIntervalSince1970 + Double(remaining)
            shared.set(endsAt, forKey: "running_ends_at")
            shared.set("resume", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
        }
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
        #endif
        
        return .result()
    }
}

struct ResetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    static var description: IntentDescription = "Reset and stop timer"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Send notification to app to reset timer
        NotificationCenter.default.post(name: .resetTimer, object: nil)
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            shared.set("reset", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
        }
        return .result()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let pauseTimer = Notification.Name("pauseTimer")
    static let resumeTimer = Notification.Name("resumeTimer")
    static let resetTimer = Notification.Name("resetTimer")
}

// MARK: - Start Timer Intent
struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Timer"
    static var description: IntentDescription = "Start focus or break timer"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            let selectedPhase = shared.string(forKey: "currentPhase") ?? "Odak"
            var remaining = shared.integer(forKey: "remainingSeconds")
            
            // If remainder is <= 0 or missing, fallback to defaults depending on phase
            if remaining <= 0 {
                let isBreak = selectedPhase.lowercased().contains("mola") || selectedPhase.lowercased().contains("break")
                remaining = isBreak ? 300 : 1500
                shared.set(remaining, forKey: "remainingSeconds")
            }
            
            shared.set(true, forKey: "isRunning")
            let endsAt = Date().timeIntervalSince1970 + Double(remaining)
            shared.set(endsAt, forKey: "running_ends_at")
            
            shared.set("start", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
            
            #if DEBUG
            print("Widget - StartTimerIntent: Set pendingAction=start and isRunning=true, remaining=\(remaining)")
            #endif
        }
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
        #endif
        
        return .result()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startTimer = Notification.Name("startTimer")
}

// MARK: - Configuration Intent (Legacy)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    @Parameter(title: "Favorite Emoji", default: "🎯")
    var favoriteEmoji: String
}
