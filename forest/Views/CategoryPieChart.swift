import SwiftUI

struct CategoryPieChart: View {
    let categoryStats: [CategoryStats]
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 24) {
            // Pie Chart
            ZStack {
                if categoryStats.isEmpty {
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
                        .frame(width: 160, height: 160)
                } else {
                    PieSlices(stats: categoryStats)
                        .frame(width: 160, height: 160)
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 12) {
                ForEach(categoryStats, id: \.category) { stat in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(stat.category.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.category.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                            
                            HStack(spacing: 8) {
                                Text(String(format: "%.1fh", stat.hours))
                                    .font(.caption2)
                                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                                
                                Text(String(format: "%.0f%%", stat.percentage))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PieSlices: View {
    let stats: [CategoryStats]
    
    var body: some View {
        ZStack {
            ForEach(Array(stats.enumerated()), id: \.element.category) { index, stat in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: stat.category.color
                )
            }
            
            // Center hole for donut effect
            Circle()
                .fill(Color("LakeNight").opacity(0.7))
                .frame(width: 80, height: 80)
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = stats.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: (previousPercentages / 100.0) * 360.0 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let percentagesUpToThis = stats.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: (percentagesUpToThis / 100.0) * 360.0 - 90)
    }
}

private struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

