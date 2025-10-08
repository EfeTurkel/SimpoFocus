import SwiftUI

struct RootView: View {
    @StateObject private var rootViewModel = RootViewModel()
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var bank: BankService
    @EnvironmentObject private var localization: LocalizationManager
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @State private var showingOnboarding = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("ForestGreen"), Color("LakeNight")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content fills the screen; tab bar overlays with translucent glass effect
            TabContentView(selectedTab: rootViewModel.selectedTab)
                .environmentObject(timer)
                .environmentObject(wallet)
                .environmentObject(market)
                .environmentObject(room)
                .environmentObject(bank)
                .environmentObject(LocalizationManager.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 0)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            // Bottom bar overlay (thin style)
            VStack { Spacer() }
                .overlay(alignment: .bottom) {
                    ModernTabBar(selectedTab: $rootViewModel.selectedTab)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .onReceive(timer.rewardPublisher) { reward in
            wallet.earn(amount: reward.coinsReward, description: "TXN_REWARD_POMODORO")
            wallet.applyPassiveBoost(reward.passiveBoost)
        }
        .task(id: rootViewModel.selectedTab) {
            if rootViewModel.selectedTab == .market {
                market.refreshPrices()
            }
        }
        .onAppear {
            market.refreshPrices()
            if !onboardingCompleted {
                showingOnboarding = true
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding,
                           userName: $userName,
                           onboardingCompleted: $onboardingCompleted)
        }
    }
}

private struct TabContentView: View {
    let selectedTab: AppTab

    var body: some View {
        Group {
            switch selectedTab {
            case .forest:
                FocusView()
            case .market:
                MarketView()
            case .bank:
                BankView()
            case .wallet:
                WalletView()
            case .home:
                HomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ModernTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var selectionAnimation
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = tab == selectedTab

                Button(action: { select(tab) }, label: { tabLabel(for: tab, isSelected: isSelected) })
                    .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

private extension ModernTabBar {
    func select(_ tab: AppTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            selectedTab = tab
        }
    }

    @ViewBuilder
    func tabLabel(for tab: AppTab, isSelected: Bool) -> some View {
        ZStack {
            tabBackground(isSelected: isSelected)
                .overlay(tabIcon(for: tab, isSelected: isSelected))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func tabBackground(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
            }
        }
        .frame(width: 50, height: 44)
    }

    func tabIcon(for tab: AppTab, isSelected: Bool) -> some View {
        Image(systemName: tab.icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.8))
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

