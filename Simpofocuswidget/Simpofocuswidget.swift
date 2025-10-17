//
//  Simpofocuswidget.swift
//  Simpofocuswidget
//
//  Created by Efe Türkel on 17.10.2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), phase: "Hazır", remainingSeconds: 1500, isRunning: false)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, phase: "Hazır", remainingSeconds: 1500, isRunning: false)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Get current timer state from UserDefaults (shared between app and widget)
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        let phase = sharedDefaults?.string(forKey: "currentPhase") ?? "Hazır"
        let remainingSeconds = sharedDefaults?.integer(forKey: "remainingSeconds") ?? 1500
        let isRunning = sharedDefaults?.bool(forKey: "isRunning") ?? false
        
        // Debug log
        print("Widget Timeline - SharedDefaults: \(sharedDefaults != nil), Phase: \(phase), Remaining: \(remainingSeconds), Running: \(isRunning)")
        
        // Test if we can write to shared defaults
        sharedDefaults?.set("Test", forKey: "testKey")
        let testValue = sharedDefaults?.string(forKey: "testKey")
        print("Widget Test Write/Read: \(testValue ?? "nil")")
        
        // Test reading all keys
        let allKeys = sharedDefaults?.dictionaryRepresentation().keys
        print("Widget - All keys in shared defaults: \(allKeys.map { Array($0) } ?? [])")
        
        // Test reading specific keys
        let testPhase = sharedDefaults?.string(forKey: "currentPhase")
        let testRemaining = sharedDefaults?.integer(forKey: "remainingSeconds")
        let testRunning = sharedDefaults?.bool(forKey: "isRunning")
        print("Widget - Direct read - Phase: \(testPhase ?? "nil"), Remaining: \(testRemaining ?? -1), Running: \(testRunning ?? false)")
        
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, configuration: configuration, phase: phase, remainingSeconds: remainingSeconds, isRunning: isRunning)
        entries.append(entry)

        // If timer is running, update every second for real-time countdown
        if isRunning && remainingSeconds > 0 {
            for i in 1...min(remainingSeconds, 300) { // Update for next 300 seconds (5 minutes) max
                let nextDate = Calendar.current.date(byAdding: .second, value: i, to: currentDate)!
                let nextEntry = SimpleEntry(
                    date: nextDate, 
                    configuration: configuration, 
                    phase: phase, 
                    remainingSeconds: max(0, remainingSeconds - i), 
                    isRunning: isRunning
                )
                entries.append(nextEntry)
            }
        } else {
            // If not running, update every 5 seconds for faster response
            let nextUpdate = Calendar.current.date(byAdding: .second, value: 5, to: currentDate)!
            let nextEntry = SimpleEntry(date: nextUpdate, configuration: configuration, phase: phase, remainingSeconds: remainingSeconds, isRunning: isRunning)
            entries.append(nextEntry)
        }
        
        print("Widget Timeline - Final entries count: \(entries.count), First entry remainingSeconds: \(entries.first?.remainingSeconds ?? -1)")

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let phase: String
    let remainingSeconds: Int
    let isRunning: Bool
}

struct SimpofocuswidgetEntryView : View {
    var entry: Provider.Entry
    
    private func localizedString(_ key: String) -> String {
        // Get current language from UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        let language = sharedDefaults?.string(forKey: "app_language") ?? "en"
        
        // Simple localization dictionary for widget
        let translations: [String: [String: String]] = [
            "tr": [
                "STATE_ACTIVE": "Aktif",
                "STATE_READY": "Hazır",
                "CONTROL_PAUSE": "Durdur",
                "CONTROL_START": "Başlat",
                "CONTROL_RESUME": "Devam Et",
                "CONTROL_RESET": "Sıfırla",
                "PHASE_FOCUS": "Odak",
                "PHASE_SHORT_BREAK": "Kısa Mola",
                "PHASE_LONG_BREAK": "Uzun Mola",
                "PHASE_IDLE": "Hazır"
            ],
            "en": [
                "STATE_ACTIVE": "Active",
                "STATE_READY": "Ready",
                "CONTROL_PAUSE": "Pause",
                "CONTROL_START": "Start",
                "CONTROL_RESUME": "Resume",
                "CONTROL_RESET": "Reset",
                "PHASE_FOCUS": "Focus",
                "PHASE_SHORT_BREAK": "Short Break",
                "PHASE_LONG_BREAK": "Long Break",
                "PHASE_IDLE": "Ready"
            ],
            "de": [
                "STATE_ACTIVE": "Aktiv",
                "STATE_READY": "Bereit",
                "CONTROL_PAUSE": "Pause",
                "CONTROL_START": "Start",
                "CONTROL_RESUME": "Fortsetzen",
                "CONTROL_RESET": "Zurücksetzen",
                "PHASE_FOCUS": "Fokus",
                "PHASE_SHORT_BREAK": "Kurze Pause",
                "PHASE_LONG_BREAK": "Lange Pause",
                "PHASE_IDLE": "Bereit"
            ]
        ]
        
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with phase and status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.phase)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        Text(entry.isRunning ? localizedString("STATE_ACTIVE") : localizedString("STATE_READY"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(entry.isRunning ? .green : .secondary)
                }
                Spacer()
                Circle()
                    .fill(entry.isRunning ? .green : .gray)
                    .frame(width: 8, height: 8)
            }
            
            // Timer display
            VStack(spacing: 4) {
                Text(timeString(from: entry.remainingSeconds))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .onAppear {
                        print("Widget UI - entry.remainingSeconds: \(entry.remainingSeconds)")
                    }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * progressPercentage(entry), height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            // Action button
            if entry.isRunning {
                    Button(intent: PauseTimerIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text(localizedString("CONTROL_PAUSE"))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                .buttonStyle(.bordered)
                .tint(.orange)
                .controlSize(.small)
                .onTapGesture {
                    print("Widget - Pause button tapped (onTapGesture)")
                }
            } else {
                    Button(intent: StartTimerIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text(localizedString("CONTROL_START"))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                .buttonStyle(.bordered)
                .tint(.green)
                .controlSize(.small)
                .onTapGesture {
                    print("Widget - Start button tapped (onTapGesture)")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
        private func timeString(from seconds: Int) -> String {
            let m = seconds / 60
            let s = seconds % 60
            let timeString = String(format: "%02d:%02d", m, s)
            print("Widget timeString - seconds: \(seconds), result: \(timeString)")
            return timeString
        }
    
        private func progressPercentage(_ entry: SimpleEntry) -> Double {
            let totalDuration: Int
            switch entry.phase {
            case "Odak":
                totalDuration = 1500 // 25 minutes
            case "Kısa Mola":
                totalDuration = 300 // 5 minutes
            case "Uzun Mola":
                totalDuration = 900 // 15 minutes
            case "Hazır":
                return 0.0 // No progress when idle
            default:
                totalDuration = 1500
            }
            
            let elapsed = totalDuration - entry.remainingSeconds
            return max(0, min(1, Double(elapsed) / Double(totalDuration)))
        }
}

struct Simpofocuswidget: Widget {
    let kind: String = "Simpofocuswidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SimpofocuswidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Focus Timer")
        .description("Modern Pomodoro timer widget with iOS 26 Liquid Glass design")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var focus: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🎯"
        return intent
    }
    
    fileprivate static var `break`: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "☕"
        return intent
    }
}

#Preview(as: .systemSmall) {
    Simpofocuswidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .focus, phase: "Odak", remainingSeconds: 1500, isRunning: false)
    SimpleEntry(date: .now, configuration: .`break`, phase: "Kısa Mola", remainingSeconds: 300, isRunning: true)
}
