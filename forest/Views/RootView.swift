import SwiftUI

struct RootView: View {
    @StateObject private var rootViewModel = RootViewModel()
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var bank: BankService
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("paywallLaunchCount") private var paywallLaunchCount: Int = 0
    @AppStorage("paywallLastShownDate") private var paywallLastShownDate: String = ""
    @AppStorage("specialOfferLastMilestoneShown") private var specialOfferLastMilestoneShown: Int = 0
    @AppStorage("specialOfferMilestoneShowCount") private var specialOfferMilestoneShowCount: Int = 0
    @AppStorage("lifetimeOfferShown") private var lifetimeOfferShown: Bool = false
    @AppStorage("proWelcomeBonusGranted") private var proWelcomeBonusGranted: Bool = false
    @AppStorage("proMonthlyBonusLastYearMonth") private var proMonthlyBonusLastYearMonth: String = ""
    @State private var showingOnboarding = false
    @State private var hasCheckedOnboarding = false
    @State private var showLaunchPaywall = false
    @State private var showSpecialOffer = false
    @State private var showLifetimeOffer = false
    @State private var persistenceError: String?
    @State private var waitingForCloudBootstrap = true

    var body: some View {
        ZStack {
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            TabContentView(selectedTab: rootViewModel.selectedTab)
                .environmentObject(timer)
                .environmentObject(wallet)
                .environmentObject(market)
                .environmentObject(room)
                .environmentObject(bank)
                .environmentObject(LocalizationManager.shared)
                .environmentObject(StoreKitService.shared)
                .environmentObject(EntitlementManager.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(rootViewModel.selectedTab)
                .transition(.opacity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ModernTabBar(selectedTab: $rootViewModel.selectedTab)
                }
        }
        .preferredColorScheme(themeManager.currentTheme.colorSchemeOverride)
        .onReceive(timer.rewardPublisher) { reward in
            let adjustedReward = reward.coinsReward * wallet.currentEarningMultiplier
            wallet.earn(amount: adjustedReward, description: "TXN_REWARD_POMODORO")
            wallet.applyPassiveBoost(reward.passiveBoost)
        }
        .onChange(of: timer.totalCompletedSessions) { _, newValue in
            maybePresentLifetimeOffer(for: newValue)
            maybePresentSpecialOffer(for: newValue)
        }
        .onChange(of: entitlements.isPro) { _, isPro in
            if isPro {
                grantProWelcomeBonusIfNeeded()
                grantProMonthlyBonusIfNeeded()
            }
        }
        .onAppear {
            if !hasCheckedOnboarding {
                waitingForCloudBootstrap = !PersistenceController.shared.didFinishInitialCloudSync
                guard !waitingForCloudBootstrap else { return }
                hasCheckedOnboarding = true
                if !onboardingCompleted {
                    showingOnboarding = true
                } else {
                    presentLaunchPaywallIfNeeded()
                    maybePresentSpecialOffer(for: timer.totalCompletedSessions)
                    if entitlements.isPro {
                        grantProWelcomeBonusIfNeeded()
                        grantProMonthlyBonusIfNeeded()
                    }
                }
            }
        }
        .onReceive(PersistenceController.shared.$didFinishInitialCloudSync) { done in
            guard done else { return }
            guard !hasCheckedOnboarding else { return }
            waitingForCloudBootstrap = false
            hasCheckedOnboarding = true
            if !onboardingCompleted {
                showingOnboarding = true
            } else {
                presentLaunchPaywallIfNeeded()
                maybePresentSpecialOffer(for: timer.totalCompletedSessions)
                if entitlements.isPro {
                    grantProWelcomeBonusIfNeeded()
                    grantProMonthlyBonusIfNeeded()
                }
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding,
                           userName: $userName,
                           onboardingCompleted: $onboardingCompleted)
        }
        .onChange(of: showingOnboarding) { _, isShowing in
            if !isShowing && onboardingCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    presentLaunchPaywallIfNeeded()
                }
            }
        }
        .fullScreenCover(isPresented: $showLaunchPaywall) {
            PaywallView(onDismissedWithoutPurchase: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    maybePresentSpecialOffer(for: timer.totalCompletedSessions)
                }
            })
        }
        .fullScreenCover(isPresented: $showSpecialOffer) {
            SpecialOfferView()
        }
        .fullScreenCover(isPresented: $showLifetimeOffer) {
            LifetimeOfferView()
        }
        .onReceive(PersistenceController.shared.$lastSaveError.compactMap { $0 }) { error in
            persistenceError = error
            PersistenceController.shared.lastSaveError = nil
        }
        .alert("Save Error", isPresented: .init(
            get: { persistenceError != nil },
            set: { if !$0 { persistenceError = nil } }
        )) {
            Button("OK", role: .cancel) { persistenceError = nil }
        } message: {
            Text(persistenceError ?? "")
        }
    }

    private func presentLaunchPaywallIfNeeded() {
        guard !entitlements.isPro else { return }
        let todayString = formattedToday()
        if paywallLaunchCount < 3 {
            paywallLaunchCount += 1
            paywallLastShownDate = todayString
            showLaunchPaywall = true
        } else if paywallLastShownDate != todayString {
            paywallLastShownDate = todayString
            showLaunchPaywall = true
        }
    }

    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func currentYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    private func maybePresentSpecialOffer(for totalCompletedSessions: Int) {
        guard !entitlements.isPro else { return }
        guard onboardingCompleted, !showingOnboarding else { return }
        guard !showLaunchPaywall else { return }
        guard !showSpecialOffer else { return }
        guard !showLifetimeOffer else { return }
        
        let milestones: Set<Int> = [10, 100, 1000]
        guard milestones.contains(totalCompletedSessions) else { return }
        if totalCompletedSessions != specialOfferLastMilestoneShown {
            specialOfferLastMilestoneShown = totalCompletedSessions
            specialOfferMilestoneShowCount = 0
        }
        // Show up to 3 times for the active milestone (e.g. right after install).
        guard specialOfferMilestoneShowCount < 3 else { return }

        specialOfferMilestoneShowCount += 1
        showSpecialOffer = true
    }

    private func maybePresentLifetimeOffer(for totalCompletedSessions: Int) {
        guard !entitlements.isPro else { return }
        guard onboardingCompleted, !showingOnboarding else { return }
        guard !showLaunchPaywall else { return }
        guard !showSpecialOffer else { return }
        guard !showLifetimeOffer else { return }
        guard totalCompletedSessions == 1 else { return }
        guard !lifetimeOfferShown else { return }

        lifetimeOfferShown = true
        showLifetimeOffer = true
    }

    private func grantProWelcomeBonusIfNeeded() {
        guard entitlements.isPro else { return }
        guard !proWelcomeBonusGranted else { return }
        proWelcomeBonusGranted = true
        wallet.earn(amount: 2000, description: "TXN_PRO_WELCOME_BONUS")
    }

    private func grantProMonthlyBonusIfNeeded() {
        guard entitlements.isPro else { return }
        let ym = currentYearMonth()
        guard proMonthlyBonusLastYearMonth != ym else { return }
        proMonthlyBonusLastYearMonth = ym
        wallet.earn(amount: 1000, description: "TXN_PRO_MONTHLY_BONUS")
    }
}

