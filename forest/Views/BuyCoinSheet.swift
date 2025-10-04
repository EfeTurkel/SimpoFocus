import SwiftUI

struct BuyCoinSheet: View {
    let coin: Coin
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @Binding var amount: Double
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @State private var errorMessage: String?
    @State private var selectedQuickAmount: Double?
    @State private var showConfetti = false

    private var history: [CoinPriceSnapshot] {
        market.priceHistory[coin.symbol] ?? []
    }

    var body: some View {
        NavigationStack {
            content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("BUY_CLOSE")) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("BUY_CONFIRM")) {
                            handlePurchase()
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let errorMessage {
                    ToastMessage(text: errorMessage)
                }

                CoinDetailHeader(coin: coin, history: history)
                quickAmountSection
                purchaseSummary
            }
            .padding(24)
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
        VStack(spacing: 18) {
            AmountSlider(amount: $amount)
                .environmentObject(localization)

            BuyAmountSection(amount: $amount,
                              price: coin.currentPrice,
                              symbol: coin.symbol)
                .environmentObject(localization)

            StatRow(coin: coin)
                .environmentObject(localization)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func handlePurchase() {
        if let spent = market.buy(symbol: coin.symbol, amount: amount, wallet: wallet) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                let formatted = CurrencyFormatter.abbreviatedCurrency(spent)
                errorMessage = loc("BUY_CONFIRM_SUCCESS", formatted, coin.symbol)
            }
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showConfetti = false
                dismiss()
            }
        } else {
            errorMessage = loc("BUY_INSUFFICIENT")
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
                let count = 120

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

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: coin.iconName)
                    .font(.system(size: 30))
                    .frame(width: 64, height: 64)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                    )
                    .foregroundStyle(.white)

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

                    Text(coin.currentPrice, format: .currency(code: "TRY"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(loc("BUY_MARKET_CAP"))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(CurrencyFormatter.abbreviatedCurrency(coin.marketValue))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
            }

            DetailedSparklineView(history: history)
                .frame(height: 100)
                .padding(.bottom, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}


struct DetailedSparklineView: View {
    let history: [CoinPriceSnapshot]

    var body: some View {
        GeometryReader { proxy in
            let values = history.map { $0.price }
            let points = makePoints(in: proxy.size)
            let fillPath = areaPath(using: points, height: proxy.size.height)
            let linePath = polyline(using: points)
            let gradient = LinearGradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)

            ZStack {
                GridLines()

                if !fillPath.isEmpty {
                    fillPath.fill(gradient)
                }

                linePath
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                if let lastPoint = points.last {
                    Circle()
                        .fill(Color.white)
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
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.vertical, 6)
                    .padding(.leading, 4)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let metrics = GraphMetrics(values: values) {
                    Text(metrics.latestString)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18), in: Capsule())
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
        if values.isEmpty {
            return []
        }

        if values.count == 1 {
            let y = size.height / 2
            return [
                CGPoint(x: 0, y: y),
                CGPoint(x: size.width, y: y)
            ]
        }

        guard let min = values.min(), let max = values.max(), max - min > 0 else {
            return values.enumerated().map { index, _ in
                let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                let y = size.height / 2
                return CGPoint(x: x, y: y)
            }
        }

        return values.enumerated().map { index, value in
            let progress = Double(index) / Double(values.count - 1)
            let normalized = (value - min) / (max - min)
            let x = CGFloat(progress) * size.width
            let y = size.height * CGFloat(1 - normalized)
            return CGPoint(x: x, y: y)
        }
    }

    private func areaPath(using points: [CGPoint], height: CGFloat) -> Path {
        guard points.count > 1 else { return Path() }

        var path = Path()
        path.move(to: CGPoint(x: points.first!.x, y: height))
        points.forEach { path.addLine(to: $0) }
        path.addLine(to: CGPoint(x: points.last!.x, y: height))
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

        var changeString: String {
            String(format: "%+.2f", change)
        }

        var badgeText: String {
            String(format: "%+.2f%%", percentage)
        }

        var changeBadge: String {
            percentage.isFinite ? badgeText : "0%"
        }
    }

    private struct GridLines: View {
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
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
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

        private static let currencyFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "TRY"
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter
        }()

        private func format(_ value: Double) -> String {
            Self.currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
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

    private let options: [Double] = [100, 250, 500, 750]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: options.count), spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selected = option
                        action(option)
                    }
                } label: {
                    Text(formatted(option))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selected == option ? Color.white.opacity(0.9) : Color.white.opacity(0.12))
                        )
                        .foregroundStyle(selected == option ? Color.black : Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₺\(Int(value))"
    }
}

private struct AmountSlider: View {
    @Binding var amount: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc("BUY_AMOUNT_LABEL"))
                    .font(.headline)
                Spacer()
                Text(amount, format: .currency(code: "TRY"))
                    .font(.headline)
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
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct StatRow: View {
    let coin: Coin
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 16) {
            StatTile(title: loc("BUY_STATS_HELD"), value: coin.quantity.formatted(.number.precision(.fractionLength(2))), icon: "cube")
                .environmentObject(localization)
            StatTile(title: loc("BUY_STATS_AVERAGE"), value: coin.averagePrice.formatted(.currency(code: "TRY")), icon: "chart.bar")
                .environmentObject(localization)
            StatTile(title: loc("BUY_STATS_MARKET"), value: CurrencyFormatter.abbreviatedCurrency(coin.marketValue), icon: "chart.line.uptrend.xyaxis")
                .environmentObject(localization)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("BUY_TOTAL_TITLE"))
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                AmountDisplayRow(label: "TRY", value: amount.formatted(.currency(code: "TRY")))
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
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.12), in: Capsule())

            Spacer()

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ToastMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(10)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(text)
                .font(.callout.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.2), radius: 18, y: 10)
        )
    }
}

