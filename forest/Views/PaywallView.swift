import SwiftUI
import StoreKit

struct PaywallView: View {
    var onDismissedWithoutPurchase: (() -> Void)?

    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @AppStorage("userName") private var userName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Padding.card) {
                        headerSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(DS.Animation.defaultSpring, value: appeared)
                        featuresSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 1, base: 0.05)), value: appeared)

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
                            plansSection
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 10)
                                .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 2, base: 0.05)), value: appeared)
                            purchaseButton
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 10)
                                .animation(DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: 3, base: 0.05)), value: appeared)
                        }

                        restoreButton
                        termsFooter
                    }
                    .padding(.horizontal, DS.Padding.screen)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismissedWithoutPurchase?()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .onGlassSecondary()
                    }
                }
            }
            .onAppear {
                if selectedProduct == nil {
                    selectedProduct = storeKit.subscriptionProducts.first { $0.id == StoreKitService.proYearlyID }
                        ?? storeKit.subscriptionProducts.last
                }
                appeared = true
            }
            .onChange(of: storeKit.subscriptionProducts) { _, newProducts in
                guard selectedProduct == nil else { return }
                selectedProduct = newProducts.first { $0.id == StoreKitService.proYearlyID }
                    ?? newProducts.first { $0.id == StoreKitService.proMonthlyID }
                    ?? newProducts.first { $0.id == StoreKitService.proWeeklyID }
            }
            .task {
                // Ensure products are available when paywall opens.
                await MainActor.run {
                    storeKit.startIfNeeded()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DS.Padding.section) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color("ForestGreen"))
                .shadow(color: Color("ForestGreen").opacity(0.3), radius: 20, y: 4)

            if let personalized = personalizedPaywallTitle {
                Text(personalized)
                    .font(DS.Typography.heroTitle)
                    .onGlassPrimary()
            } else {
                Text(loc("PAYWALL_TITLE"))
                    .font(DS.Typography.heroTitle)
                    .onGlassPrimary()
            }

            Text(loc("PAYWALL_SUBTITLE"))
                .font(DS.Typography.body)
                .onGlassSecondary()
                .multilineTextAlignment(.center)
        }
        .padding(.top, DS.Padding.section)
    }

    // MARK: - Features

    private var featuresSection: some View {
        GlassSection(cornerRadius: DS.Radius.large) {
            VStack(spacing: 14) {
                FeatureRow(icon: "infinity", text: loc("PAYWALL_FEATURE_CATEGORIES"), color: Color("ForestGreen"))
                FeatureRow(icon: "chart.bar.xaxis", text: loc("PAYWALL_FEATURE_ANALYTICS"), color: Color("ForestGreen"))
                FeatureRow(icon: "paintbrush.fill", text: loc("PAYWALL_FEATURE_THEMES"), color: Color("ForestGreen"))
                FeatureRow(icon: "timer", text: loc("PAYWALL_FEATURE_TIMER"), color: Color("ForestGreen"))
                FeatureRow(icon: "arrow.up.right", text: loc("PAYWALL_FEATURE_COINS"), color: Color("ForestGreen"))
            }
        }
    }

    // MARK: - Plans

    private var plansSection: some View {
        let weekly = storeKit.subscriptionProducts.first { $0.id == StoreKitService.proWeeklyID }
        let standardPlans = storeKit.subscriptionProducts.filter {
            $0.id == StoreKitService.proWeeklyID || $0.id == StoreKitService.proMonthlyID || $0.id == StoreKitService.proYearlyID
        }
        .sorted { lhs, rhs in
            planRank(lhs.id) < planRank(rhs.id)
        }
        return VStack(spacing: DS.Padding.element) {
            ForEach(Array(standardPlans.enumerated()), id: \.element.id) { index, product in
                PlanCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isBestValue: product.id == StoreKitService.proYearlyID,
                    weeklyReferencePrice: weekly?.price
                ) {
                    withAnimation(DS.Animation.quickSpring) {
                        selectedProduct = product
                    }
                }
                .environmentObject(localization)
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
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
                    Text(entitlements.isPro ? loc("PAYWALL_ALREADY_PRO") : loc("PAYWALL_SUBSCRIBE"))
                }
            }
            .buttonStyle(PrimaryCTAStyle())
            .disabled(isPurchasing || selectedProduct == nil || entitlements.isPro)
            .opacity(entitlements.isPro ? 0.5 : 1)
            .accessibilityHint(loc("PAYWALL_TERMS"))
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await storeKit.restorePurchases() }
        } label: {
            Text(loc("PAYWALL_RESTORE"))
        }
        .buttonStyle(GhostButtonStyle())
    }

    // MARK: - Terms

    private var termsFooter: some View {
        Text(loc("PAYWALL_TERMS"))
            .font(.caption2)
            .onGlassSecondary()
            .opacity(0.7)
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
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

    private var personalizedPaywallTitle: String? {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return loc("PAYWALL_PERSONALIZED_TITLE", trimmed)
    }
    
    private func planRank(_ productID: String) -> Int {
        switch productID {
        case StoreKitService.proYearlyID: return 0
        case StoreKitService.proMonthlyID: return 1
        case StoreKitService.proWeeklyID: return 2
        default: return 99
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: DS.Padding.section) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

            Text(text)
                .font(DS.Typography.body)
                .onGlassPrimary()

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.body.weight(.bold))
                .foregroundStyle(Color("ForestGreen"))
        }
        .frame(minHeight: 56)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let weeklyReferencePrice: Decimal?
    let onTap: () -> Void
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Padding.section) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(planTitle)
                            .font(.subheadline.weight(.semibold))
                            .onGlassPrimary()

                        if isBestValue {
                            Text(loc("PAYWALL_BEST_VALUE"))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color("ForestGreen"), in: Capsule())
                        }
                    }

                    Text(product.displayPrice + " / " + periodSuffix)
                        .font(.caption)
                        .onGlassSecondary()

                    Text(loc("PAYWALL_TRIAL_3_DAYS"))
                        .font(.caption2)
                        .onGlassSecondary()
                        .opacity(0.85)
                    
                    if let secondaryPriceNote {
                        Text(secondaryPriceNote)
                            .font(.caption2)
                            .onGlassSecondary()
                            .opacity(0.75)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color("ForestGreen") : themeManager.currentTheme.glassSecondaryText(for: colorScheme))
                    
                    if let savingsChipText {
                        Text(savingsChipText)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.9), in: Capsule())
                    }
                }
            }
            .padding(DS.Padding.card)
            .frame(minHeight: 92)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(isBestValue ? Color.yellow.opacity(0.12) : .clear)
            )
            .liquidGlass(.card, edgeMask: [.all])
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .stroke(isSelected ? (isBestValue ? Color.yellow : Color("ForestGreen")) : (isBestValue ? Color.yellow.opacity(0.5) : .clear), lineWidth: isSelected ? 2 : (isBestValue ? 1 : 0))
            )
            .shadow(color: isSelected ? (isBestValue ? Color.yellow.opacity(0.3) : Color("ForestGreen").opacity(0.15)) : (isBestValue ? Color.yellow.opacity(0.1) : .clear), radius: isBestValue ? 15 : 8, y: isBestValue ? 0 : 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var savingsChipText: String? {
        guard isBestValue else { return nil }
        guard let weeklyReferencePrice else { return loc("PAYWALL_BEST_VALUE") }
        let weekly = NSDecimalNumber(decimal: weeklyReferencePrice).doubleValue
        let yearly = NSDecimalNumber(decimal: product.price).doubleValue
        guard weekly > 0, yearly > 0 else { return nil }
        let weeklyYear = weekly * 52.0
        guard weeklyYear > 0 else { return nil }
        let savings = max(0, 1.0 - (yearly / weeklyYear))
        let percent = Int((savings * 100.0).rounded())
        guard percent > 0 else { return loc("PAYWALL_BEST_VALUE") }
        return "%\(percent) " + loc("PAYWALL_SAVE")
    }
    
    private var secondaryPriceNote: String? {
        guard isBestValue else { return nil }
        let yearly = NSDecimalNumber(decimal: product.price).doubleValue
        guard yearly > 0 else { return nil }
        let monthly = yearly / 12.0
        let formatted = currencyString(monthly)
        return "≈ \(formatted) / " + loc("PAYWALL_PERIOD_MONTH")
    }
    
    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var planTitle: String {
        switch product.id {
        case StoreKitService.proWeeklyID:  return loc("PAYWALL_PLAN_WEEKLY")
        case StoreKitService.proMonthlyID: return loc("PAYWALL_PLAN_MONTHLY")
        case StoreKitService.proYearlyID:  return loc("PAYWALL_PLAN_YEARLY")
        default: return product.displayName
        }
    }

    private var periodSuffix: String {
        switch product.id {
        case StoreKitService.proWeeklyID:  return loc("PAYWALL_PERIOD_WEEK")
        case StoreKitService.proMonthlyID: return loc("PAYWALL_PERIOD_MONTH")
        case StoreKitService.proYearlyID:  return loc("PAYWALL_PERIOD_YEAR")
        default: return ""
        }
    }

    private func loc(_ key: String) -> String {
        localization.translate(key, fallback: key)
    }
}
