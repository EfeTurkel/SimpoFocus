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

            VStack(spacing: 0) {
                TabContentView(selectedTab: rootViewModel.selectedTab)
                    .environmentObject(timer)
                    .environmentObject(wallet)
                    .environmentObject(market)
                    .environmentObject(room)
                    .environmentObject(bank)
                    .environmentObject(LocalizationManager.shared)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 30)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

                ModernTabBar(selectedTab: $rootViewModel.selectedTab)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
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
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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
        .padding(.horizontal, 14)
        .background(
            ZStack {
                LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom), lineWidth: 1.1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 18, y: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
        )
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
        VStack(spacing: 6) {
            tabBackground(isSelected: isSelected)
                .overlay(tabIcon(for: tab, isSelected: isSelected))

            Text(loc(tab.titleKey, fallback: tab.defaultTitle))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func tabBackground(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.18)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                    )
                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
            }

            Circle()
                .fill(Color.white.opacity(isSelected ? 0.95 : 0.3))
                .frame(width: 38, height: 38)
                .blur(radius: 8)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 52, height: 44)
    }

    func tabIcon(for tab: AppTab, isSelected: Bool) -> some View {
        Image(systemName: tab.icon)
            .font(.title3.weight(.semibold))
            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.7))
    }

    func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

