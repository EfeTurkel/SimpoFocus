import SwiftUI
import StoreKit

struct CoinStoreView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing: String?
    @State private var showSuccess = false
    @State private var successAmount: Double = 0
    @State private var appeared = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Padding.card) {
                        if !entitlements.isPro {
                            proCoinsBanner
                        }

                        balanceHeader

                        if let loadError = storeKit.loadError {
                            GlassSection {
                                VStack(spacing: DS.Padding.element) {
                                    Text(loadError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                    Button(loc("PAYWALL_RESTORE")) {
                                        Task { await storeKit.loadProducts() }
                                    }
                                    .buttonStyle(SecondaryCTAStyle())
                                }
                            }
                        } else {
                            coinPacksSection
                        }
                    }
                    .padding(.horizontal, DS.Padding.screen)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(loc("COIN_STORE_TITLE"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .onGlassSecondary()
                    }
                }
            }
            .alert(loc("COIN_STORE_SUCCESS_TITLE"), isPresented: $showSuccess) {
                Button(loc("COIN_STORE_OK")) { }
            } message: {
                Text(loc("COIN_STORE_SUCCESS_MSG", Int(successAmount)))
            }
            .onAppear {
                withAnimation(DS.Animation.defaultSpring.delay(0.1)) {
                    appeared = true
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Pro Coins Banner

    private var proCoinsBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.yellow)

                Text(loc("PRO_COINSTORE_BANNER"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .onGlassPrimary()

                Spacer()

                Text(loc("PRO_COINSTORE_CTA"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color("ForestGreen"))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color("ForestGreen").opacity(0.3), .yellow.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Balance Header

    private var balanceHeader: some View {
        GlassSection(cornerRadius: DS.Radius.xl) {
            VStack(spacing: DS.Padding.element) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: DS.IconSize.medium))
                    .foregroundStyle(Color("ForestGreen"))

                Text(loc("COIN_STORE_BALANCE"))
                    .font(DS.Typography.caption)
                    .onGlassSecondary()

                Text(String(format: "%.0f", wallet.balance))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .onGlassPrimary()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Coin Packs

    private var coinPacksSection: some View {
        VStack(spacing: DS.Padding.element) {
            ForEach(Array(storeKit.coinProducts.enumerated()), id: \.element.id) { index, product in
                CoinPackCard(
                    product: product,
                    coinAmount: StoreKitService.coinAmounts[product.id] ?? 0,
                    isPurchasing: isPurchasing == product.id
                ) {
                    Task { await purchaseCoinPack(product) }
                }
                .environmentObject(localization)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: index, base: 0.05)), value: appeared)
            }
        }
    }

    // MARK: - Actions

    private func purchaseCoinPack(_ product: Product) async {
        isPurchasing = product.id

        do {
            let transaction = try await storeKit.purchase(product)
            if transaction != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                let amount = StoreKitService.coinAmounts[product.id] ?? 0
                successAmount = amount
                showSuccess = true
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #if DEBUG
            print("CoinStore purchase error: \(error)")
            #endif
        }

        isPurchasing = nil
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

// MARK: - Coin Pack Card

private struct CoinPackCard: View {
    let product: Product
    let coinAmount: Double
    let isPurchasing: Bool
    let onPurchase: () -> Void
    @EnvironmentObject private var localization: LocalizationManager

    private var packIcon: String {
        switch product.id {
        case StoreKitService.coinsSmallID: return "leaf.fill"
        case StoreKitService.coinsMediumID: return "leaf.circle.fill"
        case StoreKitService.coinsLargeID: return "tree.fill"
        default: return "star.fill"
        }
    }

    private var packColor: Color {
        switch product.id {
        case StoreKitService.coinsSmallID: return .green
        case StoreKitService.coinsMediumID: return .blue
        case StoreKitService.coinsLargeID: return .purple
        default: return .orange
        }
    }

    var body: some View {
        HStack(spacing: DS.Padding.section) {
            Image(systemName: packIcon)
                .font(.title2)
                .foregroundStyle(packColor)
                .frame(width: 50, height: 50)
                .background(packColor.opacity(0.15), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.subheadline.weight(.semibold))
                    .onGlassPrimary()

                Text(String(format: "%.0f coins", coinAmount))
                    .font(.caption)
                    .onGlassSecondary()
            }

            Spacer()

            Button(action: onPurchase) {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(product.displayPrice)
                            .font(.subheadline.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Padding.card)
                .padding(.vertical, DS.Padding.element)
                .background(
                    Color("ForestGreen"),
                    in: Capsule()
                )
            }
            .disabled(isPurchasing)
        }
        .padding(DS.Padding.card)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.all])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }
}
