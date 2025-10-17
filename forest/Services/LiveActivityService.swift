import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let phase: String
        let endDate: Date
        let isPaused: Bool
        let remainingSeconds: Int
    }
}

/// Manages Live Activity for Pomodoro phases (focus / breaks)
@available(iOS 16.1, *)
final class LiveActivityService {
    static let shared = LiveActivityService()
    private init() {}

    private var activity: Activity<FocusActivityAttributes>?

    func startOrUpdate(phase: String, endDate: Date, isPaused: Bool = false, remainingSeconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // Calculate the correct end date based on remaining seconds
        let actualEndDate = isPaused ? Date() : Date().addingTimeInterval(TimeInterval(remainingSeconds))
        
        let state = FocusActivityAttributes.ContentState(
            phase: phase,
            endDate: actualEndDate,
            isPaused: isPaused,
            remainingSeconds: remainingSeconds
        )

        if let activity {
            Task { await activity.update(using: state) }
            return
        }

        let attributes = FocusActivityAttributes()
        do {
            let activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            self.activity = activity
        } catch {
            // Silently ignore; Live Activity may be restricted or not allowed
        }
    }

    func pause(phase: String, remainingSeconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = FocusActivityAttributes.ContentState(
            phase: phase,
            endDate: Date(), // When paused, endDate is current time
            isPaused: true,
            remainingSeconds: remainingSeconds
        )
        if let activity {
            Task { await activity.update(using: state) }
        }
    }

    func end() {
        guard let activity else { return }
        Task { await activity.end(using: FocusActivityAttributes.ContentState(phase: "", endDate: Date(), isPaused: false, remainingSeconds: 0), dismissalPolicy: .immediate) }
        self.activity = nil
    }
}

#endif