private struct TabContentView: View {
    let selectedTab: AppTab

    var body: some View {
        Group {
            switch selectedTab {
            case .forest: FocusView()
            case .finance: FinanceView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Apple Music Style Tab Bar

private struct ModernTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var selectionAnimation
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(themeManager.currentTheme.getCardStroke(for: colorScheme))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    let isSelected = tab == selectedTab
                    Button(action: { select(tab) }) {
                        tabLabel(for: tab, isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(loc(tab.titleKey, fallback: tab.defaultTitle))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial)
    }

    private func select(_ tab: AppTab) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.78)) {
            selectedTab = tab
        }
    }

    @ViewBuilder
    private func tabLabel(for tab: AppTab, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color("ForestGreen").opacity(0.12))
                        .matchedGeometryEffect(id: "tabBg", in: selectionAnimation)
                }

                Image(systemName: isSelected ? tab.filledIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color("ForestGreen") : themeManager.currentTheme.glassSecondaryText(for: colorScheme))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: selectedTab)
            }
            .frame(width: 56, height: 32)

            Text(loc(tab.titleKey, fallback: tab.defaultTitle))
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isSelected ? themeManager.currentTheme.getPrimaryTextColor(for: colorScheme) : themeManager.currentTheme.glassSecondaryText(for: colorScheme))
        }
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }

    private func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}
