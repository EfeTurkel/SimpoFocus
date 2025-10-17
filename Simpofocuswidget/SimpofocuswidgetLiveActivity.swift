//
//  SimpofocuswidgetLiveActivity.swift
//  Simpofocuswidget
//
//  Created by Efe Türkel on 17.10.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let phase: String
        let endDate: Date
        let isPaused: Bool
        let remainingSeconds: Int
    }
}

struct SimpofocuswidgetLiveActivity: Widget {
    private func localizedString(_ key: String) -> String {
        // Get current language from UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        let language = sharedDefaults?.string(forKey: "app_language") ?? "en"
        
        // Simple localization dictionary for Live Activity
        let translations: [String: [String: String]] = [
            "tr": [
                "STATE_ACTIVE": "Aktif",
                "STATE_PAUSED": "Duraklatıldı",
                "CONTROL_PAUSE": "Durdur",
                "CONTROL_START": "Başlat",
                "CONTROL_RESUME": "Devam",
                "CONTROL_RESET": "Sıfırla",
                "PHASE_FOCUS": "Odak",
                "PHASE_SHORT_BREAK": "Kısa Mola",
                "PHASE_LONG_BREAK": "Uzun Mola",
                "PHASE_IDLE": "Hazır",
                "ACTION_HINT_PAUSED": "Devam etmek için uygulamayı aç",
                "ACTION_HINT_ACTIVE": "Durdurmak için uygulamayı aç"
            ],
            "en": [
                "STATE_ACTIVE": "Active",
                "STATE_PAUSED": "Paused",
                "CONTROL_PAUSE": "Pause",
                "CONTROL_START": "Start",
                "CONTROL_RESUME": "Resume",
                "CONTROL_RESET": "Reset",
                "PHASE_FOCUS": "Focus",
                "PHASE_SHORT_BREAK": "Short Break",
                "PHASE_LONG_BREAK": "Long Break",
                "PHASE_IDLE": "Ready",
                "ACTION_HINT_PAUSED": "Open app to resume",
                "ACTION_HINT_ACTIVE": "Open app to pause"
            ],
            "de": [
                "STATE_ACTIVE": "Aktiv",
                "STATE_PAUSED": "Pausiert",
                "CONTROL_PAUSE": "Pause",
                "CONTROL_START": "Start",
                "CONTROL_RESUME": "Fortsetzen",
                "CONTROL_RESET": "Zurücksetzen",
                "PHASE_FOCUS": "Fokus",
                "PHASE_SHORT_BREAK": "Kurze Pause",
                "PHASE_LONG_BREAK": "Lange Pause",
                "PHASE_IDLE": "Bereit",
                "ACTION_HINT_PAUSED": "App öffnen zum Fortsetzen",
                "ACTION_HINT_ACTIVE": "App öffnen zum Pausieren"
            ]
        ]
        
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock screen/banner UI - Modern mini app design
            VStack(spacing: 16) {
                // Header with phase and status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.phase)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            if context.state.isPaused {
                                Text(localizedString("STATE_PAUSED"))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(localizedString("STATE_ACTIVE"))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.green)
                            }
                    }
                    Spacer()
                    Image(systemName: context.state.isPaused ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(context.state.isPaused ? .orange : .green)
                }
                
                // Main timer display
                VStack(spacing: 8) {
                    if context.state.isPaused {
                        Text(timeString(from: context.state.remainingSeconds))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    } else {
                        Text(context.state.endDate, style: .timer)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * progressPercentage(context.state), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                    // Action hint
                    Text(context.state.isPaused ? localizedString("ACTION_HINT_PAUSED") : localizedString("ACTION_HINT_ACTIVE"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        // Compact header with phase and status
                        HStack {
                            Text(context.state.phase)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(context.state.isPaused ? Color.orange : Color.green)
                                    .frame(width: 6, height: 6)
                                    Text(context.state.isPaused ? localizedString("STATE_PAUSED") : localizedString("STATE_ACTIVE"))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                            }
                        }
                        
                        // Compact timer display with inline progress
                        HStack(spacing: 8) {
                            if context.state.isPaused {
                                Text(timeString(from: context.state.remainingSeconds))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            } else {
                                Text(context.state.endDate, style: .timer)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            
                            // Compact progress indicator
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 3)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: geometry.size.width * progressPercentage(context.state), height: 3)
                                }
                            }
                            .frame(width: 60, height: 3)
                        }
                        
                        // Compact action buttons
                        HStack(spacing: 6) {
                            if context.state.isPaused {
                                Button(intent: ResumeTimerIntent()) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10, weight: .medium))
                                            Text(localizedString("CONTROL_RESUME"))
                                                .font(.system(size: 9, weight: .medium))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                                .controlSize(.mini)
                                
                                Button(intent: ResetTimerIntent()) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 10, weight: .medium))
                                            Text(localizedString("CONTROL_RESET"))
                                                .font(.system(size: 9, weight: .medium))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .controlSize(.mini)
                            } else {
                                Button(intent: PauseTimerIntent()) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "pause.fill")
                                            .font(.system(size: 10, weight: .medium))
                                            Text(localizedString("CONTROL_PAUSE"))
                                                .font(.system(size: 9, weight: .medium))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                                .controlSize(.mini)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            } compactLeading: {
                // Extra-compact leading indicator
                Image(systemName: context.state.isPaused ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(context.state.isPaused ? .orange : .green)
                    .frame(width: 14, height: 14, alignment: .center)
            } compactTrailing: {
                // Tight timer text
                if context.state.isPaused {
                    Text(timeString(from: context.state.remainingSeconds))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: 46, alignment: .trailing)
                } else {
                    Text(context.state.endDate, style: .timer)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: 46, alignment: .trailing)
                }
            } minimal: {
                // Tiny status dot
                Circle()
                    .fill(context.state.isPaused ? Color.orange : Color.green)
                    .frame(width: 5, height: 5)
            }
        }
    }
}

private func timeString(from seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

private func progressPercentage(_ state: FocusActivityAttributes.ContentState) -> Double {
    // Calculate progress based on remaining seconds
    // Assuming 25 minutes (1500 seconds) for focus, 5 minutes (300 seconds) for short break
    let totalDuration: Int
    switch state.phase {
    case "Odak":
        totalDuration = 1500 // 25 minutes
    case "Kısa Mola":
        totalDuration = 300 // 5 minutes
    case "Uzun Mola":
        totalDuration = 900 // 15 minutes
    default:
        totalDuration = 1500
    }
    
    let elapsed = totalDuration - state.remainingSeconds
    return max(0, min(1, Double(elapsed) / Double(totalDuration)))
}

extension FocusActivityAttributes {
    fileprivate static var preview: FocusActivityAttributes {
        FocusActivityAttributes()
    }
}

extension FocusActivityAttributes.ContentState {
    fileprivate static var focus: FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            phase: "Odak",
            endDate: Date().addingTimeInterval(1500), // 25 minutes
            isPaused: false,
            remainingSeconds: 1500
        )
    }
     
    fileprivate static var `break`: FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            phase: "Mola",
            endDate: Date().addingTimeInterval(300), // 5 minutes
            isPaused: true,
            remainingSeconds: 300
        )
    }
}

#Preview("Notification", as: .content, using: FocusActivityAttributes.preview) {
   SimpofocuswidgetLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState.focus
    FocusActivityAttributes.ContentState.`break`
}
