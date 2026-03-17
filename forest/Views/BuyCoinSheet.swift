import SwiftUI

struct BuyCoinSheet: View {
    let coin: Coin
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @Binding var amount: Double
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var errorMessage: String?
    @State private var selectedQuickAmount: Double?
    @State private var showConfetti = false

    private var history: [CoinPriceSnapshot] {
        market.priceHistory[coin.symbol] ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                content
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("BUY_CLOSE")) { dismiss() }
                        .onGlassPrimary()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("BUY_CONFIRM")) {
                        handlePurchase()
                    }
                    .onGlassPrimary()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.Padding.card) {
                if let errorMessage {
                    ToastMessage(text: errorMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                CoinDetailHeader(coin: coin, history: history)
                quickAmountSection
                purchaseSummary
            }
            .padding(.horizontal, DS.Padding.screen)
            .padding(.vertical, DS.Padding.section)
        }
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
    }

    private var quickAmountSection: some View {
        QuickAmountRow(selected: $selectedQuickAmount) { value in
            amount = value
        }
    }

    private var purchaseSummary: some View {
        GlassSection(cornerRadius: DS.Radius.large) {
            VStack(spacing: DS.Padding.section) {
                AmountSlider(amount: $amount)
                    .environmentObject(localization)

                BuyAmountSection(amount: $amount,
                                  price: coin.currentPrice,
                                  symbol: coin.symbol)
                    .environmentObject(localization)

                StatRow(coin: coin)
                    .environmentObject(localization)
            }
        }
    }

    private func handlePurchase() {
        if let spent = market.buy(symbol: coin.symbol, amount: amount, wallet: wallet) {
            withAnimation(DS.Animation.quickSpring) {
                let formatted = TokenFormatter.abbreviatedTokens(spent)
                errorMessage = loc("BUY_CONFIRM_SUCCESS", formatted, coin.symbol)
            }
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showConfetti = false }
                dismiss()
            }
        } else {
            withAnimation(DS.Animation.quickSpring) {
                errorMessage = loc("BUY_INSUFFICIENT")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { errorMessage = nil }
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct ConfettiView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let colors: [Color] = [.pink, .green, .orange, .yellow, .blue, .purple]
                let t = timeline.date.timeIntervalSinceReferenceDate
                let count = 30

                for index in 0..<count {
                    var seed = SystemRandomNumberGenerator()
                    let progress = (Double(index) / Double(count)) + t.truncatingRemainder(dividingBy: 1)
                    let x = Double(index % 10) / 10.0 * size.width + Double.random(in: -6...6, using: &seed)
                    let y = progress * size.height
                    let rect = CGRect(x: x, y: y, width: 6, height: 12)
                    let shape = Path(roundedRect: rect, cornerRadius: 3)
                    context.fill(shape, with: .color(colors[index % colors.count].opacity(0.8)))
                }
            }
        }
        .frame(height: 220)
    }
}

private struct CoinDetailHeader: View {
    let coin: Coin
    let history: [CoinPriceSnapshot]
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DS.Padding.section) {
            HStack(alignment: .center, spacing: DS.Padding.section) {
                Image(systemName: coin.iconName)
                    .font(.system(size: 30))
                    .frame(width: 64, height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.medium - 2, style: .continuous)
                            .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium - 2, style: .continuous)
                            .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
                    )
                    .onGlassPrimary()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(coin.symbol)
                            .font(.headline)
                            .lineLimit(1)
                            .layoutPriority(1)

                        if let stats = DetailedSparklineView.stats(for: history) {
                            Text(stats.changeBadge)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(stats.change >= 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2), in: Capsule())
                                .foregroundStyle(stats.change >= 0 ? Color.green : Color.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(TokenFormatter.format(coin.currentPrice, maximumFractionDigits: 2))
                        .font(.title3.weight(.semibold))
                        .onGlassPrimary()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(loc("BUY_MARKET_CAP"))
                        .font(.caption2)
                        .onGlassSecondary()
                    Text(TokenFormatter.abbreviatedTokens(coin.marketValue))
                        .font(.subheadline.weight(.medium))
                        .onGlassPrimary()
                }
            }

            DetailedSparklineView(history: history)
                .frame(height: 100)
                .padding(.bottom, 4)
        }
        .padding(DS.Padding.screen)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}


