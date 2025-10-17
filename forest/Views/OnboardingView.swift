import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Binding var userName: String
    @Binding var onboardingCompleted: Bool
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var currentStep = 0
    @State private var focusMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var sessionsBeforeLongBreak: Double = 4
    @State private var dailyTarget: Double = 4
    @State private var autoStartBreaks = false
    @State private var notificationsEnabled = false
    @State private var selectedLanguage: AppLanguage = .english
    @FocusState private var nameFieldFocused: Bool
    
    // MARK: - Transition
    private var insertionTransition: AnyTransition { .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.98)) }
    private var removalTransition: AnyTransition { .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 1.02)) }

    private var steps: [Step] { Step.allCases }

    var body: some View {
        let step = steps[currentStep]

        ZStack {
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            // Subtle bloom accents for a premium depth (only for gradient theme)
            if themeManager.currentTheme == .gradient {
                RadialGradient(colors: [Color.white.opacity(0.08), .clear], center: .topLeading, startRadius: 60, endRadius: 300)
                    .ignoresSafeArea()
                RadialGradient(colors: [Color.white.opacity(0.06), .clear], center: .bottomTrailing, startRadius: 80, endRadius: 320)
                    .ignoresSafeArea()
            }

            VStack(spacing: 28) {
                Spacer(minLength: 0)

                ZStack {
                    VStack(spacing: 14) {
                        // Gradient-masked icon for a modern Apple-like look
                        LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .mask(
                                Image(systemName: step.icon)
                                    .font(.system(size: 76, weight: .bold))
                            )
                            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

                        Text(loc(step.titleKey))
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)

                        Text(loc(step.subtitleKey))
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                            .padding(.horizontal, 24)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                    }
                    .id(currentStep)
                    .transition(.asymmetric(insertion: insertionTransition, removal: removalTransition))
                }
                .frame(minHeight: 220)

                ZStack {
                    stepContent(for: step)
                        .id(currentStep)
                        .transition(.asymmetric(insertion: insertionTransition, removal: removalTransition))
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(minHeight: 240, alignment: .top)

                Spacer(minLength: 0)

                onboardingProgress
                    .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    if currentStep > 0 {
                        backButton
                    }
                    
                    primaryButton
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            // Set the language to device language when onboarding appears
            selectedLanguage = AppLanguage.defaultFromDevice()
            localization.language = selectedLanguage
            preloadValues()
        }
        .onChange(of: currentStep, initial: false) { _, newValue in
            if steps[newValue] == .profile {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    nameFieldFocused = true
                }
            }
        }
    }

    private func preloadValues() {
        focusMinutes = Double(timer.focusDuration) / 60
        shortBreakMinutes = Double(timer.shortBreakDuration) / 60
        longBreakMinutes = Double(timer.longBreakDuration) / 60
        sessionsBeforeLongBreak = Double(timer.sessionsBeforeLongBreak)
        dailyTarget = Double(market.dailyTarget)
        autoStartBreaks = timer.autoStartBreaks
        notificationsEnabled = timer.notificationsEnabled
    }

    private var onboardingProgress: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.white : Color.white.opacity(0.25))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
        .padding(10)
        .background(
            Capsule().fill(Color.clear)
        )
        .liquidGlass(.header, edgeMask: [.all])
        .clipShape(Capsule())
    }

    private var primaryButton: some View {
        Button(action: nextStep) {
            Text(currentStep == steps.count - 1 ? loc("ONBOARD_PRIMARY_START") : loc("ONBOARD_PRIMARY_NEXT"))
                .font(.headline.weight(.semibold))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .onGlassPrimary()
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
        }
        .disabled(steps[currentStep] == .profile && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(steps[currentStep] == .profile && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }
    
    private var backButton: some View {
        Button(action: previousStep) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                Text(loc("ONBOARD_BACK"))
                    .font(.headline.weight(.semibold))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
            )
            .liquidGlass(.card, edgeMask: [.all])
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onGlassPrimary()
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        }
    }

    @ViewBuilder
    private func stepContent(for step: Step) -> some View {
        switch step {
        case .welcome:
            WelcomeCard()
                .environmentObject(localization)
        case .theme:
            ThemeSelectionCard()
        case .focus:
            VStack(spacing: 18) {
                OnboardingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(loc("ONBOARD_FOCUS_DURATION", Int(focusMinutes)))
                                .font(.headline)
                            Spacer()
                        }
                        Slider(value: $focusMinutes, in: 15...60, step: 5)
                            .tint(Color("ForestGreen"))
                    }
                }

                OnboardingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(loc("ONBOARD_DAILY_TARGET"))
                            .font(.headline)
                        Stepper(loc("ONBOARD_DAILY_TARGET_VALUE", Int(dailyTarget)), value: $dailyTarget, in: 2...12, step: 1)
                    }
                }
            }
        case .breaks:
            VStack(spacing: 18) {
                OnboardingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(loc("ONBOARD_SHORT_BREAK", Int(shortBreakMinutes)))
                            .font(.headline)
                        Slider(value: $shortBreakMinutes, in: 3...15, step: 1)
                            .tint(Color("LakeBlue"))
                        Text(loc("ONBOARD_LONG_BREAK", Int(longBreakMinutes)))
                            .font(.headline)
                        Slider(value: $longBreakMinutes, in: 10...30, step: 1)
                            .tint(Color("LakeNight"))
                    }
                }

                OnboardingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Stepper(loc("ONBOARD_BEFORE_LONG_BREAK", Int(sessionsBeforeLongBreak)), value: $sessionsBeforeLongBreak, in: 2...10, step: 1)
                        Toggle(loc("ONBOARD_AUTO_BREAKS"), isOn: $autoStartBreaks)
                            .toggleStyle(.switch)
                    }
                }
            }
        case .finance:
            FinanceCard()
                .environmentObject(localization)
        case .home:
            HomeCard()
                .environmentObject(localization)
        case .notifications:
            OnboardingCard {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(loc("ONBOARD_NOTIFICATIONS_TOGGLE"), isOn: $notificationsEnabled)
                        .toggleStyle(.switch)
                    Text(loc("ONBOARD_NOTIFICATIONS_DESC"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        case .language:
            LanguageCard(selectedLanguage: $selectedLanguage)
                .environmentObject(localization)
        case .profile:
            ProfileCard(userName: $userName,
                        nameFieldFocused: _nameFieldFocused,
                        finishAction: attemptFinish)
                .environmentObject(localization)
        }
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                currentStep += 1
            }
        } else {
            attemptFinish()
        }
    }
    
    private func previousStep() {
        if currentStep > 0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                currentStep -= 1
            }
        }
    }

    private func attemptFinish() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userName = trimmed

        timer.adjustDurations(focus: Int(focusMinutes * 60),
                              shortBreak: Int(shortBreakMinutes * 60),
                              longBreak: Int(longBreakMinutes * 60))
        timer.sessionsBeforeLongBreak = Int(sessionsBeforeLongBreak)
        timer.autoStartBreaks = autoStartBreaks
        timer.notificationsEnabled = notificationsEnabled
        market.dailyTarget = Int(dailyTarget)

        localization.language = selectedLanguage

        onboardingCompleted = true
        isPresented = false
    }

    private struct OnboardingCard<Content: View>: View {
        @ViewBuilder var content: Content

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.clear)
            )
            .liquidGlass(.card, edgeMask: [.all])
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        }
    }

    private struct WelcomeCard: View {
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            VStack(spacing: 16) {
                // Keep a single, concise welcome to avoid clutter
                Text(loc("ONBOARD_WELCOME_DESC"))
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .onGlassPrimary()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.white.opacity(0.08))
                    )
            }
            .padding(.horizontal, 24)
        }

        private func loc(_ key: String, _ arguments: CVarArg...) -> String {
            localization.translate(key, fallback: key, arguments: arguments)
        }
    }

    private struct FinanceCard: View {
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            OnboardingCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label(loc("ONBOARD_FINANCE_EARN"), systemImage: "bolt.fill")
                        .font(.headline)
                    Text(loc("ONBOARD_FINANCE_EARN_DESC"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Divider().blendMode(.overlay)
                    Label(loc("ONBOARD_FINANCE_BANK"), systemImage: "building.columns")
                        .font(.headline)
                    Text(loc("ONBOARD_FINANCE_BANK_DESC"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Divider().blendMode(.overlay)
                    Label(loc("ONBOARD_FINANCE_MARKET"), systemImage: "cart.fill")
                        .font(.headline)
                    Text(loc("ONBOARD_FINANCE_MARKET_DESC"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }

        private func loc(_ key: String, _ arguments: CVarArg...) -> String {
            localization.translate(key, fallback: key, arguments: arguments)
        }
    }

    private struct HomeCard: View {
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            OnboardingCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label(loc("ONBOARD_HOME_CUSTOMIZE"), systemImage: "house.fill")
                        .font(.headline)
                    Text(loc("ONBOARD_HOME_CUSTOMIZE_DESC"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Divider().blendMode(.overlay)
                    Label(loc("ONBOARD_HOME_THEMES"), systemImage: "sparkles")
                        .font(.headline)
                    Text(loc("ONBOARD_HOME_THEMES_DESC"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }

        private func loc(_ key: String, _ arguments: CVarArg...) -> String {
            localization.translate(key, fallback: key, arguments: arguments)
        }
    }

    private struct LanguageCard: View {
        @Binding var selectedLanguage: AppLanguage
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            OnboardingCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text(loc("ONBOARD_LANGUAGE_TITLE"))
                        .font(.headline)
                    Text(loc("ONBOARD_LANGUAGE_DESCRIPTION"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Picker(loc("ONBOARD_LANGUAGE_TITLE"), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(loc("ONBOARD_LANGUAGE_NOTE"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        private func loc(_ key: String, _ arguments: CVarArg...) -> String {
            localization.translate(key, fallback: key, arguments: arguments)
        }
    }

    private struct ProfileCard: View {
        @Binding var userName: String
        @FocusState var nameFieldFocused: Bool
        let finishAction: () -> Void
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            OnboardingCard {
                VStack(spacing: 16) {
                    TextField(loc("ONBOARD_NAME_PROMPT"), text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3.weight(.semibold))
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { finishAction() }

                    Text(loc("ONBOARD_NAME_HINT"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 4)
            }
        }

        private func loc(_ key: String, _ arguments: CVarArg...) -> String {
            localization.translate(key, fallback: key, arguments: arguments)
        }
    }

    private enum Step: Int, CaseIterable {
        case welcome
        case theme
        case focus
        case breaks
        case finance
        case home
        case notifications
        case language
        case profile

        var icon: String {
            switch self {
            case .welcome: return "sparkles"
            case .theme: return "paintpalette.fill"
            case .focus: return "timer"
            case .breaks: return "bed.double"
            case .finance: return "banknote"
            case .home: return "house.fill"
            case .notifications: return "bell.badge.fill"
            case .language: return "globe"
            case .profile: return "person.fill"
            }
        }

        var titleKey: String {
            switch self {
            case .welcome: return "ONBOARD_STEP_WELCOME"
            case .theme: return "ONBOARD_STEP_THEME"
            case .focus: return "ONBOARD_STEP_FOCUS"
            case .breaks: return "ONBOARD_STEP_BREAKS"
            case .finance: return "ONBOARD_STEP_FINANCE"
            case .home: return "ONBOARD_STEP_HOME"
            case .notifications: return "ONBOARD_STEP_NOTIFICATIONS"
            case .language: return "ONBOARD_LANGUAGE_TITLE"
            case .profile: return "ONBOARD_STEP_PROFILE"
            }
        }

        var subtitleKey: String {
            switch self {
            case .welcome: return "ONBOARD_SUB_WELCOME"
            case .theme: return "ONBOARD_SUB_THEME"
            case .focus: return "ONBOARD_SUB_FOCUS"
            case .breaks: return "ONBOARD_SUB_BREAKS"
            case .finance: return "ONBOARD_SUB_FINANCE"
            case .home: return "ONBOARD_SUB_HOME"
            case .notifications: return "ONBOARD_SUB_NOTIFICATIONS"
            case .language: return "ONBOARD_LANGUAGE_DESCRIPTION"
            case .profile: return "ONBOARD_SUB_PROFILE"
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

// MARK: - Theme Selection Card
private struct ThemeSelectionCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    private let themes: [AppTheme] = [.system, .light, .gradient, .oledDark]
    
    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(themes, id: \.self) { theme in
                    ThemeOptionCard(theme: theme, isSelected: themeManager.currentTheme == theme) {
                        themeManager.currentTheme = theme
                    }
                }
            }
        }
    }
}

// MARK: - Theme Option Card
private struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Theme preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.getBackgroundGradient(for: colorScheme))
                    .frame(height: 80)
                    .overlay(
                        VStack(spacing: 4) {
                            Circle()
                                .fill(theme.getPrimaryTextColor(for: colorScheme))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(theme.getPrimaryTextColor(for: colorScheme))
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(theme.getPrimaryTextColor(for: colorScheme))
                                .frame(width: 4, height: 4)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color("ForestGreen") : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                Text(theme.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.getPrimaryTextColor(for: colorScheme))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
