import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), phase: "Odak", remainingSeconds: 1500, isRunning: false, endDate: nil, totalDuration: 1500)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, phase: "Odak", remainingSeconds: 1500, isRunning: false, endDate: nil, totalDuration: 1500)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        let phase = sharedDefaults?.string(forKey: "currentPhase") ?? "Odak"
        let isRunning = sharedDefaults?.bool(forKey: "isRunning") ?? false
        let endsAtTimestamp = sharedDefaults?.double(forKey: "running_ends_at")
        let savedRemaining = sharedDefaults?.integer(forKey: "remainingSeconds") ?? 1500

        var endDate: Date? = nil
        var remainingSeconds = savedRemaining
        
        let totalDuration: Int
        let lowerPhase = phase.lowercased()
        if lowerPhase.contains("mola") || lowerPhase.contains("break") {
            if lowerPhase.contains("uzun") || lowerPhase.contains("long") {
                totalDuration = 900 // 15 mins
            } else {
                totalDuration = 300 // 5 mins
            }
        } else {
            totalDuration = 1500 // 25 mins
        }

        if isRunning, let ts = endsAtTimestamp, ts > 0 {
            endDate = Date(timeIntervalSince1970: ts)
            if let end = endDate {
                remainingSeconds = max(0, Int(end.timeIntervalSince(Date()).rounded(.down)))
            }
        }
        
        #if DEBUG
        print("Widget Timeline - Phase: \(phase), Remaining: \(remainingSeconds), Running: \(isRunning), EndDate: \(endDate?.description ?? "nil")")
        #endif
        
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            phase: phase == "Hazır" ? "Odak" : phase,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            endDate: endDate,
            totalDuration: totalDuration
        )

        let refreshDate = endDate ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let phase: String
    let remainingSeconds: Int
    let isRunning: Bool
    let endDate: Date?
    let totalDuration: Int
}

struct SimpofocuswidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private func localizedString(_ key: String) -> String {
        let sharedDefaults = UserDefaults(suiteName: "group.com.efeturkel.simpoapp")
        let language = sharedDefaults?.string(forKey: "app_language") ?? "en"
        
        let translations: [String: [String: String]] = [
            "tr": [
                "ODAK": "Odak",
                "KISA_MOLA": "Kısa Mola",
                "UZUN_MOLA": "Uzun Mola",
                "HAZIR": "Hazır"
            ],
            "en": [
                "ODAK": "Focus",
                "KISA_MOLA": "Short Break",
                "UZUN_MOLA": "Long Break",
                "HAZIR": "Ready"
            ],
            "de": [
                "ODAK": "Fokus",
                "KISA_MOLA": "Kurze Pause",
                "UZUN_MOLA": "Lange Pause",
                "HAZIR": "Bereit"
            ]
        ]
        
        let locMap = ["Odak": "ODAK", "Kısa Mola": "KISA_MOLA", "Uzun Mola": "UZUN_MOLA", "Hazır": "HAZIR"]
        let lookupKey = locMap[key] ?? key
        
        return translations[language]?[lookupKey] ?? translations["en"]?[lookupKey] ?? key
    }

    var body: some View {
        let isBreak = entry.phase.lowercased().contains("mola") || entry.phase.lowercased().contains("break")
        let mainColor = isBreak ? Color.teal : Color.indigo
        let gradientSecondary = isBreak ? Color.mint : Color.purple
        
        ZStack {
            // Modern Background gradient
            LinearGradient(
                colors: [mainColor.opacity(0.85), gradientSecondary.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass overlay
            Color.black.opacity(0.15)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: isBreak ? "cup.and.saucer.fill" : "target")
                        .font(.system(size: 11, weight: .bold))
                    Text(localizedString(entry.phase))
                        .lineLimit(1)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Circle()
                        .fill(entry.isRunning ? Color.green : Color.white.opacity(0.6))
                        .frame(width: 10, height: 10)
                        .shadow(color: entry.isRunning ? .green : .clear, radius: 4)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Timer native live countdown
                if entry.isRunning, let endDate = entry.endDate, endDate > Date() {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .contentTransition(.numericText())
                } else {
                    Text(timeString(from: entry.remainingSeconds))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                }
                
                Spacer()
                
                // Interactive Button Container
                HStack {
                    if entry.isRunning {
                        let url = URL(string: "forest://pause")
                        if let url {
                            Link(destination: url) {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "pause.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                            }
                            .accessibilityLabel("Pause")
                        }
                    } else {
                        let url = URL(string: "forest://start")
                        if let url {
                            Link(destination: url) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(mainColor)
                                    )
                                    .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
                            }
                            .accessibilityLabel("Start")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .padding(0)
    }
    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct Simpofocuswidget: Widget {
    let kind: String = "Simpofocuswidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SimpofocuswidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget) // iOS 17 modern transparent container
        }
        .configurationDisplayName("Focus Timer")
        .description("Modern Pomodoro timer widget with fast interactive controls.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled() // Removes default padding so gradient fills completely!
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
    SimpleEntry(date: .now, configuration: .focus, phase: "Odak", remainingSeconds: 1500, isRunning: false, endDate: nil, totalDuration: 1500)
    SimpleEntry(date: .now, configuration: .`break`, phase: "Kısa Mola", remainingSeconds: 300, isRunning: true, endDate: Date().addingTimeInterval(300), totalDuration: 300)
}
