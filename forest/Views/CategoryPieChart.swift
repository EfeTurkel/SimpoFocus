import SwiftUI

struct CategoryPieChart: View {
    let categoryStats: [CategoryStats]
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: DS.Padding.screen) {
            ZStack {
                if categoryStats.isEmpty {
                    Circle()
                        .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                        .frame(width: 160, height: 160)
                    VStack(spacing: 4) {
                        Image(systemName: "chart.pie")
                            .font(.title2)
                            .onGlassSecondary()
                        Text("—")
                            .font(.caption)
                            .onGlassSecondary()
                    }
                } else {
                    PieSlices(stats: categoryStats)
                        .frame(width: 160, height: 160)
                }
            }

            VStack(alignment: .leading, spacing: DS.Padding.element) {
                ForEach(categoryStats, id: \.category) { stat in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(stat.category.color)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.category.displayName)
                                .font(.subheadline.weight(.medium))
                                .onGlassPrimary()

                            HStack(spacing: 8) {
                                Text(String(format: "%.1fh", stat.hours))
                                    .font(.caption2)
                                    .onGlassSecondary()

                                Text(String(format: "%.0f%%", stat.percentage))
                                    .font(.caption2.weight(.semibold))
                                    .onGlassSecondary()
                            }
                        }

                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(DS.Animation.defaultSpring, value: categoryStats.map(\.category.displayName))
    }
}

private struct PieSlices: View {
    let stats: [CategoryStats]
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            ForEach(Array(stats.enumerated()), id: \.element.category) { index, stat in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: stat.category.color
                )
            }
            
            Circle()
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
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

