import SwiftUI

struct YearlyAnalyticsView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var showingPaywall = false

    private var isPro: Bool { entitlements.hasAdvancedAnalytics }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var activeCalculator: AnalyticsCalculator {
        isPro ? realCalculator : demoCalculator
    }

    private var realCalculator: AnalyticsCalculator {
        AnalyticsCalculator(
            sessionHistory: timer.sessionHistory,
            legacyTotalMinutes: timer.totalFocusMinutes
        )
    }

    private var demoCalculator: AnalyticsCalculator {
        let categories: [FocusCategory] = [
            .predefined(.coding), .predefined(.algorithms),
            .predefined(.physics), .predefined(.business)
        ]
        let seededRNG = SeededRandomGenerator(seed: 42)
        var sessions: [FocusSession] = []
        let cal = Calendar.current
        var dayOffset = 0
        while dayOffset < 300 {
            let date = cal.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let count = seededRNG.next(in: 1...4)
            for _ in 0..<count {
                sessions.append(FocusSession(
                    date: date,
                    durationMinutes: Double(seededRNG.next(in: 15...50)),
                    category: categories[seededRNG.next(in: 0...(categories.count - 1))],
                    coinsEarned: Double(seededRNG.next(in: 5...25))
                ))
            }
            dayOffset += seededRNG.next(in: 1...3)
        }
        return AnalyticsCalculator(sessionHistory: sessions, legacyTotalMinutes: 0)
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            analyticsContent
                .blur(radius: isPro ? 0 : 6)
                .allowsHitTesting(isPro)

            if !isPro {
                proOverlay
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Analytics Content

    private var analyticsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerView
                quickStatsGrid
                categorySection
                bestRecordsSection
                heatmapSection
            }
            .padding(24)
        }
    }

    // MARK: - Pro Overlay

    private var proOverlay: some View {
        VStack {
            VStack(spacing: DS.Padding.section) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color("ForestGreen"))

                Text(loc("PRO_GATE_ANALYTICS"))
                    .font(DS.Typography.cardTitle)
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text(loc("PRO_GATE_ANALYTICS_DESC"))
                    .font(DS.Typography.caption)
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)

                Button { showingPaywall = true } label: {
                    Text(loc("PRO_GATE_UNLOCK"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Padding.card)
                        .padding(.vertical, 12)
                        .background(Color("ForestGreen"), in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(DS.Padding.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, DS.Padding.screen)
            .padding(.top, 80)

            Spacer()
        }
    }

    // MARK: - Sections

    private var headerView: some View {
        HStack {
            Text(loc("ANALYTICS_TITLE"))
                .font(.title.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

            Spacer()

            Text(String(format: "%d", currentYear))
                .font(.title3.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
        }
    }

    private var quickStatsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatCard(
                    title: loc("ANALYTICS_TODAY"),
                    value: formatHours(activeCalculator.todayStats().hours),
                    sessions: activeCalculator.todayStats().sessions,
                    icon: "sun.max.fill",
                    color: .orange
                )
                .environmentObject(localization)

                StatCard(
                    title: loc("ANALYTICS_WEEK"),
                    value: formatHours(activeCalculator.weekStats().hours),
                    sessions: activeCalculator.weekStats().sessions,
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                .environmentObject(localization)
            }

            HStack(spacing: 12) {
                StatCard(
                    title: loc("ANALYTICS_MONTH"),
                    value: formatHours(activeCalculator.monthStats().hours),
                    sessions: activeCalculator.monthStats().sessions,
                    icon: "calendar",
                    color: .purple
                )
                .environmentObject(localization)

                StatCard(
                    title: loc("ANALYTICS_YEAR"),
                    value: formatHours(activeCalculator.yearStats(year: currentYear).hours),
                    sessions: activeCalculator.yearStats(year: currentYear).sessions,
                    icon: "chart.bar.fill",
                    color: .green
                )
                .environmentObject(localization)
            }

            StatCard(
                title: loc("ANALYTICS_ALL_TIME"),
                value: formatHours(activeCalculator.allTimeStats().hours),
                sessions: activeCalculator.allTimeStats().sessions,
                icon: "infinity",
                color: .pink,
                isWide: true
            )
            .environmentObject(localization)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("ANALYTICS_CATEGORY_BREAKDOWN"))
                .font(.headline.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

            let categoryStats = activeCalculator.categoryBreakdown(for: currentYear)

            if categoryStats.isEmpty {
                Text(loc("ANALYTICS_NO_DATA"))
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                CategoryPieChart(categoryStats: categoryStats)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    private var bestRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("ANALYTICS_BEST_RECORDS"))
                .font(.headline.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

            VStack(spacing: 12) {
                if let bestDay = activeCalculator.bestDay() {
                    BestRecordRow(
                        icon: "star.fill",
                        title: loc("ANALYTICS_BEST_DAY"),
                        value: formatHours(bestDay.hours),
                        subtitle: formatDate(bestDay.date),
                        color: .yellow
                    )
                }

                if let bestWeek = activeCalculator.bestWeek() {
                    BestRecordRow(
                        icon: "flame.fill",
                        title: loc("ANALYTICS_BEST_WEEK"),
                        value: formatHours(bestWeek.hours),
                        subtitle: formatDate(bestWeek.startDate),
                        color: .orange
                    )
                }

                if let bestMonth = activeCalculator.bestMonth() {
                    BestRecordRow(
                        icon: "trophy.fill",
                        title: loc("ANALYTICS_BEST_MONTH"),
                        value: formatHours(bestMonth.hours),
                        subtitle: formatMonthYear(bestMonth.date),
                        color: .purple
                    )
                }

                let bestStreak = activeCalculator.bestStreak()
                if bestStreak > 0 {
                    BestRecordRow(
                        icon: "bolt.fill",
                        title: loc("ANALYTICS_BEST_STREAK"),
                        value: "\(bestStreak) " + loc("ANALYTICS_DAYS"),
                        subtitle: loc("ANALYTICS_CONSECUTIVE"),
                        color: .green
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("ANALYTICS_ACTIVITY_CALENDAR"))
                .font(.headline.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

            YearlyHeatmapView(
                year: currentYear,
                heatmapData: activeCalculator.yearlyHeatmapData(for: currentYear)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    // MARK: - Helper Functions

    private func formatHours(_ hours: Double) -> String {
        let totalMinutes = Int(round(hours * 60))

        if totalMinutes >= 60 {
            let wholeHours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60
            if remainingMinutes > 0 {
                return "\(wholeHours)h \(remainingMinutes)m"
            } else {
                return "\(wholeHours)h"
            }
        } else {
            return "\(totalMinutes)m"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

// MARK: - Seeded RNG (stable demo data across renders)

private class SeededRandomGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    func next(in range: ClosedRange<Int>) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let value = Int((state >> 33) % UInt64(range.count))
        return range.lowerBound + value
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let sessions: Int
    let icon: String
    let color: Color
    var isWide: Bool = false
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))

                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

                Text("\(sessions) " + loc(sessions == 1 ? "ANALYTICS_SESSION" : "ANALYTICS_SESSIONS"))
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme).opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }

    private func loc(_ key: String) -> String {
        localization.translate(key, fallback: key)
    }
}

private struct BestRecordRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .fill(color.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
            }

            Spacer()

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top, .bottom])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }
}
