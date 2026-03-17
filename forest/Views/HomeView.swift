import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("userName") private var userName: String = ""
    @State private var selectedAsset: RoomAsset?
    @State private var showingInventory = false
    @State private var showingPaywall = false
    @State private var showingCoinStore = false
    @State private var toastMessage: ToastMessage?

    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Active Theme
            activeThemeCard

            // MARK: - Selected / Studio
            equippedSection

            // MARK: - Market
            marketSection
        }
        .padding(.horizontal, DS.Padding.screen) // Matches finance view horizontal paddings if removed there. Actually since HomeView is placed INSIDE FinanceView which ALREADY has horizontal padding, this might cause double padding.
        // I will remove the outer horizontal padding here, since FinanceView already handles the horizontal bounds for `HomeView`.
        .padding(.horizontal, 0) // Explicitly no horizontal padding
        .padding(.top, 8)
        .overlay(alignment: .top) {
            if let toastMessage {
                ToastBanner(message: toastMessage)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 12)
            }
        }
        .sheet(isPresented: $showingInventory) {
            OwnedItemsView(title: loc("HOME_BUTTON_INVENTORY"), assets: room.ownedAssets)
                .environmentObject(room)
                .environmentObject(localization)
        }
        .sheet(item: $selectedAsset) { asset in
            PurchaseSheet(asset: asset) { result in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    toastMessage = result
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if toastMessage?.id == result.id {
                            toastMessage = nil
                        }
                    }
                }
            }
            .environmentObject(room)
            .environmentObject(wallet)
            .environmentObject(localization)
            .presentationDetents([.fraction(0.42), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.automatic)
        }
    }

    // MARK: - Overview / Theme
    
    private var activeThemeCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(loc("HOME_ACTIVE_THEME_TITLE"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                Text(room.currentTheme.name)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showingInventory = true
            } label: {
                Text(loc("HOME_ACTIVE_THEME_BUTTON"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.04), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    // MARK: - Equipped / Studio

    private var equippedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("HOME_STUDIO_TITLE"))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .onGlassPrimary()
                    Text(loc("HOME_STUDIO_SUBTITLE"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingInventory = true
                } label: {
                    Text(loc("HOME_BUTTON_INVENTORY"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.04), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            if room.placedItems.isEmpty {
                EmptyStateView(message: loc("HOME_STUDIO_EMPTY"))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(room.placedItems) { item in
                        DecorCard(asset: item.asset) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                let generator = UIImpactFeedbackGenerator(style: .rigid)
                                generator.impactOccurred()
                                room.remove(assetID: item.asset.id)
                            }
                        }
                        .environmentObject(localization)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    // MARK: - Market

    private var marketSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc("HOME_MARKET_TITLE"))
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .onGlassPrimary()
                Text(loc("HOME_MARKET_SUBTITLE"))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 20)

            ForEach(room.availableMarketSections) { section in
                MarketListSectionView(section: section,
                                      isUnlocked: { room.unlockedAssets.contains($0) }) { asset in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selectedAsset = asset
                }
                .environmentObject(localization)
            }
        }
        .padding(.vertical, 20)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

// MARK: - Supporting Views

private struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Color.secondary.opacity(0.6))
            Text(message)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

private struct DecorCard: View {
    let asset: RoomAsset
    let removeAction: () -> Void
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: asset.iconName)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

            VStack(spacing: 4) {
                Text(localizedName)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(localizedDescription)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Button(role: .destructive, action: removeAction) {
                Text(loc("HOME_DECOR_REMOVE"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.05), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.red.opacity(0.2), lineWidth: 0.5))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var localizedName: String { loc(asset.nameKey) }
    private var localizedDescription: String { loc(asset.descriptionKey) }
    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct MarketItemCard: View {
    let asset: RoomAsset
    let isUnlocked: Bool
    let action: () -> Void
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: asset.iconName)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

                Text(localizedName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if isUnlocked {
                    Text(loc("HOME_MARKET_PURCHASED"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme).opacity(0.6))
                } else {
                    Text(asset.price, format: .currency(code: "TRY"))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(isUnlocked ? 0.01 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isUnlocked ? 0.03 : 0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isUnlocked)
        .opacity(isUnlocked ? 0.6 : 1)
    }

    private var localizedName: String { loc(asset.nameKey) }
    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct MarketListSectionView: View {
    let section: MarketSection
    let isUnlocked: (UUID) -> Bool
    let action: (RoomAsset) -> Void
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc(section.titleKey))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 20)
                .textCase(.uppercase)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Spacer().frame(width: 8)
                    ForEach(section.assets) { asset in
                        MarketItemCard(asset: asset,
                                       isUnlocked: isUnlocked(asset.id),
                                       action: { action(asset) })
                        .frame(width: 140)
                        .environmentObject(localization)
                    }
                    Spacer().frame(width: 8)
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct PurchaseSheet: View {
    let asset: RoomAsset
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @State private var placementSuccess = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    let completion: (ToastMessage) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: asset.iconName)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    .padding(24)
                    .background(Color.primary.opacity(0.03), in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))

                VStack(spacing: 8) {
                    Text(loc(asset.nameKey))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

                    Text(loc(asset.descriptionKey))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 24)
                }

                Text(asset.price, format: .currency(code: "TRY"))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

                if placementSuccess {
                    Label(loc("HOME_PURCHASE_PLACED", loc(asset.nameKey)), systemImage: "checkmark")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                }

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    purchaseAndPlace()
                } label: {
                    Text(room.unlockedAssets.contains(asset.id) ? loc("HOME_PURCHASE_PLACE") : loc("HOME_PURCHASE_BUY_PLACE"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(themeManager.currentTheme == .light || colorScheme == .light ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .padding(.top, 32)
            .background(themeManager.currentTheme.sheetBackground(for: colorScheme))
        }
    }

    private func purchaseAndPlace() {
        if room.unlockedAssets.contains(asset.id) {
            room.place(asset: asset)
            placementSuccess = true
            let message = ToastMessage(text: loc("HOME_PURCHASE_PLACED", loc(asset.nameKey)), style: .success)
            completion(message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
        } else if room.unlock(asset: asset, wallet: wallet) {
            room.place(asset: asset)
            placementSuccess = true
            let message = ToastMessage(text: loc("HOME_PURCHASE_PURCHASED", loc(asset.nameKey)), style: .success)
            completion(message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
        } else {
            let message = ToastMessage(text: loc("HOME_PURCHASE_BALANCE_ERROR"), style: .error)
            completion(message)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct OwnedItemsView: View {
    let title: String
    let assets: [RoomAsset]
    @EnvironmentObject private var room: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if assets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                        Text(loc("HOME_OWNED_EMPTY"))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeManager.currentTheme.sheetBackground(for: colorScheme))
                } else {
                    List {
                        ForEach(assets) { asset in
                            HStack(spacing: 16) {
                                Image(systemName: asset.iconName)
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.primary.opacity(0.04))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(loc(asset.nameKey))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Text(loc(asset.descriptionKey))
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.secondary)
                                }

                                Spacer()

                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    room.place(asset: asset)
                                } label: {
                                    Text(loc("HOME_PURCHASE_PLACE"))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.primary.opacity(0.05), in: Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(themeManager.currentTheme.sheetBackground(for: colorScheme))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .presentationBackground(.regularMaterial)
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    let style: Style

    enum Style {
        case success
        case error
    }
}

private struct ToastBanner: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.style == .success ? "checkmark" : "exclamationmark.triangle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.primary)

            Text(message.text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(message.style == .success ? 0.05 : 0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}
