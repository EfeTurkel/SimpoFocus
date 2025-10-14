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
        .onAppear {
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
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tabBarBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(tabBarStroke, lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    private var tabBarBackground: Color {
        let theme = themeManager.currentTheme
        switch theme {
        case .system:
            return colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.95)
        case .gradient:
            return Color("ForestGreen").opacity(0.7)
        case .oledDark:
            return Color.black.opacity(0.8)
        case .light:
            return Color.white.opacity(0.95)
        }
    }
    
    private var tabBarStroke: Color {
        let theme = themeManager.currentTheme
        switch theme {
        case .system:
            return colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.25)
        case .gradient:
            return Color("LakeBlue").opacity(0.4)
        case .oledDark:
            return Color.white.opacity(0.2)
        case .light:
            return Color.black.opacity(0.25)
        }
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
                let theme = themeManager.currentTheme
                let bgColors: [Color] = {
                    switch theme {
                    case .system:
                        return colorScheme == .dark 
                            ? [Color.white.opacity(0.25), Color.white.opacity(0.1)]
                            : [Color.black.opacity(0.18), Color.black.opacity(0.08)]
                    case .gradient:
                        return [Color("LakeBlue").opacity(0.4), Color("ForestGreen").opacity(0.3)]
                    case .oledDark:
                        return [Color.white.opacity(0.25), Color.white.opacity(0.1)]
                    case .light:
                        return [Color.black.opacity(0.18), Color.black.opacity(0.08)]
                    }
                }()
                
                let strokeColor: Color = {
                    switch theme {
                    case .system:
                        return colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
                    case .gradient:
                        return Color.white.opacity(0.5)
                    case .oledDark:
                        return Color.white.opacity(0.3)
                    case .light:
                        return Color.black.opacity(0.3)
                    }
                }()
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: bgColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(strokeColor, lineWidth: 0.5)
                    )
                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
            }
        }
        .frame(width: 50, height: 44)
    }

    func tabIcon(for tab: AppTab, isSelected: Bool) -> some View {
        let theme = themeManager.currentTheme
        let iconColor: Color = {
            switch theme {
            case .system:
                if isSelected {
                    return colorScheme == .dark ? .white : .black
                } else {
                    return colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.55)
                }
            case .gradient:
                return isSelected ? .white : Color.white.opacity(0.7)
            case .oledDark:
                return isSelected ? .white : Color.white.opacity(0.6)
            case .light:
                return isSelected ? .black : Color.black.opacity(0.55)
            }
        }()
        
        return Image(systemName: tab.icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(iconColor)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    func loc(_ key: String, fallback: String) -> String {
        localization.translate(key, fallback: fallback)
    }
}

