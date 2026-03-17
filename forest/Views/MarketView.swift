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
    @State private var refreshPulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                MarketHeader(balance: wallet.balance,
                             title: loc("MARKET_TOTAL_BALANCE", fallback: "Toplam Bakiye"),
                             subtitle: loc("MARKET_OVERVIEW", fallback: "Piyasa değerinin güncel görünümü"))

                VStack(spacing: 0) {
                    ForEach(Array(market.coins.enumerated()), id: \.element.id) { index, coin in
                        CoinCard(coin: coin) {
                            selectedCoin = coin
                        }
                        .environmentObject(market)
                        if index < market.coins.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.card)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .fill(.clear)
                )
                .liquidGlass(.card, edgeMask: [.top])
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
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
                    market.refreshPrices(wallet: wallet)
                    withAnimation(.easeInOut(duration: 0.2)) { refreshPulse.toggle() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.2)) { refreshPulse.toggle() }
                    }
                } label: {
                    Label("\(wallet.marketRefreshCredits)", systemImage: "arrow.clockwise")
                        .scaleEffect(refreshPulse ? 1.08 : 1)
                }
            }
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .onGlassSecondary()

            Text(TokenFormatter.format(balance, maximumFractionDigits: 0))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .onGlassPrimary()

            Text(subtitle)
                .font(.caption2)
                .onGlassSecondary()
        }
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CoinCard: View {
    let coin: Coin
    let action: () -> Void
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

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
            HStack(spacing: 12) {
                Image(systemName: coin.iconName)
                    .font(.title3)
                    .onGlassSecondary()
                    .frame(width: 36, height: 36)
                    .background(Color("ForestGreen").opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(coin.name)
                        .font(.subheadline.weight(.medium))
                        .onGlassPrimary()
                    Text(TokenFormatter.format(coin.currentPrice, maximumFractionDigits: 2))
                        .font(.subheadline.weight(.semibold))
                        .onGlassPrimary()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .onGlassSecondary()
            }
            .padding(.vertical, DS.Padding.section)
        }
        .buttonStyle(.plain)
    }
}


