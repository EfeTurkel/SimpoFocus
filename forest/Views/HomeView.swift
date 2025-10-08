import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @AppStorage("userName") private var userName: String = ""
    @State private var selectedSegment: Segment = .overview
    @State private var selectedAsset: RoomAsset?
    @State private var showingInventory = false
    @State private var toastMessage: ToastMessage?
    @Namespace private var animation

    private var greetingName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? loc("HOME_GUEST_NAME") : trimmed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                heroHeader
                segmentedControl
                contentForSelectedSegment
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.never)
        .background(bloomBackground)
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    toastMessage = result
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut) {
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

    private var bloomBackground: some View {
        ZStack {
            LinearGradient(colors: [Color("ForestGreen"), Color("LakeNight")], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Color.white.opacity(0.08), .clear], center: .topLeading, startRadius: 80, endRadius: 360)
            RadialGradient(colors: [Color.white.opacity(0.08), .clear], center: .bottomTrailing, startRadius: 60, endRadius: 320)
        }
        .ignoresSafeArea()
    }

    private var heroHeader: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: loc("HOME_GREETING"), greetingName))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(loc("HOME_SUBTITLE"))
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    showingInventory = true
                } label: {
                    Label(loc("HOME_BUTTON_INVENTORY"), systemImage: "tray.full")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            HStack(spacing: 18) {
                BalanceCard(title: loc("HOME_BALANCE_PRIMARY"), value: wallet.balance, icon: "creditcard.fill", tint: LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .environmentObject(localization)
                BalanceCard(title: loc("HOME_BALANCE_STAKED"), value: wallet.stakedBalance, icon: "lock.fill", tint: LinearGradient(colors: [Color("LakeBlue"), Color("LakeNight")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .environmentObject(localization)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(loc(segment.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedSegment == segment ? .black : .white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            Group {
                                if selectedSegment == segment {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white)
                                        .matchedGeometryEffect(id: "segment", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var contentForSelectedSegment: some View {
        switch selectedSegment {
        case .overview:
            overviewSection
        case .studio:
            equippedSection
        case .market:
            marketSection
        }
    }

    private var overviewSection: some View {
        VStack(spacing: 18) {
            GlassCard(title: loc("HOME_ACTIVE_THEME_TITLE"), subtitle: room.currentTheme.name, icon: "sparkles") {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc("HOME_ACTIVE_THEME_LABEL"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(themeEnergyText)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button {
                        showingInventory = true
                    } label: {
                        Label(loc("HOME_ACTIVE_THEME_BUTTON"), systemImage: "paintpalette")
                            .font(.footnote.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                }
            }

            GlassCard(title: loc("HOME_STATS_TITLE"), subtitle: loc("HOME_STATS_SUBTITLE"), icon: "flame.fill") {
                HStack(spacing: 16) {
                    StatTile(title: loc("HOME_STATS_COMPLETED"), value: completedEarnedCount)
                        .environmentObject(localization)
                    StatTile(title: loc("HOME_STATS_SPENT"), value: spentTotalText)
                        .environmentObject(localization)
                    StatTile(title: loc("HOME_STATS_PASSIVE"), value: passiveBoostText)
                        .environmentObject(localization)
                }
            }
        }
    }

    private var themeEnergyText: String {
        let bonus = min(Int(wallet.passiveIncomeBoost * 120), 100)
        return String(format: loc("HOME_THEME_BONUS"), bonus)
    }

    private var completedEarnedCount: String {
        "\(wallet.transactions.filter { $0.type == .earned }.count)"
    }

    private var spentTotalText: String {
        let total = wallet.transactions.filter { $0.type == .spent }.map { $0.amount }.reduce(0, +)
        return total.formatted(.currency(code: "TRY"))
    }

    private var passiveBoostText: String {
        "+%" + String(Int(wallet.passiveIncomeBoost * 100))
    }

    private var equippedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("HOME_STUDIO_TITLE"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(loc("HOME_STUDIO_SUBTITLE"))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Button {
                    showingInventory = true
                } label: {
                    Label(loc("HOME_BUTTON_INVENTORY"), systemImage: "capsule")
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(.white.opacity(0.15), in: Capsule())
                }
            }

            if room.placedItems.isEmpty {
                EmptyStateView(message: loc("HOME_STUDIO_EMPTY"))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    ForEach(room.placedItems) { item in
                        DecorCard(asset: item.asset) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                room.remove(assetID: item.asset.id)
                            }
                        }
                        .environmentObject(localization)
                    }
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var marketSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(loc("HOME_MARKET_TITLE"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(loc("HOME_MARKET_SUBTITLE"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }

            ForEach(room.availableMarketSections) { section in
                MarketListSectionView(section: section,
                                      isUnlocked: { room.unlockedAssets.contains($0) }) { asset in
                    selectedAsset = asset
                }
                .environmentObject(localization)
            }
        }
        .padding(24)
        .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private enum Segment: CaseIterable {
        case overview
        case studio
        case market

        var titleKey: String {
            switch self {
            case .overview: return "HOME_SEGMENT_OVERVIEW"
            case .studio: return "HOME_SEGMENT_STUDIO"
            case .market: return "HOME_SEGMENT_MARKET"
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

// MARK: - Supporting Views

private struct BalanceCard: View {
    let title: String
    let value: Double
    let icon: String
    let tint: LinearGradient
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(value, format: .currency(code: "TRY"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.65), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct GlassCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()
            }

            content
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.65))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct DecorCard: View {
    let asset: RoomAsset
    let removeAction: () -> Void
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: asset.iconName)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .padding(18)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(localizedName)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(localizedDescription)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Button(role: .destructive, action: removeAction) {
                Label(loc("HOME_DECOR_REMOVE"), systemImage: "trash")
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.12), in: Capsule())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var localizedName: String {
        loc(asset.nameKey)
    }

    private var localizedDescription: String {
        loc(asset.descriptionKey)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct MarketItemCard: View {
    let asset: RoomAsset
    let isUnlocked: Bool
    let action: () -> Void
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: asset.iconName)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 6) {
                    Text(localizedName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(asset.price, format: .currency(code: "TRY"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))

                    Text(localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                if isUnlocked {
                    Text(loc("HOME_MARKET_PURCHASED"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isUnlocked ? Color.green.opacity(0.4) : .white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isUnlocked)
        .opacity(isUnlocked ? 0.6 : 1)
    }

    private var localizedName: String {
        loc(asset.nameKey)
    }

    private var localizedDescription: String {
        loc(asset.descriptionKey)
    }

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
        VStack(alignment: .leading, spacing: 14) {
            Text(loc(section.titleKey))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 16)], spacing: 16) {
                ForEach(section.assets) { asset in
                    MarketItemCard(asset: asset,
                                   isUnlocked: isUnlocked(asset.id),
                                   action: { action(asset) })
                    .environmentObject(localization)
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
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
    let completion: (ToastMessage) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: asset.iconName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Color("ForestGreen"))
                    .padding(16)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(spacing: 6) {
                    Text(loc(asset.nameKey))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(loc(asset.descriptionKey))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                Text(asset.price, format: .currency(code: "TRY"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("ForestGreen"))

                if placementSuccess {
                    Label(loc("HOME_PURCHASE_PLACED", loc(asset.nameKey)), systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                }

                Button {
                    purchaseAndPlace()
                } label: {
                    Text(room.unlockedAssets.contains(asset.id) ? loc("HOME_PURCHASE_PLACE") : loc("HOME_PURCHASE_BUY_PLACE"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 24)
                .background(Color(.systemBackground))
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

    var body: some View {
        NavigationStack {
            Group {
                if assets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text(loc("HOME_OWNED_EMPTY"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(assets) { asset in
                            HStack(spacing: 16) {
                                Image(systemName: asset.iconName)
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(.secondarySystemFill))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(loc(asset.nameKey))
                                        .font(.headline)
                                    Text(loc(asset.descriptionKey))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(loc("HOME_PURCHASE_PLACE")) {
                                    room.place(asset: asset)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color("ForestGreen"))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("HOME_NAV_CLOSE")) { dismiss() }
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
            Image(systemName: message.style == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .padding(10)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(message.text)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(message.style == .success ? Color.green.opacity(0.85) : Color.red.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 18, y: 12)
        )
    }
}
