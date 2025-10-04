import SwiftUI

private struct SummaryChip: View {
    let title: String
    let value: String
    let icon: String
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(loc(title))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct PortfolioSection: View {
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var selectedCoin: Coin?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc("WALLET_ASSETS"))
                .font(.title3.bold())
                .foregroundStyle(.white)

            if market.coins.allSatisfy({ $0.quantity == 0 }) {
                Text(loc("WALLET_EMPTY_ASSETS"))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(market.coins.filter { $0.quantity > 0 }) { coin in
                        AssetRow(coin: coin, totalValue: coin.quantity * coin.currentPrice) {
                            selectedCoin = coin
                        }
                        .environmentObject(localization)
                    }
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct AssetRow: View {
    let coin: Coin
    let totalValue: Double
    let action: () -> Void
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: coin.iconName)
                .font(.title3)
                .frame(width: 46, height: 46)
                .foregroundStyle(.white)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(coin.symbol)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(loc("WALLET_QUANTITY_SUFFIX", String(format: "%.2f", coin.quantity)))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(totalValue, format: .currency(code: "TRY"))
                    .font(.headline)
                    .foregroundStyle(.white)
                Button(loc("WALLET_SELL")) {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

struct WalletView: View {
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedCoin: Coin?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WalletSummaryCard(balance: wallet.balance, passiveBoost: wallet.passiveIncomeBoost)
                    .environmentObject(wallet)
                    .environmentObject(localization)

                PortfolioSection(selectedCoin: $selectedCoin)
                    .environmentObject(market)
                    .environmentObject(wallet)
                    .environmentObject(localization)

                VStack(alignment: .leading, spacing: 16) {
                    Text(loc("WALLET_TRANSACTIONS"))
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    if wallet.transactions.isEmpty {
                        EmptyTransactionsView()
                            .environmentObject(localization)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(wallet.transactions) { transaction in
                                TransactionCard(transaction: transaction)
                                    .environmentObject(localization)
                            }
                        }
                    }
                }
                .padding(20)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
            }
            .padding(24)
        }
        .scrollIndicators(.never)
        .sheet(item: $selectedCoin) { coin in
            SellCoinSheet(selectedCoin: coin)
                .environmentObject(market)
                .environmentObject(wallet)
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct WalletSummaryCard: View {
    let balance: Double
    let passiveBoost: Double
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(loc("WALLET_TITLE"))
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))

            Text(balance, format: .currency(code: "TRY"))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                SummaryChip(title: "WALLET_PASSIVE_CHIP", value: "+\(Int(passiveBoost * 100))%", icon: "sparkles")
                    .environmentObject(localization)
                SummaryChip(title: "WALLET_STAKED_CHIP", value: wallet.stakedBalance.formatted(.currency(code: "TRY")), icon: "lock.fill")
                    .environmentObject(localization)
            }

            PassiveIncomeRow(passiveBoost: passiveBoost,
                              accruedInterest: wallet.earnedFromInterest)
                .environmentObject(localization)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color("LakeBlue"), Color("ForestGreen")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct PassiveIncomeRow: View {
    let passiveBoost: Double
    let accruedInterest: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc("WALLET_PASSIVE_TITLE"))
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 12) {
                Label(loc("WALLET_PASSIVE_RATE", Int(passiveBoost * 100)), systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                Spacer()
                Text(accruedInterest, format: .currency(code: "TRY"))
                    .font(.headline)
            }
            .foregroundStyle(.white)
        }
        .padding(16)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct TransactionCard: View {
    let transaction: WalletTransaction
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(localizedDescription)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(transaction.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "TRY"))
                .font(.headline)
                .foregroundStyle(transaction.amount >= 0 ? .green : .red)
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        case "Faiz kazancı", "Faiz hesap bakiyesi":
            return localization.translate("TXN_INTEREST_GAIN")
        case "Interest earned", "Interest gain":
            return localization.translate("TXN_INTEREST_GAIN")
        case "Zinsen gutgeschrieben", "Zinsen erhalten":
            return localization.translate("TXN_INTEREST_GAIN")
        case "Faize yatırıldı":
            return localization.translate("TXN_STAKE_DEPOSIT")
        case "Deposited to interest":
            return localization.translate("TXN_STAKE_DEPOSIT")
        case "In Zinskonto eingezahlt":
            return localization.translate("TXN_STAKE_DEPOSIT")
        case "Faiz hesabından çekildi":
            return localization.translate("TXN_STAKE_WITHDRAW")
        case "Withdrawn from interest":
            return localization.translate("TXN_STAKE_WITHDRAW")
        case "Vom Zinskonto abgehoben":
            return localization.translate("TXN_STAKE_WITHDRAW")
        case "Pomodoro ödülü":
            return localization.translate("TXN_REWARD_POMODORO")
        case "Pomodoro reward":
            return localization.translate("TXN_REWARD_POMODORO")
        case "Pomodoro-Belohnung":
            return localization.translate("TXN_REWARD_POMODORO")
        default:
            break
        }

        if let symbol = text.replacingOccurrences(of: "Bought ", with: "", options: [.anchored]) as String?,
           text.hasPrefix("Bought ") {
            return localization.translate("TXN_MARKET_BUY", arguments: [symbol])
        }

        if let symbol = text.replacingOccurrences(of: "Sold ", with: "", options: [.anchored]) as String?,
           text.hasPrefix("Sold ") {
            return localization.translate("TXN_MARKET_SELL", arguments: [symbol])
        }

        if let symbol = text.replacingOccurrences(of: "Gekauft ", with: "", options: [.anchored]) as String?,
           text.hasPrefix("Gekauft ") {
            return localization.translate("TXN_MARKET_BUY", arguments: [symbol])
        }

        if let symbol = text.replacingOccurrences(of: "Verkauft ", with: "", options: [.anchored]) as String?,
           text.hasPrefix("Verkauft ") {
            return localization.translate("TXN_MARKET_SELL", arguments: [symbol])
        }

        if text.hasSuffix("temasını açtı") {
            let themeName = text.replacingOccurrences(of: " temasını açtı", with: "")
            return localization.translate("TXN_THEME_UNLOCK", arguments: [themeName])
        }

        if text.hasSuffix("theme unlocked") {
            let themeName = text.replacingOccurrences(of: " theme unlocked", with: "")
            return localization.translate("TXN_THEME_UNLOCK", arguments: [themeName])
        }

        if text.hasSuffix("Thema freigeschaltet") {
            let themeName = text.replacingOccurrences(of: " Thema freigeschaltet", with: "")
            return localization.translate("TXN_THEME_UNLOCK", arguments: [themeName])
        }

        return nil
    }
}

private struct EmptyTransactionsView: View {
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(.white.opacity(0.6))
            Text(loc("WALLET_EMPTY_TRANSACTIONS"))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

