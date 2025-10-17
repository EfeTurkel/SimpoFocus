import SwiftUI

struct SellCoinSheet: View {
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSymbol: String?
    @State private var quantity: Double = 0
    @State private var errorMessage: String?
    @State private var quickSelection: Double?

    init(selectedCoin: Coin? = nil) {
        _selectedSymbol = State(initialValue: selectedCoin?.symbol)
    }

    private var selectedCoin: Coin? {
        guard let symbol = selectedSymbol else { return nil }
        return market.coins.first(where: { $0.symbol == symbol })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PickerCard(selectedSymbol: $selectedSymbol, coins: market.coins)

                    if let coin = selectedCoin {
                        CoinOverview(coin: coin, quickSelection: $quickSelection) { value in
                            quantity = min(value, coin.quantity)
                        }
                        .environmentObject(market)
                        .environmentObject(market)

                        VStack(spacing: 18) {
                            QuantitySlider(quantity: $quantity, maxQuantity: coin.quantity, price: coin.currentPrice)
                                .environmentObject(localization)

                            StatTile(title: loc("SELL_COIN_MARKET_VALUE"), value: CurrencyFormatter.abbreviatedCurrency(coin.marketValue), icon: "chart.line.uptrend.xyaxis")
                        }
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.clear)
                        )
                        .liquidGlass(.card, edgeMask: [.top, .bottom])
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("SELL_COIN_CLOSE")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("SELL_COIN_SELL")) {
                        guard let symbol = selectedSymbol else {
                            errorMessage = loc("SELL_COIN_ERROR_SELECT")
                            return
                        }
                        guard quantity > 0 else {
                            errorMessage = loc("SELL_COIN_ERROR_QUANTITY")
                            return
                        }
                        let success = market.sell(symbol: symbol, quantity: quantity, wallet: wallet)
                        if success {
                            dismiss()
                        } else {
                            errorMessage = loc("SELL_COIN_ERROR_INSUFFICIENT")
                        }
                    }
                }
            }
        }
    }
    
    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct PickerCard: View {
    @Binding var selectedSymbol: String?
    let coins: [Coin]
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("SELL_COIN_SELECT"))
                .font(.headline)
            Picker("Coin", selection: $selectedSymbol) {
                Text(loc("SELL_COIN_SELECT_PLACEHOLDER")).tag(String?.none)
                ForEach(coins) { coin in
                    Text("\(coin.symbol) - \(coin.quantity, format: .number.precision(.fractionLength(2))) adet")
                        .tag(String?.some(coin.symbol))
                }
            }
            .pickerStyle(.menu)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            themeManager.currentTheme == .light
                ? LinearGradient(colors: [Color("LakeBlue").opacity(0.8), Color("LakeNight").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color("LakeBlue"), Color("LakeNight")], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .onGlassPrimary()
    }
    
    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct CoinOverview: View {
    let coin: Coin
    @Binding var quickSelection: Double?
    let action: (Double) -> Void
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared

    private var quickOptions: [Double] {
        let base = coin.quantity
        return [0.1, 0.25, 0.5, 1].map { base * $0 }.filter { $0 > 0 }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: coin.iconName)
                    .font(.system(size: 34))
                    .frame(width: 72, height: 72)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .onGlassPrimary()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(coin.symbol)
                            .font(.headline)
                            .lineLimit(1)
                            .layoutPriority(1)
                        if let stats = DetailedSparklineView.stats(for: market.priceHistory[coin.symbol] ?? []) {
                            Text(stats.changeBadge)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(stats.change >= 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2), in: Capsule())
                                .foregroundStyle(stats.change >= 0 ? Color.green : Color.red)
                        }
                    }
                    Text(loc("SELL_COIN_AVAILABLE", coin.quantity.formatted(.number.precision(.fractionLength(2)))))
                        .font(.caption)
                        .onGlassSecondary()
                    Text(coin.currentPrice, format: .currency(code: "TRY"))
                        .font(.headline)
                        .onGlassPrimary()
                }
                .onGlassPrimary()

                Spacer()
            }

            DetailedSparklineView(history: market.priceHistory[coin.symbol] ?? [])
                .frame(height: 100)
                .padding(.bottom, 4)

            if !quickOptions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(quickOptions, id: \.self) { option in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                quickSelection = option
                                action(option)
                            }
                        } label: {
                            Text(option, format: .number.precision(.fractionLength(2)))
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(quickSelection == option ? Color.white.opacity(0.9) : Color.white.opacity(0.12))
                                )
                                .foregroundStyle(quickSelection == option ? Color.black : Color.white.opacity(0.85))
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    themeManager.currentTheme == .light
                        ? LinearGradient(colors: [Color("ForestGreen").opacity(0.8), Color("LakeBlue").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        )
    }
    
    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct QuantitySlider: View {
    @Binding var quantity: Double
    let maxQuantity: Double
    let price: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc("SELL_COIN_QUANTITY"))
                    .font(.headline)
                Spacer()
                Text(quantity, format: .number.precision(.fractionLength(4)))
                    .font(.headline)
            }
            Slider(value: $quantity, in: 0...maxQuantity, step: max(maxQuantity / 20, 0.01))
                .tint(Color("ForestGreen"))

            if price > 0 {
                Text("≈ \((quantity * price), format: .currency(code: "TRY"))")
                    .font(.subheadline.weight(.medium))
            }
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .onGlassSecondary()
            }
        }
        .onGlassPrimary()
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

