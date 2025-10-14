import SwiftUI

struct YearlyHeatmapView: View {
    let year: Int
    let heatmapData: [Date: Double]
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    private let calendar = Calendar.current
    private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { monthOffset in
                        let targetMonth = getTargetMonth(offset: monthOffset)
                        VStack(spacing: 8) {
                            // Month column with heatmap
                            MonthColumn(
                                year: targetMonth.year,
                                month: targetMonth.month,
                                heatmapData: heatmapData,
                                maxHours: getMaxHours()
                            )
                            
                            // Month name and hours below
                            VStack(spacing: 2) {
                                Text(monthNames[targetMonth.month - 1])
                                    .font(.caption2)
                                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                                
                                Text(formatMonthHours(targetMonth.month, year: targetMonth.year))
                                    .font(.caption2)
                                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func getTargetMonth(offset: Int) -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Calculate target month (current month - offset)
        // Reverse order: 0 = 3 months ago, 1 = 2 months ago, 2 = 1 month ago, 3 = current month
        let targetMonth = currentMonth - (3 - offset)
        let targetYear = targetMonth <= 0 ? currentYear - 1 : currentYear
        let adjustedMonth = targetMonth <= 0 ? targetMonth + 12 : targetMonth
        
        return (year: targetYear, month: adjustedMonth)
    }
    
    private func getMaxHours() -> Double {
        let allHours = heatmapData.values
        return allHours.max() ?? 1.0
    }
    
    private func formatMonthHours(_ month: Int, year: Int) -> String {
        let monthData = heatmapData.filter { key, _ in
            calendar.component(.month, from: key) == month && calendar.component(.year, from: key) == year
        }
        let totalHours = monthData.values.reduce(0, +)
        return String(format: "%.0fh", totalHours)
    }
    
    private func monthWidth(for month: Int) -> CGFloat {
        let daysInMonth = calendar.range(of: .day, in: .month, for: dateForMonth(month + 1))?.count ?? 30
        return CGFloat(daysInMonth) * 12 + CGFloat(daysInMonth - 1) * 2
    }
    
    private func dateForMonth(_ month: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }
}

private struct MonthColumn: View {
    let year: Int
    let month: Int
    let heatmapData: [Date: Double]
    let maxHours: Double
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(weeksInMonth(), id: \.self) { week in
                HStack(spacing: 2) {
                    ForEach(week, id: \.self) { day in
                        DayCell(
                            date: day,
                            hours: heatmapData[day] ?? 0,
                            maxHours: maxHours
                        )
                    }
                }
            }
        }
    }
    
    private func weeksInMonth() -> [[Date]] {
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        
        // Add empty cells for days before the first day of the month
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let emptyDays = (firstWeekday - 1) % 7
        for _ in 0..<emptyDays {
            currentWeek.append(Date.distantPast) // Placeholder for empty cells
        }
        
        for day in range {
            let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
            currentWeek.append(date)
            
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        
        // Add remaining days to the last week
        if !currentWeek.isEmpty {
            // Fill remaining slots with empty cells
            while currentWeek.count < 7 {
                currentWeek.append(Date.distantPast) // Placeholder for empty cells
            }
            weeks.append(currentWeek)
        }
        
        return weeks
    }
    
    private func daysInMonth() -> [Date] {
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        return range.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
    }
}

private struct DayCell: View {
    let date: Date
    let hours: Double
    let maxHours: Double
    @State private var showTooltip = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Circle()
            .fill(cellColor)
            .frame(width: 10, height: 10)
            .opacity(isValidDate ? 1 : 0)
            .onTapGesture {
                if isValidDate {
                    showTooltip.toggle()
                }
            }
            .popover(isPresented: $showTooltip, arrowEdge: .top) {
                VStack(spacing: 4) {
                    Text(formattedDate)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    Text(String(format: "%.1fh", hours))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                }
                .padding(8)
                .presentationCompactAdaptation(.popover)
            }
    }
    
    private var isValidDate: Bool {
        // Check if this is a placeholder date (empty cell)
        return date != Date.distantPast
    }
    
            private var cellColor: Color {
                if hours == 0 {
                    return themeManager.currentTheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08)
                }
                
                // GitHub-style intensity based on relative hours
                let intensity = hours / maxHours
                
                if themeManager.currentTheme == .light {
                    // Light mode: use darker colors for better visibility
                    if intensity < 0.1 {
                        return Color.green.opacity(0.4)
                    } else if intensity < 0.3 {
                        return Color.green.opacity(0.6)
                    } else if intensity < 0.6 {
                        return Color.green.opacity(0.8)
                    } else if intensity < 0.9 {
                        return Color.green.opacity(0.9)
                    } else {
                        return Color.green
                    }
                } else {
                    // Dark mode: original colors
                    if intensity < 0.1 {
                        return Color.green.opacity(0.3)
                    } else if intensity < 0.5 {
                        return Color.green.opacity(0.5)
                    } else if intensity < 0.7 {
                        return Color.green.opacity(0.7)
                    } else if intensity < 0.9 {
                        return Color.green.opacity(0.9)
                    } else {
                        return Color.green
                    }
                }
            }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

