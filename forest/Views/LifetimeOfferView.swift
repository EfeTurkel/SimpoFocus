import SwiftUI
import StoreKit

struct LifetimeOfferView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userName") private var userName: String = ""

    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ConfettiEmitterView(isActive: confettiActive)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Padding.card) {
                    Spacer(minLength: 24)

                    headerSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -12)
                        .animation(DS.Animation.defaultSpring, value: appeared)

                    offerCard
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.96)
                        .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 1, base: 0.05)), value: appeared)

                    ctaSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
                        .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 2, base: 0.05)), value: appeared)

                    noThanksButton
                    termsFooter

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DS.Padding.screen)
            }
        }
        .onAppear {
            appeared = true
            storeKit.startIfNeeded()
            confettiActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                confettiActive = false
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 62, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange, .pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .shadow(color: .orange.opacity(0.25), radius: 18, y: 6)

            Text(loc(greetingKey, displayName))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .onGlassPrimary()
                .multilineTextAlignment(.center)

            Text(loc("LIFETIME_OFFER_SUBTITLE"))
                .font(.title3.weight(.semibold))
                .onGlassSecondary()
                .multilineTextAlignment(.center)
        }
    }

    private var offerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("LIFETIME_OFFER_TITLE"))
                        .font(.headline)
                        .onGlassPrimary()
                    Text(loc("LIFETIME_OFFER_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "infinity")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color("ForestGreen"))
            }

            Divider().blendMode(.overlay)

            HStack(alignment: .firstTextBaseline) {
                Text(lifetimeDisplayPrice)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .onGlassPrimary()
                Text("/ " + loc("LIFETIME_OFFER_PERIOD"))
                    .font(.subheadline.weight(.semibold))
                    .onGlassSecondary()
                Spacer()
                Text(loc("LIFETIME_OFFER_EXCLUSIVE_TAG"))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("ForestGreen"), in: Capsule())
            }
        }
        .padding(DS.Padding.card)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    private var ctaSection: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await handlePurchase() }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }
                    Image(systemName: "sparkles")
                        .font(.headline)
                    Text(entitlements.isPro ? loc("PAYWALL_ALREADY_PRO") : loc("LIFETIME_OFFER_CTA"))
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
            .disabled(isPurchasing || entitlements.isPro || storeKit.lifetimeProduct == nil)
            .opacity(entitlements.isPro ? 0.5 : 1)
        }
    }

    private var noThanksButton: some View {
        Button { dismiss() } label: {
            Text(loc("SPECIAL_OFFER_NO_THANKS"))
                .font(.footnote)
                .onGlassTertiary()
                .underline()
        }
    }

    private var termsFooter: some View {
        Text(loc("LIFETIME_OFFER_TERMS"))
            .font(.caption2)
            .onGlassTertiary()
            .multilineTextAlignment(.center)
    }

    private func handlePurchase() async {
        guard let product = storeKit.lifetimeProduct else { return }
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

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? loc("HOME_GUEST_NAME") : trimmed
    }

    private var greetingKey: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "LIFETIME_OFFER_CONGRATS"
            : "LIFETIME_OFFER_CONGRATS_NAME"
    }

    private var lifetimeDisplayPrice: String {
        storeKit.lifetimeProduct?.displayPrice ?? "79,99 TL"
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

