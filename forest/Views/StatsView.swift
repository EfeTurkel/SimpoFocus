import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel

    private var totalHours: Double {
        timer.totalFocusMinutes / 60
    }

    private var activeDaysCount: Int {
        timer.focusDays.count
    }

    private var averageMinutesPerSession: Double {
        guard timer.totalCompletedSessions > 0 else { return 0 }
        return timer.totalFocusMinutes / Double(timer.totalCompletedSessions)
    }

    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                heroCard
                analyticsStack
                dailyGoalCard
                activityHeatmap
            }
            .padding(24)
        }
        .background(
            LinearGradient(colors: [Color("LakeNight").opacity(0.7), Color("ForestGreen").opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }

    private var heroCard: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text(loc("STATS_TOTAL_FOCUS_TIME"))
                    .font(.subheadline.weight(.semibold))
                    .onGlassSecondary()
                Text(formattedHours(totalHours))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .onGlassPrimary()
                    .shadow(color: .black.opacity(0.4), radius: 16, y: 10)
            }

            HStack(spacing: 18) {
                MetricChip(icon: "timer", title: loc("STATS_TOTAL_SESSIONS"), value: "\(timer.totalCompletedSessions)")
                MetricChip(icon: "calendar", title: loc("STATS_ACTIVE_DAYS"), value: "\(activeDaysCount)")
                MetricChip(icon: "chart.bar", title: loc("STATS_AVERAGE_SESSION"), value: formattedMinutes(averageMinutesPerSession))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.header, edgeMask: [.top])
    }

    private var analyticsStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(loc("STATS_PERFORMANCE_SUMMARY"))
                .font(.headline)
                .onGlassPrimary()

            VStack(spacing: 18) {
                AnalyticsRow(icon: "flame.fill", title: loc("STATS_BEST_STREAK"), detail: loc("STATS_STREAK_VALUE", timer.streak))
                AnalyticsRow(icon: "clock.arrow.circlepath", title: loc("STATS_DAILY_AVERAGE"), detail: formattedMinutes(timer.totalFocusMinutes / Double(max(activeDaysCount, 1))))
                AnalyticsRow(icon: "bolt.heart", title: loc("STATS_LAST_FOCUS"), detail: lastFocusText)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
            )
            .liquidGlass(.card, edgeMask: [.top, .bottom])
        }
    }

    private var dailyGoalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(loc("STATS_DAILY_GOAL"))
                    .font(.headline)
                Spacer()
                Text(loc("STATS_GOAL_VALUE", timer.completedFocusSessions, market.dailyTarget))
                    .font(.title3.weight(.semibold))
            }
            .onGlassPrimary()

            ProgressView(value: min(Double(timer.completedFocusSessions) / Double(max(market.dailyTarget, 1)), 1))
                .tint(Color("ForestGreen"))
                .frame(height: 12)
                .background(Color.white.opacity(0.08), in: Capsule())

            Text(timer.completedFocusSessions >= market.dailyTarget ? loc("STATS_GOAL_COMPLETE") : loc("STATS_GOAL_PROGRESS"))
                .font(.footnote)
                .onGlassSecondary()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
    }

    private var activityHeatmap: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(loc("STATS_ACTIVITY_CALENDAR"))
                    .font(.headline)
                Spacer()
                Text(loc("STATS_ACTIVITY_DAYS", historyDays))
                    .font(.footnote)
                    .onGlassSecondary()
            }
            .onGlassPrimary()

            let dates = generateRecentDates()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(dates, id: \ .self) { date in
                    ActivityDayCell(date: date,
                                    isActive: timer.focusDays.contains(calendar.startOfDay(for: date)),
                                    formatter: shortDayFormatter)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
    }

    private var calendar: Calendar { Calendar.current }

    private var historyDays: Int { 28 }

    private func generateRecentDates() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<historyDays).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    private var shortDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter
    }

    private var lastFocusText: String {
        guard let last = timer.lastFocusStart else { return loc("STATS_LAST_FOCUS_NONE") }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter.localizedString(for: last, relativeTo: Date())
    }

    private func formattedHours(_ hours: Double) -> String {
        if hours >= 1 {
            let wholeHours = Int(hours)
            let minutes = Int((hours - Double(wholeHours)) * 60)
            return loc("STATS_HOURS_FORMAT", wholeHours, minutes)
        } else {
            return loc("STATS_MINUTES_FORMAT", Int(hours * 60))
        }
    }

    private func formattedMinutes(_ minutes: Double) -> String {
        return loc("STATS_MINUTES_FORMAT", Int(minutes))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct MetricChip: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .onGlassPrimary()
                .padding(10)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(value)
                .font(.headline)
                .onGlassPrimary()

            Text(title)
                .font(.caption2)
                .onGlassSecondary()
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct AnalyticsRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
    }
}

private struct ActivityDayCell: View {
    let date: Date
    let isActive: Bool
    let formatter: DateFormatter

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(fillStyle)
            .frame(height: 34)
            .overlay(
                Text(formatter.string(from: date))
                    .font(.caption2)
                    .foregroundStyle(isActive ? .white : .white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(borderStyle, lineWidth: 1)
            )
            .shadow(color: isActive ? Color("ForestGreen").opacity(0.2) : .clear, radius: 6, y: 3)
    }

    private var fillStyle: AnyShapeStyle {
        if isActive {
            return AnyShapeStyle(LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.07))
        }
    }

    private var borderStyle: Color {
        isActive ? Color.white.opacity(0.2) : Color.white.opacity(0.05)
    }
}
