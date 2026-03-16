import SwiftUI

struct FinanceView: View {
    enum Section: String, CaseIterable {
        case bank
        case wallet

        var titleKey: String {
            switch self {
            case .bank: return "TAB_BANK"
            case .wallet: return "TAB_WALLET"
            }
        }

        var defaultTitle: String {
            switch self {
            case .bank: return "Banka"
            case .wallet: return "Cüzdan"
            }
        }
    }

    @State private var selectedSection: Section = .bank
    @State private var showPaywall = false
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("financeProBannerDismissed") private var bannerDismissed = false

    var body: some View {
        VStack(spacing: 0) {
            segmentedPicker
                .padding(.horizontal, DS.Padding.screen)
                .padding(.top, DS.Padding.element)
                .padding(.bottom, 4)

            if !entitlements.isPro && !bannerDismissed {
                proBanner
                    .padding(.horizontal, DS.Padding.screen)
                    .padding(.vertical, 6)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            switch selectedSection {
            case .bank:
                BankView()
                    .transition(.opacity)
            case .wallet:
                WalletView()
                    .transition(.opacity)
            }
        }
        .animation(DS.Animation.quickSpring, value: selectedSection)
        .animation(.easeOut(duration: 0.25), value: bannerDismissed)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var proBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 1) {
                    Text(loc("PRO_BANNER_TITLE", fallback: "2x Coin Multiplier"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    Text(loc("PRO_BANNER_SUBTITLE", fallback: "Unlock with Pro"))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(themeManager.currentTheme.glassSecondaryText(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(themeManager.currentTheme.glassSecondaryText(for: colorScheme))

                Button {
                    withAnimation { bannerDismissed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(themeManager.currentTheme.glassSecondaryText(for: colorScheme))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .strokeBorder(Color("ForestGreen").opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases, id: \.self) { section in
                let isSelected = section == selectedSection
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedSection = section
                } label: {
                    Text(loc(section.titleKey, fallback: section.defaultTitle))
                        .font(DS.Typography.cardTitle)
                        .foregroundStyle(
                            isSelected
                            ? Color("ForestGreen")
                            : themeManager.currentTheme.glassSecondaryText(for: colorScheme)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected
                            ? Color("ForestGreen").opacity(0.10)
                            : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.6),
            in: Capsule()
        )
    }

    private func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}
