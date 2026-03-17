import SwiftUI
import StoreKit

// MARK: - Token Packages View

struct TokenPackagesView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    var isSheet: Bool = false
    @State private var isPurchasingProductID: String?
    @State private var feedbackText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isSheet {
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                    Spacer()
                }
            }

            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isSheet ? loc("COIN_STORE_INSUFFICIENT", fallback: "Yetersiz Bakiye") : loc("COIN_STORE_TITLE", fallback: "Token Paketleri"))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .onGlassPrimary()
                    Text(isSheet ? loc("COIN_STORE_BUY_MORE", fallback: "Gerekli işlemi yapmak için token almalısınız.") : loc("COIN_STORE_SUBTITLE", fallback: "Uygulama içi satın alımlar"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(isSheet ? .red.opacity(0.8) : Color.secondary)
                }
                Spacer()
                if !entitlements.isPro {
                    Text("PRO 2X")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.horizontal, DS.Padding.screen)
            .padding(.top, isSheet ? 8 : 0)

            // Package cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Spacer().frame(width: DS.Padding.screen - 16)

                    if storeKit.coinProducts.isEmpty {
                        placeholderPackCard(tier: .starter, amount: "500", price: "₺29.99")
                        placeholderPackCard(tier: .popular, amount: "1.5K", price: "₺69.99")
                        placeholderPackCard(tier: .mega, amount: "5.0K", price: "₺149.99")
                    } else {
                        ForEach(storeKit.coinProducts, id: \.id) { product in
                            paidPackageCard(for: product)
                        }
                    }

                    Spacer().frame(width: DS.Padding.screen - 16)
                }
                .padding(.bottom, 8)
            }
            
            if isSheet {
                Spacer()
            }
        }
        .overlay(alignment: .top) {
            if let feedbackText {
                feedbackBanner(feedbackText)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(isSheet ? themeManager.currentTheme.getBackgroundGradient(for: colorScheme).ignoresSafeArea() : nil)
    }

    // MARK: - Feedback Banner
    private func feedbackBanner(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.primary.opacity(0.05), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
            .padding(.top, isSheet ? 24 : 8)
    }

    // MARK: - Package Tier
    private enum PackageTier {
        case starter, popular, mega
        var icon: String {
            switch self {
            case .starter: return "circle"
            case .popular: return "circle.circle"
            case .mega: return "circle.circle.fill"
            }
        }
        var label: String {
            switch self {
            case .starter: return "BAŞLANGIÇ"
            case .popular: return "POPÜLER"
            case .mega: return "EN İYİ FIRSAT"
            }
        }
        var isBest: Bool { self == .mega }
    }

    private func tierFor(_ productID: String) -> PackageTier {
        switch productID {
        case StoreKitService.coinsSmallID: return .starter
        case StoreKitService.coinsMediumID: return .popular
        case StoreKitService.coinsLargeID: return .mega
        default: return .starter
        }
    }

    // MARK: - Paid Package Card
    private func paidPackageCard(for product: Product) -> some View {
        let amount = StoreKitService.coinAmounts[product.id] ?? 0
        let tier = tierFor(product.id)
        return packageCardContent(
            tier: tier,
            amountText: formatAmount(amount),
            priceText: product.displayPrice,
            isLoading: isPurchasingProductID == product.id
        ) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            Task { await purchase(product) }
        }
    }

    private func placeholderPackCard(tier: PackageTier, amount: String, price: String) -> some View {
        packageCardContent(tier: tier, amountText: amount, priceText: price, isLoading: false) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }

    private func packageCardContent(
        tier: PackageTier,
        amountText: String,
        priceText: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: tier.icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.secondary)
                Spacer()
                if tier.isBest {
                    Text(tier.label)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(amountText)
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .onGlassPrimary()
                Text(tier.isBest ? "TOKEN PAKETİ" : "TOKEN")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            Button(action: action) {
                Group {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(priceText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
            .foregroundStyle(tier.isBest ? Color.black : themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
            .background(
                tier.isBest ? Color.yellow.opacity(0.8) : Color.primary.opacity(0.02),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tier.isBest ? Color.yellow : Color.primary.opacity(0.1), lineWidth: tier.isBest ? 1.5 : 0.5)
            )
            .shadow(color: tier.isBest ? Color.yellow.opacity(0.4) : .clear, radius: 10, y: 4)
            .disabled(isLoading)
        }
        .padding(20)
        .frame(width: 160, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(tier.isBest ? 0.05 : 0.0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(tier.isBest ? Color.yellow.opacity(0.6) : Color.primary.opacity(0.08), lineWidth: tier.isBest ? 1 : 0.5)
        )
        .shadow(color: tier.isBest ? Color.yellow.opacity(0.15) : .clear, radius: 20, y: 0)
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1000 { return String(format: "%.1fK", amount / 1000) }
        return String(Int(amount))
    }

    private func purchase(_ product: Product) async {
        isPurchasingProductID = product.id
        defer { isPurchasingProductID = nil }
        do {
            _ = try await storeKit.purchase(product)
            showFeedback(loc("COIN_STORE_SUCCESS", fallback: "Satın alma başarılı"))
            if isSheet {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
            }
        } catch {
            showFeedback(loc("BUY_ERROR_GENERIC", fallback: "İptal edildi"))
        }
    }

    private func showFeedback(_ text: String) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(text.contains("hata") || text.contains("İptal") ? .error : .success)
        withAnimation(DS.Animation.quickSpring) { feedbackText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(DS.Animation.quickSpring) { feedbackText = nil }
        }
    }

    private func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

// MARK: - Utilities Toggle View

struct UtilitiesToggleView: View {
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    @Binding var isExpanded: Bool
    @Binding var showCoinStoreSheet: Bool

    var body: some View {
        FinanceToggleComponent(
            icon: "sparkles",
            titleKey: "TOKEN_UTILITY_TITLE",
            fallback: "Güçlendirmeler",
            isExpanded: $isExpanded
        ) {
            VStack(spacing: 8) {
                UtilityRow(
                    title: loc("TOKEN_UTILITY_EARN_TITLE", fallback: "2x Odak Geliri"),
                    subtitle: loc("TOKEN_UTILITY_EARN_SUB", fallback: "Pomodoro nakit ödüllerini 2 saat için 2x yapar"),
                    actionTitle: "300",
                    action: activateMultiplier
                )
                Divider().opacity(0.5)
                UtilityRow(
                    title: loc("TOKEN_UTILITY_BANK_TITLE", fallback: "Banka Boost"),
                    subtitle: loc("TOKEN_UTILITY_BANK_SUB", fallback: "Günlük faiz hesabına 24 saat +50% çarpan"),
                    actionTitle: "250",
                    action: activateBankBoost
                )
                Divider().opacity(0.5)
                UtilityRow(
                    title: loc("TOKEN_UTILITY_MARKET_TITLE", fallback: "Market Yenileme"),
                    subtitle: loc("TOKEN_UTILITY_MARKET_SUB", fallback: "Ekstra piyasa yenileme hakkı"),
                    actionTitle: "120",
                    action: activateMarketPerk
                )
                Divider().opacity(0.5)
                UtilityStatusRow(
                    title: loc("TOKEN_UTILITY_COSMETIC_TITLE", fallback: "Kozmetik"),
                    subtitle: loc("TOKEN_UTILITY_COSMETIC_SUB", fallback: "Ev temaları ve dekorasyonlar"),
                    status: loc("TOKEN_UTILITY_ACTIVE", fallback: "Açık")
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
            .padding(.top, 16)
        }
    }

    private func activateMultiplier() {
        let success = wallet.activateEarningMultiplier(multiplier: 2.0, duration: 2 * 60 * 60, cost: 300)
        handlePurchaseResult(success)
    }

    private func activateBankBoost() {
        let success = wallet.activateBankBoost(multiplier: 1.5, duration: 24 * 60 * 60, cost: 250)
        handlePurchaseResult(success)
    }

    private func activateMarketPerk() {
        let success = wallet.activateMarketRefreshCredits(count: 1, duration: 24 * 60 * 60, cost: 120)
        handlePurchaseResult(success)
    }

    private func handlePurchaseResult(_ success: Bool) {
        if !success {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            showCoinStoreSheet = true
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

// MARK: - Coins Market Toggle View

struct CoinsMarketToggleView: View {
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    @Binding var isExpanded: Bool
    @Binding var selectedCoin: Coin?
    @Binding var showingSellSheet: Bool

    var body: some View {
        FinanceToggleComponent(
            icon: "chart.line.uptrend.xyaxis",
            titleKey: "MARKET_COINS",
            fallback: "Coinler",
            isExpanded: $isExpanded
        ) {
            CoinsMarketSection(selectedCoin: $selectedCoin, showingSellSheet: $showingSellSheet)
                .environmentObject(market)
                .environmentObject(localization)
                .padding(.top, 16)
        }
    }
}

// MARK: - Reusable Minimal Toggle Component

struct FinanceToggleComponent<Content: View>: View {
    let icon: String
    let titleKey: String
    let fallback: String
    @Binding var isExpanded: Bool
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(isExpanded ? themeManager.currentTheme.getPrimaryTextColor(for: colorScheme) : Color.secondary)

                    Text(localization.translate(titleKey, fallback: fallback))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .onGlassPrimary()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(isExpanded ? 0.03 : 0.0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
            }
            .buttonStyle(SectionToggleStyle())

            if isExpanded {
                content()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -10)),
                            removal: .opacity.combined(with: .offset(y: -10))
                        )
                    )
            }
        }
    }
}

// MARK: - Supporting Row Types

private struct UtilityRow: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }) {
                Text(actionTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.04), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

private struct UtilityStatusRow: View {
    let title: String
    let subtitle: String
    let status: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(status)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 8)
    }
}

private struct SectionToggleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