struct DetailedSparklineView: View {
    let history: [CoinPriceSnapshot]
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let values = history.map { $0.price }
            let points = makePoints(in: proxy.size)
            let fillPath = areaPath(using: points, height: proxy.size.height)
            let linePath = polyline(using: points)
            let gradient = LinearGradient(colors: [themeManager.currentTheme.glassPrimaryText(for: colorScheme).opacity(0.4), themeManager.currentTheme.glassPrimaryText(for: colorScheme).opacity(0.05)], startPoint: .top, endPoint: .bottom)

            ZStack {
                GridLines(themeManager: themeManager, colorScheme: colorScheme)

                if !fillPath.isEmpty {
                    fillPath.fill(gradient)
                }

                linePath
                    .stroke(themeManager.currentTheme.glassPrimaryText(for: colorScheme), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                if let lastPoint = points.last {
                    Circle()
                        .fill(themeManager.currentTheme.glassPrimaryText(for: colorScheme))
                        .frame(width: 8, height: 8)
                        .position(lastPoint)
                }
            }
            .overlay(alignment: .leading) {
                if let metrics = GraphMetrics(values: values) {
                    VStack {
                        Text(metrics.maxString)
                        Spacer()
                        if metrics.midString != metrics.maxString {
                            Text(metrics.midString)
                            Spacer()
                        }
                        Text(metrics.minString)
                    }
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.glassSecondaryText(for: colorScheme))
                    .padding(.vertical, 6)
                    .padding(.leading, 4)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let metrics = GraphMetrics(values: values) {
                    Text(metrics.latestString)
                        .font(.caption2.weight(.semibold))
                        .onGlassPrimary()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.getCardBackground(for: colorScheme), in: Capsule())
                        .padding([.top, .trailing], 8)
                }
            }
        }
    }

    static func stats(for history: [CoinPriceSnapshot]) -> Stats? {
        Stats(history: history)
    }

    private func makePoints(in size: CGSize) -> [CGPoint] {
        let values = history.map { $0.price }
        if values.isEmpty { return [] }

        if values.count == 1 {
            let y = size.height / 2
            return [CGPoint(x: 0, y: y), CGPoint(x: size.width, y: y)]
        }

        guard let min = values.min(), let max = values.max(), max - min > 0 else {
            return values.enumerated().map { index, _ in
                let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                return CGPoint(x: x, y: size.height / 2)
            }
        }

        return values.enumerated().map { index, value in
            let progress = Double(index) / Double(values.count - 1)
            let normalized = (value - min) / (max - min)
            return CGPoint(x: CGFloat(progress) * size.width, y: size.height * CGFloat(1 - normalized))
        }
    }

    private func areaPath(using points: [CGPoint], height: CGFloat) -> Path {
        guard points.count > 1 else { return Path() }
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }
        path.move(to: CGPoint(x: first.x, y: height))
        points.forEach { path.addLine(to: $0) }
        path.addLine(to: CGPoint(x: last.x, y: height))
        path.closeSubpath()
        return path
    }

    private func polyline(using points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        return path
    }

    struct Stats {
        let latest: Double
        let change: Double
        let percentage: Double

        init?(history: [CoinPriceSnapshot]) {
            guard let first = history.first?.price, let last = history.last?.price else { return nil }
            latest = last
            change = last - first
            percentage = first > 0 ? (change / first) * 100 : 0
        }

        var changeString: String { String(format: "%+.2f", change) }
        var badgeText: String { String(format: "%+.2f%%", percentage) }
        var changeBadge: String { percentage.isFinite ? badgeText : "0%" }
    }

    private struct GridLines: View {
        let themeManager: ThemeManager
        let colorScheme: ColorScheme

        var body: some View {
            GeometryReader { proxy in
                Path { path in
                    let stepY = proxy.size.height / 3
                    for index in 0...3 {
                        let y = stepY * CGFloat(index)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(themeManager.currentTheme.glassSecondaryText(for: colorScheme).opacity(0.2), lineWidth: 0.5)
            }
        }
    }

    private struct GraphMetrics {
        let min: Double
        let max: Double
        let latest: Double

        init?(values: [Double]) {
            guard let min = values.min(), let max = values.max() else { return nil }
            self.min = min
            self.max = max
            self.latest = values.last ?? max
        }

        private func format(_ value: Double) -> String {
            TokenFormatter.format(value, maximumFractionDigits: 2)
        }

        var maxString: String { format(max) }
        var minString: String { format(min) }
        var midString: String { format((max + min) / 2) }
        var latestString: String { format(latest) }
    }
}

private struct QuickAmountRow: View {
    @Binding var selected: Double?
    let action: (Double) -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private let options: [Double] = [100, 250, 500, 750]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Padding.element), count: options.count), spacing: DS.Padding.element) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(DS.Animation.quickSpring) {
                        selected = option
                        action(option)
                    }
                } label: {
                    let isSelected = selected == option
                    let bgFill = themeManager.currentTheme.chipBackground(selected: isSelected, for: colorScheme)
                    let textColor = themeManager.currentTheme.chipTextColor(selected: isSelected, for: colorScheme)
                    Text(formatted(option))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.medium - 2, style: .continuous)
                                .fill(bgFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.medium - 2, style: .continuous)
                                .stroke(themeManager.currentTheme.glassStroke(for: colorScheme).opacity(0.6), lineWidth: 0.6)
                        )
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        TokenFormatter.format(value, maximumFractionDigits: 0)
    }
}

