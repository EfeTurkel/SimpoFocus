import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var entitlements: EntitlementManager

    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showingPaywall = false

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
            VStack(spacing: DS.Padding.card) {
                heroCard
                proGatedSection(analyticsStack)
                dailyGoalCard
                proGatedSection(activityHeatmap)
            }
            .padding(.horizontal, DS.Padding.screen)
            .padding(.vertical, DS.Padding.section)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .background(
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()
        )
    }

    private var heroCard: some View {
        VStack(spacing: DS.Padding.card) {
            VStack(spacing: 6) {
                Text(loc("STATS_TOTAL_FOCUS_TIME"))
                    .font(DS.Typography.caption)
                    .onGlassSecondary()
                Text(formattedHours(totalHours))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .onGlassPrimary()
            }

            HStack(spacing: 0) {
                MetricChip(icon: "timer", title: loc("STATS_TOTAL_SESSIONS"), value: "\(timer.totalCompletedSessions)")
                Divider().frame(height: 32)
                MetricChip(icon: "calendar", title: loc("STATS_ACTIVE_DAYS"), value: "\(activeDaysCount)")
                Divider().frame(height: 32)
                MetricChip(icon: "chart.bar", title: loc("STATS_AVERAGE_SESSION"), value: formattedMinutes(averageMinutesPerSession))
            }
        }
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.hero, edgeMask: [.top])
    }

    private var analyticsStack: some View {
        VStack(alignment: .leading, spacing: DS.Padding.section) {
            Text(loc("STATS_PERFORMANCE_SUMMARY"))
                .font(.subheadline.weight(.semibold))
                .onGlassPrimary()

            VStack(spacing: DS.Padding.section) {
                AnalyticsRow(icon: "flame.fill", title: loc("STATS_BEST_STREAK"), detail: loc("STATS_STREAK_VALUE", timer.streak))
                AnalyticsRow(icon: "clock.arrow.circlepath", title: loc("STATS_DAILY_AVERAGE"), detail: formattedMinutes(timer.totalFocusMinutes / Double(max(activeDaysCount, 1))))
                AnalyticsRow(icon: "bolt.heart", title: loc("STATS_LAST_FOCUS"), detail: lastFocusText)
            }
            .padding(DS.Padding.card)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .fill(.clear)
            )
            .liquidGlass(.card, edgeMask: [.top])
        }
    }

    private var dailyGoalCard: some View {
        VStack(alignment: .leading, spacing: DS.Padding.section) {
            HStack {
                Text(loc("STATS_DAILY_GOAL"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(loc("STATS_GOAL_VALUE", timer.completedFocusSessions, market.dailyTarget))
                    .font(.subheadline.weight(.bold))
            }
            .onGlassPrimary()

            ProgressView(value: min(Double(timer.completedFocusSessions) / Double(max(market.dailyTarget, 1)), 1))
                .tint(Color("ForestGreen"))

            Text(timer.completedFocusSessions >= market.dailyTarget ? loc("STATS_GOAL_COMPLETE") : loc("STATS_GOAL_PROGRESS"))
                .font(.caption)
                .onGlassSecondary()
        }
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
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
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
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

    @ViewBuilder
    private func proGatedSection<Content: View>(_ content: Content) -> some View {
        if entitlements.hasAdvancedAnalytics {
            content
        } else {
            content
                .blur(radius: 6)
                .overlay(
                    VStack(spacing: DS.Padding.element) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color("ForestGreen"))
                        Text(loc("PRO_GATE_ANALYTICS"))
                            .font(DS.Typography.cardTitle)
                            .onGlassPrimary()
                            .multilineTextAlignment(.center)
                        Button {
                            showingPaywall = true
                        } label: {
                            Text(loc("PRO_GATE_UNLOCK"))
                                .font(DS.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, DS.Padding.card)
                                .padding(.vertical, 10)
                                .background(Color("ForestGreen"), in: Capsule())
                        }
                    }
                    .padding(DS.Padding.card)
                )
                .allowsHitTesting(false)
                .overlay(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { showingPaywall = true }
                )
        }
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
                .font(DS.Typography.caption)
                .onGlassSecondary()
            Text(value)
                .font(DS.Typography.cardTitle)
                .onGlassPrimary()
            Text(title)
                .font(DS.Typography.micro)
                .onGlassSecondary()
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
    }
}

private struct AnalyticsRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .onGlassSecondary()
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .onGlassPrimary()

            Spacer()

            Text(detail)
                .font(.subheadline.weight(.medium))
                .onGlassPrimary()
        }
    }
}

private struct ActivityDayCell: View {
    let date: Date
    let isActive: Bool
    let formatter: DateFormatter
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isActive ? Color("ForestGreen") : Color("ForestGreen").opacity(0.08))
            .frame(height: 36)
            .overlay(
                Text(formatter.string(from: date))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isActive ? .white : themeManager.currentTheme.glassSecondaryText(for: colorScheme))
            )
    }
}
