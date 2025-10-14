import Foundation

struct PeriodStats {
    let sessions: Int
    let hours: Double
    let coins: Double
}

struct CategoryStats {
    let category: FocusCategory
    let hours: Double
    let percentage: Double
    let sessions: Int
}

final class AnalyticsCalculator {
    private let calendar = Calendar.current
    private let sessionHistory: [FocusSession]
    private let legacyTotalMinutes: Double
    
    init(sessionHistory: [FocusSession], legacyTotalMinutes: Double = 0) {
        self.sessionHistory = sessionHistory
        self.legacyTotalMinutes = legacyTotalMinutes
    }
    
    // MARK: - Period Stats
    
    func todayStats() -> PeriodStats {
        let today = calendar.startOfDay(for: Date())
        return statsForPeriod { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    func weekStats() -> PeriodStats {
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        return statsForPeriod { $0.date >= weekAgo && $0.date <= now }
    }
    
    func monthStats() -> PeriodStats {
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        return statsForPeriod { $0.date >= monthAgo && $0.date <= now }
    }
    
    func yearStats(year: Int) -> PeriodStats {
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            return PeriodStats(sessions: 0, hours: 0, coins: 0)
        }
        return statsForPeriod { $0.date >= startOfYear && $0.date <= endOfYear }
    }
    
    func allTimeStats() -> PeriodStats {
        let historyStats = statsForPeriod { _ in true }
        
        // Only use legacy data if we have no session history (backward compatibility)
        // Otherwise session history already contains all the data
        if sessionHistory.isEmpty && legacyTotalMinutes > 0 {
            let totalHours = legacyTotalMinutes / 60.0
            return PeriodStats(
                sessions: 0,
                hours: totalHours,
                coins: 0
            )
        }
        
        return historyStats
    }
    
    private func statsForPeriod(_ filter: (FocusSession) -> Bool) -> PeriodStats {
        let filtered = sessionHistory.filter(filter)
        let sessions = filtered.count
        let hours = filtered.reduce(0) { $0 + $1.hours }
        let coins = filtered.reduce(0) { $0 + $1.coinsEarned }
        return PeriodStats(sessions: sessions, hours: hours, coins: coins)
    }
    
    // MARK: - Category Breakdown
    
    func categoryBreakdown(for year: Int? = nil) -> [CategoryStats] {
        let sessions = year != nil ? sessionsForYear(year!) : sessionHistory
        let totalHours = sessions.reduce(0) { $0 + $1.hours }
        
        guard totalHours > 0 else { return [] }
        
        var categoryData: [FocusCategory: (hours: Double, count: Int)] = [:]
        
        for session in sessions {
            let current = categoryData[session.category, default: (0, 0)]
            categoryData[session.category] = (current.hours + session.hours, current.count + 1)
        }
        
        return categoryData.map { category, data in
            CategoryStats(
                category: category,
                hours: data.hours,
                percentage: (data.hours / totalHours) * 100,
                sessions: data.count
            )
        }.sorted { $0.hours > $1.hours }
    }
    
    private func sessionsForYear(_ year: Int) -> [FocusSession] {
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            return []
        }
        return sessionHistory.filter { $0.date >= startOfYear && $0.date <= endOfYear }
    }
    
    // MARK: - Best Records
    
    func bestDay() -> (date: Date, hours: Double)? {
        var dailyTotals: [Date: Double] = [:]
        
        for session in sessionHistory {
            let day = calendar.startOfDay(for: session.date)
            dailyTotals[day, default: 0] += session.hours
        }
        
        return dailyTotals.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
    
    func bestWeek() -> (startDate: Date, hours: Double)? {
        var weeklyTotals: [Date: Double] = [:]
        
        for session in sessionHistory {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.date)?.start {
                weeklyTotals[weekStart, default: 0] += session.hours
            }
        }
        
        return weeklyTotals.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
    
    func bestMonth() -> (date: Date, hours: Double)? {
        var monthlyTotals: [Date: Double] = [:]
        
        for session in sessionHistory {
            let components = calendar.dateComponents([.year, .month], from: session.date)
            if let monthStart = calendar.date(from: components) {
                monthlyTotals[monthStart, default: 0] += session.hours
            }
        }
        
        return monthlyTotals.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
    
    func bestStreak() -> Int {
        guard !sessionHistory.isEmpty else { return 0 }
        
        let sortedDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.date) })
            .sorted()
        
        var maxStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for day in sortedDays {
            if let prev = previousDate {
                let daysDiff = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            previousDate = day
        }
        
        return max(maxStreak, currentStreak)
    }
    
    // MARK: - Yearly Heatmap Data
    
    func yearlyHeatmapData(for year: Int) -> [Date: Double] {
        var heatmapData: [Date: Double] = [:]
        
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return heatmapData
        }
        
        // Initialize all days with 0
        var currentDate = startOfYear
        while currentDate <= endOfYear {
            heatmapData[currentDate] = 0
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        
        // Fill in actual session data
        for session in sessionHistory {
            let day = calendar.startOfDay(for: session.date)
            if day >= startOfYear && day <= endOfYear {
                heatmapData[day, default: 0] += session.hours
            }
        }
        
        return heatmapData
    }
}

