import SwiftUI

struct FinanceView: View {
    @State private var showPaywall = false
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var wallet: WalletViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var bannerDismissed = false

    @State private var showHome = false
    @State private var showBank = false
    @State private var showUtilities = false
    @State private var showCoins = false
    @State private var showCoinStoreSheet = false
    @State private var selectedCoin: Coin?
    @State private var showingSellSheet = false

    @EnvironmentObject private var market: MarketViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Pro Banner
                if !entitlements.isPro && !bannerDismissed {
                    proBanner
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // MARK: - Hero Balance
                heroBalanceCard

                // MARK: - Ev (Home)
                collapsibleSection(
                    icon: "house",
                    titleKey: "TAB_HOME",
                    fallback: "Ev",
                    isExpanded: $showHome
                ) {
                    HomeView()
                }

                // MARK: - Banka (Bank)
                collapsibleSection(
                    icon: "building.columns",
                    titleKey: "TAB_BANK",
                    fallback: "Banka",
                    isExpanded: $showBank
                ) {
                    BankView()
                }

                // MARK: - Güçlendirmeler
                UtilitiesToggleView(isExpanded: $showUtilities, showCoinStoreSheet: $showCoinStoreSheet)

                // MARK: - Coinler
                CoinsMarketToggleView(isExpanded: $showCoins, selectedCoin: $selectedCoin, showingSellSheet: $showingSellSheet)

                // MARK: - Coin Mağazası
                TokenPackagesView(isSheet: false)
                    .padding(.horizontal, -DS.Padding.screen)

                // MARK: - Transactions (always at bottom)
                TransactionsSection()
                    .environmentObject(wallet)
                    .environmentObject(localization)
                    .padding(.top, 16)
            }
            .padding(.horizontal, DS.Padding.screen)
            .padding(.bottom, 60)
            .padding(.top, 16)
        }
        .scrollIndicators(.never)
        .background(themeManager.currentTheme.getBackgroundGradient(for: colorScheme))
        .animation(.easeOut(duration: 0.25), value: bannerDismissed)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showHome)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showBank)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showUtilities)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showCoins)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: $selectedCoin) { coin in
            BuyCoinSheet(coin: coin, amount: .constant(100.0))
                .environmentObject(market)
                .environmentObject(wallet)
        }
        .sheet(isPresented: $showingSellSheet) {
            SellCoinSheet()
                .environmentObject(market)
                .environmentObject(wallet)
        }
        .sheet(isPresented: $showCoinStoreSheet) {
            TokenPackagesView(isSheet: true)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            market.refreshPrices()
        }
    }

    // MARK: - Hero Balance Card

    private var heroBalanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("COIN_STORE_BALANCE", fallback: "Net Varlıklar").uppercased())
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.secondary)

            HStack(alignment: .bottom) {
                Text(TokenFormatter.format(wallet.balance, maximumFractionDigits: 0))
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .onGlassPrimary()
                    .contentTransition(.numericText())

                Spacer()
            }

            HStack(spacing: 12) {
                minimalChip(label: "+\(Int(wallet.passiveIncomeBoost * 100))% Boost")
                minimalChip(label: "\(TokenFormatter.format(wallet.stakedBalance, maximumFractionDigits: 0)) Stake")
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.all])
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    // MARK: - Minimal Chip

    private func minimalChip(label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Color.secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.primary.opacity(0.03), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
    }

    // MARK: - Collapsible Section

    private func collapsibleSection<Content: View>(
        icon: String,
        titleKey: String,
        fallback: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(isExpanded.wrappedValue ? themeManager.currentTheme.getPrimaryTextColor(for: colorScheme) : Color.secondary)

                    Text(loc(titleKey, fallback: fallback))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .onGlassPrimary()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(isExpanded.wrappedValue ? 0.03 : 0.0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
            }
            .buttonStyle(SectionToggleStyle())

            if isExpanded.wrappedValue {
                content()
                    .padding(.top, 16)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -10)),
                            removal: .opacity.combined(with: .offset(y: -10))
                        )
                    )
            }
        }
    }

    // MARK: - Pro Banner

    private var proBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.primary.opacity(0.7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("PRO_BANNER_TITLE", fallback: "SimpoFocus Pro"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .onGlassPrimary()
                    Text(loc("PRO_BANNER_SUBTITLE", fallback: "2x Sim & Sınırsız Özellikler"))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Button {
                    withAnimation { bannerDismissed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
        }
        .buttonStyle(SectionToggleStyle())
    }

    private func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

// MARK: - Premium Toggle Button Style

private struct SectionToggleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