private struct AmountSlider: View {
    @Binding var amount: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            HStack {
                Text(loc("BUY_AMOUNT_LABEL"))
                    .font(.headline)
                    .onGlassPrimary()
                Spacer()
                Text(TokenFormatter.format(amount, maximumFractionDigits: 0))
                    .font(.headline)
                    .onGlassPrimary()
            }

            Slider(value: $amount, in: 50...1000, step: 10)
                .tint(Color("ForestGreen"))
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .onGlassSecondary()
        }
        .onGlassPrimary()
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Padding.element)
    }
}

private struct StatRow: View {
    let coin: Coin
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: DS.Padding.section) {
            StatTile(title: loc("BUY_STATS_HELD"), value: coin.quantity.formatted(.number.precision(.fractionLength(2))), icon: "cube")
            StatTile(title: loc("BUY_STATS_AVERAGE"), value: TokenFormatter.format(coin.averagePrice, maximumFractionDigits: 2), icon: "chart.bar")
            StatTile(title: loc("BUY_STATS_MARKET"), value: TokenFormatter.abbreviatedTokens(coin.marketValue), icon: "chart.line.uptrend.xyaxis")
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct BuyAmountSection: View {
    @Binding var amount: Double
    let price: Double
    let symbol: String
    @EnvironmentObject private var localization: LocalizationManager

    private var tokenQuantity: Double {
        guard price > 0 else { return 0 }
        return amount / price
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            Text(loc("BUY_TOTAL_TITLE"))
                .font(.footnote.weight(.medium))
                .onGlassSecondary()

            VStack(spacing: DS.Padding.element) {
                AmountDisplayRow(label: "Sim", value: TokenFormatter.format(amount, maximumFractionDigits: 0))
                AmountDisplayRow(label: symbol, value: tokenQuantity.formatted(.number.precision(.fractionLength(4))))
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct AmountDisplayRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: DS.Padding.element) {
            Text(label)
                .font(.caption.weight(.semibold))
                .onGlassPrimary()
                .padding(.vertical, 6)
                .padding(.horizontal, DS.Padding.element)

            Spacer()

            Text(value)
                .font(.title3.weight(.semibold))
                .onGlassPrimary()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, DS.Padding.section)
        .padding(.vertical, DS.Padding.element)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.all])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }
}

private struct ToastMessage: View {
    let text: String
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: DS.Padding.element) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.small + 2, style: .continuous)
                        .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                )

            Text(text)
                .font(.callout.weight(.semibold))
                .lineLimit(2)
                .onGlassPrimary()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Padding.section)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(LinearGradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}
