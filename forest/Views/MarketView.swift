import SwiftUI

struct MarketView: View {
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCoin: Coin?
    @State private var amount: Double = 100
    @State private var showingSellSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                MarketHeader(balance: wallet.balance,
                             title: loc("MARKET_TOTAL_BALANCE", fallback: "Toplam Bakiye"),
                             subtitle: loc("MARKET_OVERVIEW", fallback: "Piyasa değerinin güncel görünümü"))

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(market.coins) { coin in
                        CoinCard(coin: coin) {
                            selectedCoin = coin
                        }
                        .environmentObject(market)
                    }
                }
                .padding(18)
                .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.8), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
                )
            }
            .padding(24)
        }
        .scrollIndicators(.never)
        .sheet(item: $selectedCoin) { coin in
            BuyCoinSheet(coin: coin, amount: $amount)
        }
        .sheet(isPresented: $showingSellSheet) {
            SellCoinSheet()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSellSheet = true
                } label: {
                    Label(loc("MARKET_SELL", fallback: "Sat"), systemImage: "chart.line.downtrend.xyaxis")
                }
            }
        }
        .onAppear { market.refreshPrices() }
    }
}

private extension MarketView {
    func loc(_ key: String, fallback: String? = nil, arguments: CVarArg...) -> String {
        localization.translate(key, fallback: fallback, arguments: arguments)
    }
}

private struct MarketHeader: View {
    let balance: Double
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))

            Text(balance, format: .currency(code: "TRY"))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 18, y: 10)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        )
    }
}

private struct CoinCard: View {
    let coin: Coin
    let action: () -> Void
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    private var history: [CoinPriceSnapshot] {
        market.priceHistory[coin.symbol] ?? []
    }

    private var stats: MiniSparkline.Stats? {
        MiniSparkline.Stats(history: history)
    }

    private var descriptionText: String {
        let key: String
        switch coin.symbol {
        case "LEAF": key = "MARKET_COIN_DESC_LEAF"
        case "ROOT": key = "MARKET_COIN_DESC_ROOT"
        case "BARK": key = "MARKET_COIN_DESC_BARK"
        default: key = "MARKET_COIN_DESC_DEFAULT"
        }
        return localization.translate(key, fallback: key)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: coin.iconName)
                    .font(.title2)
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    .frame(width: 54, height: 54)
                    .background(themeManager.currentTheme.getCardBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(coin.name)
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    Text(coin.currentPrice, format: .currency(code: "TRY"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
            }
            .padding(18)
            .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.5), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }
}

private struct ChangeBadge: View {
    let percentage: Double

    private var formatted: String {
        String(format: "%+.2f%%", percentage)
    }

    private var isPositive: Bool { percentage >= 0 }

    var body: some View {
        Text(formatted)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((isPositive ? Color.green : Color.red).opacity(0.16), in: Capsule())
            .foregroundStyle(isPositive ? Color.green : Color.red)
    }
}

private struct MiniSparkline: View {
    let history: [CoinPriceSnapshot]
    let accent: Color
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let points = makePoints(in: proxy.size)
            let color = accent.opacity(0.85)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.3))

                if points.count > 1 {
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        points.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    if let last = points.last {
                        Circle()
                            .strokeBorder(color.opacity(0.4), lineWidth: 2)
                            .background(Circle().fill(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme)))
                            .frame(width: 6, height: 6)
                            .position(last)
                    }
                }
            }
        }
    }

    func makePoints(in size: CGSize) -> [CGPoint] {
        let values = history.map { $0.price }
        guard values.count > 1 else {
            return [CGPoint(x: 0, y: size.height / 2), CGPoint(x: size.width, y: size.height / 2)]
        }

        guard let min = values.min(), let max = values.max(), max - min > 0 else {
            return values.enumerated().map { index, _ in
                let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                return CGPoint(x: x, y: size.height / 2)
            }
        }

        return values.enumerated().map { index, value in
            let progress = CGFloat(index) / CGFloat(values.count - 1)
            let normalized = (value - min) / (max - min)
            let x = progress * size.width
            let y = size.height * CGFloat(1 - normalized)
            return CGPoint(x: x, y: y)
        }
    }

    struct Stats {
        let percentage: Double

        init?(history: [CoinPriceSnapshot]) {
            guard let first = history.first?.price, let last = history.last?.price, first > 0 else { return nil }
            percentage = ((last - first) / first) * 100
        }

        static func historyAvailable(_ history: [CoinPriceSnapshot]) -> Bool {
            history.count > 1
        }
    }
}

