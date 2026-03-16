import SwiftUI

struct SellCoinSheet: View {
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
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
            ZStack {
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Padding.card) {
                        PickerCard(selectedSymbol: $selectedSymbol, coins: market.coins)

                        if let coin = selectedCoin {
                            CoinOverview(coin: coin, quickSelection: $quickSelection) { value in
                                quantity = min(value, coin.quantity)
                            }
                            .environmentObject(market)

                            GlassSection(cornerRadius: DS.Radius.large) {
                                VStack(spacing: DS.Padding.section) {
                                    QuantitySlider(quantity: $quantity, maxQuantity: coin.quantity, price: coin.currentPrice)
                                        .environmentObject(localization)

                                    SellStatTile(title: loc("SELL_COIN_MARKET_VALUE"), value: CurrencyFormatter.abbreviatedCurrency(coin.marketValue), icon: "chart.line.uptrend.xyaxis")
                                }
                            }
                        }

                        if let errorMessage {
                            HStack(spacing: DS.Padding.element) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(errorMessage)
                                    .font(.subheadline.weight(.medium))
                                    .onGlassPrimary()
                            }
                            .padding(DS.Padding.section)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                    .fill(Color.red.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .offset(y: 8)))
                        }
                    }
                    .padding(.horizontal, DS.Padding.screen)
                    .padding(.vertical, DS.Padding.section)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("SELL_COIN_CLOSE")) { dismiss() }
                        .onGlassPrimary()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("SELL_COIN_SELL")) {
                        handleSell()
                    }
                    .onGlassPrimary()
                }
            }
        }
    }

    private func handleSell() {
        guard let symbol = selectedSymbol else {
            withAnimation(DS.Animation.quickSpring) {
                errorMessage = loc("SELL_COIN_ERROR_SELECT")
            }
            return
        }
        guard quantity > 0 else {
            withAnimation(DS.Animation.quickSpring) {
                errorMessage = loc("SELL_COIN_ERROR_QUANTITY")
            }
            return
        }
        let success = market.sell(symbol: symbol, quantity: quantity, wallet: wallet)
        if success {
            dismiss()
        } else {
            withAnimation(DS.Animation.quickSpring) {
                errorMessage = loc("SELL_COIN_ERROR_INSUFFICIENT")
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
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            Text(loc("SELL_COIN_SELECT"))
                .font(.headline)
                .onGlassPrimary()
            Picker("Coin", selection: $selectedSymbol) {
                Text(loc("SELL_COIN_SELECT_PLACEHOLDER")).tag(String?.none)
                ForEach(coins) { coin in
                    Text("\(coin.symbol) - \(coin.quantity, format: .number.precision(.fractionLength(2))) \(loc("SELL_COIN_QUANTITY_UNIT"))")
                        .tag(String?.some(coin.symbol))
                }
            }
            .pickerStyle(.menu)
            .tint(Color("ForestGreen"))
        }
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
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
    @Environment(\.colorScheme) private var colorScheme

    private var quickOptions: [Double] {
        let base = coin.quantity
        return [0.1, 0.25, 0.5, 1].map { base * $0 }.filter { $0 > 0 }
    }

    var body: some View {
        VStack(spacing: DS.Padding.section) {
            HStack(alignment: .center, spacing: DS.Padding.section) {
                Image(systemName: coin.iconName)
                    .font(.system(size: 34))
                    .frame(width: 72, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
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
                HStack(spacing: DS.Padding.element) {
                    ForEach(quickOptions, id: \.self) { option in
                        let isSelected = quickSelection == option
                        Button {
                            withAnimation(DS.Animation.quickSpring) {
                                quickSelection = option
                                action(option)
                            }
                        } label: {
                            Text(option, format: .number.precision(.fractionLength(2)))
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 10)
                                .padding(.horizontal, DS.Padding.section)
                                .background(
                                    RoundedRectangle(cornerRadius: DS.Radius.medium - 2, style: .continuous)
                                        .fill(themeManager.currentTheme.chipBackground(selected: isSelected, for: colorScheme))
                                )
                                .foregroundStyle(themeManager.currentTheme.chipTextColor(selected: isSelected, for: colorScheme))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
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

private struct QuantitySlider: View {
    @Binding var quantity: Double
    let maxQuantity: Double
    let price: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            HStack {
                Text(loc("SELL_COIN_QUANTITY"))
                    .font(.headline)
                    .onGlassPrimary()
                Spacer()
                Text(quantity, format: .number.precision(.fractionLength(4)))
                    .font(.headline)
                    .onGlassPrimary()
            }
            Slider(value: $quantity, in: 0...maxQuantity, step: max(maxQuantity / 20, 0.01))
                .tint(Color("ForestGreen"))

            if price > 0 {
                Text("≈ \((quantity * price), format: .currency(code: "TRY"))")
                    .font(.subheadline.weight(.medium))
                    .onGlassSecondary()
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct SellStatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: DS.Padding.element) {
            Image(systemName: icon)
                .font(.headline)
                .onGlassPrimary()
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .onGlassPrimary()
                Text(title)
                    .font(.caption)
                    .onGlassSecondary()
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DS.Padding.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.all])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }
}
