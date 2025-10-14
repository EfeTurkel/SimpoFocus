import SwiftUI

struct YearlyAnalyticsView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var calculator: AnalyticsCalculator {
        AnalyticsCalculator(
            sessionHistory: timer.sessionHistory,
            legacyTotalMinutes: timer.totalFocusMinutes
        )
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Quick stats cards
                quickStatsGrid
                
                // Category breakdown
                categorySection
                
                // Best records
                bestRecordsSection
                
                // Yearly heatmap
                heatmapSection
            }
            .padding(24)
        }
        .background(
            themeManager.currentTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
        )
    }
    
    private var headerView: some View {
        HStack {
            Text(loc("ANALYTICS_TITLE"))
                .font(.title.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
            
            Spacer()
            
            Text(String(format: "%d", currentYear))
                .font(.title3.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
        }
    }
    
    private var quickStatsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatCard(
                    title: loc("ANALYTICS_TODAY"),
                    value: formatHours(calculator.todayStats().hours),
                    sessions: calculator.todayStats().sessions,
                    icon: "sun.max.fill",
                    color: .orange
                )
                .environmentObject(localization)
                
                StatCard(
                    title: loc("ANALYTICS_WEEK"),
                    value: formatHours(calculator.weekStats().hours),
                    sessions: calculator.weekStats().sessions,
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                .environmentObject(localization)
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: loc("ANALYTICS_MONTH"),
                    value: formatHours(calculator.monthStats().hours),
                    sessions: calculator.monthStats().sessions,
                    icon: "calendar",
                    color: .purple
                )
                .environmentObject(localization)
                
                StatCard(
                    title: loc("ANALYTICS_YEAR"),
                    value: formatHours(calculator.yearStats(year: currentYear).hours),
                    sessions: calculator.yearStats(year: currentYear).sessions,
                    icon: "chart.bar.fill",
                    color: .green
                )
                .environmentObject(localization)
            }
            
            StatCard(
                title: loc("ANALYTICS_ALL_TIME"),
                value: formatHours(calculator.allTimeStats().hours),
                sessions: calculator.allTimeStats().sessions,
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
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
            
            let categoryStats = calculator.categoryBreakdown(for: currentYear)
            
            if categoryStats.isEmpty {
                Text(loc("ANALYTICS_NO_DATA"))
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                CategoryPieChart(categoryStats: categoryStats)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
        )
    }
    
    private var bestRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("ANALYTICS_BEST_RECORDS"))
                .font(.headline.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
            
            VStack(spacing: 12) {
                if let bestDay = calculator.bestDay() {
                    BestRecordRow(
                        icon: "star.fill",
                        title: loc("ANALYTICS_BEST_DAY"),
                        value: formatHours(bestDay.hours),
                        subtitle: formatDate(bestDay.date),
                        color: .yellow
                    )
                }
                
                if let bestWeek = calculator.bestWeek() {
                    BestRecordRow(
                        icon: "flame.fill",
                        title: loc("ANALYTICS_BEST_WEEK"),
                        value: formatHours(bestWeek.hours),
                        subtitle: formatDate(bestWeek.startDate),
                        color: .orange
                    )
                }
                
                if let bestMonth = calculator.bestMonth() {
                    BestRecordRow(
                        icon: "trophy.fill",
                        title: loc("ANALYTICS_BEST_MONTH"),
                        value: formatHours(bestMonth.hours),
                        subtitle: formatMonthYear(bestMonth.date),
                        color: .purple
                    )
                }
                
                let bestStreak = calculator.bestStreak()
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
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
        )
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("ANALYTICS_ACTIVITY_CALENDAR"))
                .font(.headline.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
            
            YearlyHeatmapView(
                year: currentYear,
                heatmapData: calculator.yearlyHeatmapData(for: currentYear)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
        )
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
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                
                Text("\(sessions) " + loc(sessions == 1 ? "ANALYTICS_SESSION" : "ANALYTICS_SESSIONS"))
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme).opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
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
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
            }
            
            Spacer()
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
        )
    }
}

