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
    @State private var isForward = true
    
    // MARK: - Transition
    private var insertionTransition: AnyTransition {
        .opacity.combined(with: .move(edge: isForward ? .trailing : .leading))
    }
    private var removalTransition: AnyTransition {
        .opacity.combined(with: .move(edge: isForward ? .leading : .trailing))
    }

    private var steps: [Step] { Step.allCases }

    var body: some View {
        let step = steps[currentStep]

        ZStack {
            themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: DS.Padding.section * 2) {
                Spacer(minLength: 0)

                ZStack {
                    VStack(spacing: DS.Padding.section) {
                        // Gradient-masked icon for a modern Apple-like look
                        Image(systemName: step.icon)
                            .font(.system(size: 88, weight: .bold))
                            .foregroundStyle(Color("ForestGreen"))

                        Text(loc(step.titleKey))
                            .font(DS.Typography.heroTitle)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, DS.Padding.screen)

                        Text(loc(step.subtitleKey))
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                            .padding(.horizontal, DS.Padding.screen)
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
                .padding(.horizontal, DS.Padding.screen)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(minHeight: 240, alignment: .top)

                Spacer(minLength: 0)

                onboardingProgress
                    .padding(.horizontal, DS.Padding.screen)

                HStack(spacing: DS.Padding.card) {
                    if currentStep > 0 {
                        backButton
                    }
                    
                    primaryButton
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, DS.Padding.screen)
                .padding(.bottom, DS.Padding.xl)
            }
        }
        .interactiveDismissDisabled(true)
        .preferredColorScheme(themeManager.currentTheme.colorSchemeOverride)
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
        HStack(spacing: DS.Padding.element) {
            ForEach(steps.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color("ForestGreen") : Color("ForestGreen").opacity(0.25))
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: nextStep) {
            Text(currentStep == steps.count - 1 ? loc("ONBOARD_PRIMARY_START") : loc("ONBOARD_PRIMARY_NEXT"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, DS.Padding.card)
                .frame(maxWidth: .infinity)
                .background(Color("ForestGreen"), in: RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
        }
        .disabled(steps[currentStep] == .profile && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(steps[currentStep] == .profile && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }
    
    private var backButton: some View {
        Button(action: previousStep) {
            HStack(spacing: DS.Padding.element) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                Text(loc("ONBOARD_BACK"))
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
            .padding(.vertical, DS.Padding.card)
            .padding(.horizontal, DS.Padding.screen)
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
            VStack(spacing: DS.Padding.section + DS.Padding.element) {
                OnboardingCard {
                    VStack(alignment: .leading, spacing: DS.Padding.section) {
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
                    VStack(alignment: .leading, spacing: DS.Padding.section) {
                        Text(loc("ONBOARD_DAILY_TARGET"))
                            .font(.headline)
                        Stepper(loc("ONBOARD_DAILY_TARGET_VALUE", Int(dailyTarget)), value: $dailyTarget, in: 2...12, step: 1)
                    }
                }
            }
        case .breaks:
            VStack(spacing: DS.Padding.section + DS.Padding.element) {
                OnboardingCard {
                    VStack(alignment: .leading, spacing: DS.Padding.section) {
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
                    VStack(alignment: .leading, spacing: DS.Padding.section) {
                        Stepper(loc("ONBOARD_BEFORE_LONG_BREAK", Int(sessionsBeforeLongBreak)), value: $sessionsBeforeLongBreak, in: 2...10, step: 1)
                        Toggle(loc("ONBOARD_AUTO_BREAKS"), isOn: $autoStartBreaks)
                            .toggleStyle(.switch)
                    }
                }
            }
        case .finance:
            FinanceCard()
                .environmentObject(localization)
        case .notifications:
            OnboardingCard {
                VStack(alignment: .leading, spacing: DS.Padding.section + DS.Padding.element) {
                    Toggle(loc("ONBOARD_NOTIFICATIONS_TOGGLE"), isOn: $notificationsEnabled)
                        .toggleStyle(.switch)
                    Text(loc("ONBOARD_NOTIFICATIONS_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
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
            isForward = true
            withAnimation(DS.Animation.slowSpring) {
                currentStep += 1
            }
        } else {
            attemptFinish()
        }
    }
    
    private func previousStep() {
        if currentStep > 0 {
            isForward = false
            withAnimation(DS.Animation.slowSpring) {
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
            VStack(alignment: .leading, spacing: DS.Padding.section) {
                content
            }
            .padding(DS.Padding.card + DS.Padding.section)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .fill(Color.clear)
            )
            .liquidGlass(.card, edgeMask: [.all])
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
        }
    }

    private struct WelcomeCard: View {
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            VStack(spacing: DS.Padding.card) {
                Text(loc("ONBOARD_WELCOME_DESC"))
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .onGlassPrimary()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                            .fill(.clear)
                    )
                    .liquidGlass(.card, edgeMask: [.all])
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            }
            .padding(.horizontal, DS.Padding.screen)
        }

        private func loc(_ key: String, _ arguments: CVarArg...) -> String {
            localization.translate(key, fallback: key, arguments: arguments)
        }
    }

    private struct FinanceCard: View {
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            OnboardingCard {
                VStack(alignment: .leading, spacing: DS.Padding.section) {
                    Label(loc("ONBOARD_FINANCE_EARN"), systemImage: "bolt.fill")
                        .font(.headline)
                    Text(loc("ONBOARD_FINANCE_EARN_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
                    Divider().blendMode(.overlay)
                    Label(loc("ONBOARD_FINANCE_BANK"), systemImage: "building.columns")
                        .font(.headline)
                    Text(loc("ONBOARD_FINANCE_BANK_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
                    Divider().blendMode(.overlay)
                    Label(loc("ONBOARD_FINANCE_MARKET"), systemImage: "cart.fill")
                        .font(.headline)
                    Text(loc("ONBOARD_FINANCE_MARKET_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
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
                VStack(alignment: .leading, spacing: DS.Padding.section) {
                    Label(loc("ONBOARD_HOME_CUSTOMIZE"), systemImage: "house.fill")
                        .font(.headline)
                    Text(loc("ONBOARD_HOME_CUSTOMIZE_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
                    Divider().blendMode(.overlay)
                    Label(loc("ONBOARD_HOME_THEMES"), systemImage: "sparkles")
                        .font(.headline)
                    Text(loc("ONBOARD_HOME_THEMES_DESC"))
                        .font(.footnote)
                        .onGlassSecondary()
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
                        .onGlassSecondary()

                    Picker(loc("ONBOARD_LANGUAGE_TITLE"), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(loc("ONBOARD_LANGUAGE_NOTE"))
                        .font(.caption)
                        .onGlassSecondary()
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
                VStack(spacing: DS.Padding.card) {
                    TextField(loc("ONBOARD_NAME_PROMPT"), text: $userName)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .onGlassPrimary()
                        .padding(.horizontal, DS.Padding.section)
                        .padding(.vertical, DS.Padding.element)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                                .fill(.clear)
                        )
                        .liquidGlass(.card, edgeMask: .all)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { finishAction() }

                    Text(loc("ONBOARD_NAME_HINT"))
                        .font(.caption)
                        .onGlassSecondary()
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, DS.Padding.element)
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
                        themeManager.setTheme(theme)
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
                RoundedRectangle(cornerRadius: DS.Radius.small)
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
                        RoundedRectangle(cornerRadius: DS.Radius.small)
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
