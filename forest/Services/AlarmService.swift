import Foundation

#if canImport(AlarmKit)
import AlarmKit
#endif

/// Thin wrapper to integrate system alarms when available.
/// Falls back to no-op on platforms without AlarmKit.
final class AlarmService {
    static let shared = AlarmService()
    private init() {}

    private var activeAlarmId: String?

    func requestAuthorization() {
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            // Placeholder: request any required permissions if needed by AlarmKit.
            // AlarmKit currently does not require explicit authorization similar to notifications.
        }
        #endif
    }

    func scheduleAlarm(id: String, date: Date, title: String, body: String) {
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            // NOTE: Replace with concrete AlarmKit API when adopting the SDK.
            // This placeholder ensures the app compiles on older SDKs while keeping call sites.
            // Example (pseudocode):
            // let alarm = AKAlarm(date: date, label: title)
            // try? AKAlarmCenter.shared.add(alarm)
            activeAlarmId = id
        }
        #endif
    }

    func startOrUpdateCountdown(start: Date, end: Date, label: String) {
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            // Example (pseudocode):
            // let alarm = AKAlarm(startDate: start, endDate: end, label: label)
            // if let id = activeAlarmId { AKAlarmCenter.shared.update(id, with: alarm) } else { activeAlarmId = try? AKAlarmCenter.shared.add(alarm) }
        }
        #endif
    }

    func cancelAll() {
        #if canImport(AlarmKit)
        if #available(iOS 18.0, *) {
            // Example (pseudocode): AKAlarmCenter.shared.removeAll()
            activeAlarmId = nil
        }
        #endif
    }
}


