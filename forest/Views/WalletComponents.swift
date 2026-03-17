import SwiftUI

struct SummaryChip: View {
    let title: String
    let value: String
    let icon: String
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DS.Typography.caption)
                Text(loc(title))
                    .font(DS.Typography.micro)
                    .onGlassSecondary()
            }
        }
        .onGlassPrimary()
        .padding(.vertical, 10)
        .padding(.horizontal, DS.Padding.section)
        .background(Color("ForestGreen").opacity(0.08), in: Capsule())
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

struct CoinsMarketSection: View {
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var selectedCoin: Coin?
    @Binding var showingSellSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            HStack {
                Text(loc("MARKET_COINS"))
                    .font(DS.Typography.cardTitle)
                    .onGlassPrimary()

                Spacer()

                Button {
                    showingSellSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(loc("MARKET_SELL"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.red.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                ForEach(market.coins) { coin in
                    CoinBuyCard(coin: coin) {
                        selectedCoin = coin
                    }
                }
            }
        }
        .padding(DS.Padding.card)
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

struct CoinBuyCard: View {
    let coin: Coin
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Padding.section) {
                Image(systemName: coin.iconName)
                    .font(.title3)
                    .onGlassSecondary()
                    .frame(width: 40, height: 40)
                    .background(Color("ForestGreen").opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(coin.name)
                        .font(.headline)
                        .onGlassPrimary()
                    Text(coin.currentPrice, format: .currency(code: "TRY"))
                        .font(.title3.weight(.semibold))
                        .onGlassPrimary()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .onGlassSecondary()
            }
            .padding(DS.Padding.section)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct WalletSummaryCard: View {
    let balance: Double
    let passiveBoost: Double
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.section) {
            Text(loc("WALLET_TITLE"))
                .font(DS.Typography.caption)
                .onGlassSecondary()

            Text(balance, format: .currency(code: "TRY"))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .onGlassPrimary()

            HStack(spacing: DS.Padding.element) {
                SummaryChip(title: "WALLET_PASSIVE_CHIP", value: "+\(Int(passiveBoost * 100))%", icon: "sparkles")
                SummaryChip(title: "WALLET_STAKED_CHIP", value: wallet.stakedBalance.formatted(.currency(code: "TRY")), icon: "lock.fill")
            }

            PassiveIncomeRow(passiveBoost: passiveBoost, accruedInterest: wallet.earnedFromInterest)
        }
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

struct PassiveIncomeRow: View {
    let passiveBoost: Double
    let accruedInterest: Double
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc("WALLET_PASSIVE_TITLE"))
                .font(.footnote.weight(.medium))
                .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))

            HStack(spacing: 12) {
                Label(loc("WALLET_PASSIVE_RATE", Int(passiveBoost * 100)), systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                Spacer()
                Text(accruedInterest, format: .currency(code: "TRY"))
                    .font(.headline)
            }
            .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
        }
        .padding(DS.Padding.section)
        .background(Color("ForestGreen").opacity(0.06), in: RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

struct TransactionsSection: View {
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("WALLET_TRANSACTIONS"))
                .font(.title3.bold())
                .onGlassPrimary()

            if wallet.transactions.isEmpty {
                EmptyTransactionsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(wallet.transactions) { transaction in
                        TransactionCard(transaction: transaction)
                    }
                }
            }
        }
        .padding(DS.Padding.card)
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

struct TransactionCard: View {
    let transaction: WalletTransaction
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(alignment: .top, spacing: DS.Padding.section) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(localizedDescription)
                    .font(DS.Typography.cardTitle)
                    .onGlassPrimary()
                Text(transaction.date, style: .time)
                    .font(DS.Typography.micro)
                    .onGlassSecondary()
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "TRY"))
                .font(DS.Typography.cardTitle)
                .foregroundStyle(transaction.amount >= 0 ? .green : .red)
        }
        .padding(.vertical, DS.Padding.element)
    }

    private var iconName: String {
        switch transaction.type {
        case .earned: return "arrow.down.circle.fill"
        case .spent: return "arrow.up.circle.fill"
        case .market: return "bitcoinsign.circle.fill"
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case .earned: return .green
        case .spent: return .orange
        case .market: return .blue
        }
    }

    private var localizedDescription: String {
        if transaction.description.starts(with: "TXN_") {
            return localization.translate(transaction.description)
        }
        if let mapped = mappedLegacyDescription() {
            return mapped
        }
        return transaction.description
    }

    private func mappedLegacyDescription() -> String? {
        let text = transaction.description
        switch text {
        case "Faiz kazancı", "Faiz hesap bakiyesi", "Interest earned", "Interest gain", "Zinsen gutgeschrieben", "Zinsen erhalten":
            return localization.translate("TXN_INTEREST_GAIN")
        case "Faize yatırıldı", "Deposited to interest", "In Zinskonto eingezahlt":
            return localization.translate("TXN_STAKE_DEPOSIT")
        case "Faiz hesabından çekildi", "Withdrawn from interest", "Vom Zinskonto abgehoben":
            return localization.translate("TXN_STAKE_WITHDRAW")
        case "Pomodoro ödülü", "Pomodoro reward", "Pomodoro-Belohnung":
            return localization.translate("TXN_REWARD_POMODORO")
        default:
            break
        }
        if text.hasPrefix("Bought ") {
            return localization.translate("TXN_MARKET_BUY", arguments: [text.replacingOccurrences(of: "Bought ", with: "", options: [.anchored])])
        }
        if text.hasPrefix("Sold ") {
            return localization.translate("TXN_MARKET_SELL", arguments: [text.replacingOccurrences(of: "Sold ", with: "", options: [.anchored])])
        }
        if text.hasPrefix("Gekauft ") {
            return localization.translate("TXN_MARKET_BUY", arguments: [text.replacingOccurrences(of: "Gekauft ", with: "", options: [.anchored])])
        }
        if text.hasPrefix("Verkauft ") {
            return localization.translate("TXN_MARKET_SELL", arguments: [text.replacingOccurrences(of: "Verkauft ", with: "", options: [.anchored])])
        }
        if text.hasSuffix("temasını açtı") {
            return localization.translate("TXN_THEME_UNLOCK", arguments: [text.replacingOccurrences(of: " temasını açtı", with: "")])
        }
        if text.hasSuffix("theme unlocked") {
            return localization.translate("TXN_THEME_UNLOCK", arguments: [text.replacingOccurrences(of: " theme unlocked", with: "")])
        }
        if text.hasSuffix("Thema freigeschaltet") {
            return localization.translate("TXN_THEME_UNLOCK", arguments: [text.replacingOccurrences(of: " Thema freigeschaltet", with: "")])
        }
        return nil
    }
}

struct EmptyTransactionsView: View {
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title)
                .onGlassSecondary()
            Text(loc("WALLET_EMPTY_TRANSACTIONS"))
                .onGlassSecondary()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}
