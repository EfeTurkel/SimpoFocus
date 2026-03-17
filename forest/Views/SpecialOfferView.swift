import SwiftUI
import StoreKit

struct SpecialOfferView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var timeRemaining: Int = 15 * 60
    @State private var appeared = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Padding.card) {
                    Spacer(minLength: DS.Padding.card)
                    headerSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -12)
                        .animation(DS.Animation.defaultSpring, value: appeared)
                    discountBadge
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.9)
                        .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 1, base: 0.05)), value: appeared)
                    countdownSection
                        .opacity(appeared ? 1 : 0)
                        .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 2, base: 0.05)), value: appeared)
                    featuresCompact
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 3, base: 0.05)), value: appeared)
                    ctaButton
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)
                        .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 4, base: 0.05)), value: appeared)
                    noThanksButton
                    termsFooter
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DS.Padding.screen)
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                withAnimation(DS.Animation.defaultSpring) { timeRemaining -= 1 }
            }
        }
        .onAppear {
            appeared = true
        }
    }

    // MARK: - Background

    private var background: some View {
        themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
            .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: DS.IconSize.large))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange, .red],
                                   startPoint: .top, endPoint: .bottom)
                )

            Text(loc("SPECIAL_OFFER_WAIT"))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .onGlassPrimary()

            Text(loc("SPECIAL_OFFER_TITLE"))
                .font(.title3.weight(.semibold))
                .onGlassPrimary()
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Discount Badge

    private var discountBadge: some View {
        VStack(spacing: DS.Padding.section) {
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(Color("ForestGreen"))
                .frame(height: 80)
                .overlay(
                    Text(loc("SPECIAL_OFFER_DISCOUNT_BADGE"))
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                )

            HStack(spacing: DS.Padding.element) {
                VStack(spacing: 2) {
                    Text(loc("SPECIAL_OFFER_ORIGINAL_PRICE"))
                        .font(.caption2)
                        .onGlassSecondary()
                    Text("₺199.99")
                        .font(.title2.weight(.bold))
                        .strikethrough(true, color: .red)
                        .onGlassSecondary()
                }

                Image(systemName: "arrow.right")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("ForestGreen"))

                VStack(spacing: 2) {
                    Text(loc("SPECIAL_OFFER_NOW"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("ForestGreen"))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        let weeklyProduct = storeKit.subscriptionProducts.first { $0.id == StoreKitService.proWeeklyID }
                        Text(weeklyProduct?.displayPrice ?? "$0.99")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .onGlassPrimary()
                        Text(loc("SPECIAL_OFFER_PER_WEEK"))
                            .font(.subheadline.weight(.semibold))
                            .onGlassSecondary()
                    }
                }
            }
        }
        .padding(DS.Padding.card)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    // MARK: - Countdown

    private var countdownSection: some View {
        VStack(spacing: 8) {
            Text(loc("SPECIAL_OFFER_TIMER_LABEL"))
                .font(.caption.weight(.medium))
                .onGlassSecondary()
                .textCase(.uppercase)
                .tracking(1.5)

            HStack(spacing: 8) {
                let minutes = timeRemaining / 60
                let seconds = timeRemaining % 60

                timerDigit(String(format: "%02d", minutes))
                Text(":")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color("ForestGreen"))
                timerDigit(String(format: "%02d", seconds))
            }
        }
        .padding(.vertical, DS.Padding.section)
        .padding(.horizontal, DS.Padding.xl)
        .background(
            Capsule().fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
        )
        .clipShape(Capsule())
    }

    private func timerDigit(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 40, weight: .bold, design: .monospaced))
            .onGlassPrimary()
            .frame(width: 72)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                    .fill(themeManager.currentTheme.glassPrimaryText(for: colorScheme).opacity(0.08))
            )
            .contentTransition(.numericText())
    }

    // MARK: - Features

    private var featuresCompact: some View {
        HStack(spacing: DS.Padding.section) {
            compactFeature(icon: "infinity", text: loc("PAYWALL_FEATURE_CATEGORIES"))
            compactFeature(icon: "chart.bar.xaxis", text: loc("PAYWALL_FEATURE_ANALYTICS"))
            compactFeature(icon: "paintbrush.fill", text: loc("PAYWALL_FEATURE_THEMES"))
        }
        .padding(DS.Padding.section)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.all])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }

    private func compactFeature(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("ForestGreen"))
            Text(text)
                .font(.caption2.weight(.medium))
                .onGlassSecondary()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Button {
                Task { await handlePurchase() }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }
                    Image(systemName: "bolt.fill")
                        .font(.headline)
                    Text(loc("SPECIAL_OFFER_CTA"))
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Padding.card)
                .background(
                    Color("ForestGreen"),
                    in: RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isPurchasing)
        }
    }

    // MARK: - No Thanks

    private var noThanksButton: some View {
        Button { dismiss() } label: {
            Text(loc("SPECIAL_OFFER_NO_THANKS"))
                .font(.footnote)
                .onGlassTertiary()
                .underline()
        }
    }

    // MARK: - Terms

    private var termsFooter: some View {
        Text(loc("PAYWALL_TERMS"))
            .font(.caption2)
            .onGlassTertiary()
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let product = storeKit.subscriptionProducts.first(where: { $0.id == StoreKitService.proWeeklyID }) else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            let transaction = try await storeKit.purchase(product)
            if transaction != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = error.localizedDescription
        }

        isPurchasing = false
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}
