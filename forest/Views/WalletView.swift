import SwiftUI

struct WalletView: View {
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedCoin: Coin?
    @State private var showingSellSheet = false
    @State private var buyAmount: Double = 100

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Padding.card) {
                WalletSummaryCard(balance: wallet.balance, passiveBoost: wallet.passiveIncomeBoost)
                    .environmentObject(wallet)
                    .environmentObject(localization)

                CoinsMarketSection(selectedCoin: $selectedCoin, showingSellSheet: $showingSellSheet)
                    .environmentObject(market)
                    .environmentObject(localization)

                TransactionsSection()
                    .environmentObject(wallet)
                    .environmentObject(localization)
            }
            .padding(DS.Padding.screen)
        }
        .scrollIndicators(.never)
        .sheet(item: $selectedCoin) { coin in
            BuyCoinSheet(coin: coin, amount: $buyAmount)
                .environmentObject(market)
                .environmentObject(wallet)
        }
        .sheet(isPresented: $showingSellSheet) {
            SellCoinSheet()
                .environmentObject(market)
                .environmentObject(wallet)
        }
        .onAppear {
            market.refreshPrices()
        }
    }
}

