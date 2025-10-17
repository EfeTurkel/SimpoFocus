import SwiftUI

struct RootView: View {
    @StateObject private var rootViewModel = RootViewModel()
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var bank: BankService
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @State private var showingOnboarding = false
    @State private var hasCheckedOnboarding = false

    var body: some View {
        ZStack {
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
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

            // Bottom bar overlay (iOS 26 native style)
            VStack { Spacer() }
                .overlay(alignment: .bottom) {
                    ModernTabBar(selectedTab: $rootViewModel.selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .padding(.top, 4)
                }
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .onReceive(timer.rewardPublisher) { reward in
            wallet.earn(amount: reward.coinsReward, description: "TXN_REWARD_POMODORO")
            wallet.applyPassiveBoost(reward.passiveBoost)
        }
        .onAppear {
            // Only check onboarding status once per app launch
            if !hasCheckedOnboarding {
                hasCheckedOnboarding = true
                if !onboardingCompleted {
                    showingOnboarding = true
                }
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
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

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
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.system, edgeMask: [.all])
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(themeManager.currentTheme.glassStroke(for: colorScheme), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 20, y: 8)
        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
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
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func tabBackground(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.clear)
                    .liquidGlass(.card, edgeMask: [.all])
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(themeManager.currentTheme.glassStroke(for: colorScheme), lineWidth: 0.5)
                    )
                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
            }
        }
        .frame(width: 60, height: 50)
    }

    func tabIcon(for tab: AppTab, isSelected: Bool) -> some View {
        let iconColor: Color = {
            if isSelected {
                return themeManager.currentTheme.glassPrimaryText(for: colorScheme)
            } else {
                return themeManager.currentTheme.glassSecondaryText(for: colorScheme)
            }
        }()
        
        return Image(systemName: tab.icon)
            .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(iconColor)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }

    func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

