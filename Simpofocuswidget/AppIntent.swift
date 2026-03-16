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

// MARK: - Timer Control Intents
struct PauseTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description: IntentDescription = "Pause focus or break timer"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Send notification to app to pause timer
        #if DEBUG
        print("Widget - PauseTimerIntent triggered")
        #endif
        NotificationCenter.default.post(name: .pauseTimer, object: nil)
        // Write pending action for app to process when opened
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            shared.set("pause", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
            #if DEBUG
            print("Widget - PauseTimerIntent: Set pendingAction=pause")
            #endif
        } else {
            #if DEBUG
            print("Widget - PauseTimerIntent: Failed to access shared UserDefaults")
            #endif
        }
        
        // Force widget reload after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
            #if DEBUG
            print("Widget - Forced timeline reload after pause")
            #endif
            #endif
        }
        
        return .result()
    }
}

struct ResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description: IntentDescription = "Resume paused timer"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Send notification to app to resume timer
        NotificationCenter.default.post(name: .resumeTimer, object: nil)
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            shared.set("resume", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
        }
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
        #if DEBUG
        print("Widget - StartTimerIntent triggered")
        #endif
        
        // Send notification to app
        NotificationCenter.default.post(name: .startTimer, object: nil)
        if let shared = UserDefaults(suiteName: "group.com.efeturkel.simpoapp") {
            shared.set("start", forKey: "pendingAction")
            shared.set(Date().timeIntervalSince1970, forKey: "pendingActionAt")
            #if DEBUG
            print("Widget - StartTimerIntent: Set pendingAction=start")
            #endif
        } else {
            #if DEBUG
            print("Widget - StartTimerIntent: Failed to access shared UserDefaults")
            #endif
        }
        
        // Force widget reload immediately and after delays
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
        #if DEBUG
        print("Widget - Immediate timeline reload after start")
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
            #if DEBUG
            print("Widget - Quick timeline reload after start")
            #endif
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
            #if DEBUG
            print("Widget - Delayed timeline reload after start")
            #endif
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadTimelines(ofKind: "Simpofocuswidget")
            #if DEBUG
            print("Widget - Final timeline reload after start")
            #endif
        }
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
