import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Binding var userName: String
    @Binding var onboardingCompleted: Bool
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager

    @State private var currentStep = 0
    @State private var focusMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var sessionsBeforeLongBreak: Double = 4
    @State private var dailyTarget: Double = 4
    @State private var autoStartBreaks = false
    @State private var notificationsEnabled = false
    @State private var selectedLanguage: AppLanguage = LocalizationManager.shared.language
    @FocusState private var nameFieldFocused: Bool

    private var steps: [Step] { Step.allCases }

    var body: some View {
        let step = steps[currentStep]

        ZStack {
            LinearGradient(colors: [Color("ForestGreen"), Color("LakeNight")],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 0)

                Image(systemName: step.icon)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 12)
                    .transition(.scale.combined(with: .opacity))

                VStack(spacing: 10) {
                    Text(loc(step.titleKey))
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text(loc(step.subtitleKey))
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 24)
                }

                stepContent(for: step)
                    .padding(.horizontal, 24)

                Spacer(minLength: 0)

                onboardingProgress
                    .padding(.horizontal, 24)

                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear(perform: preloadValues)
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
                .foregroundStyle(.black)
        }
        .disabled(steps[currentStep] == .profile && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(steps[currentStep] == .profile && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }

    @ViewBuilder
    private func stepContent(for step: Step) -> some View {
        switch step {
        case .welcome:
            WelcomeCard()
                .environmentObject(localization)
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
            withAnimation(.easeInOut) {
                currentStep += 1
            }
        } else {
            attemptFinish()
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
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
    }

    private struct WelcomeCard: View {
        @EnvironmentObject private var localization: LocalizationManager

        var body: some View {
            VStack(spacing: 16) {
                Text(loc("ONBOARD_WELCOME_DESC"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding()
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
            case .welcome: return "Simpo'ya Hoş Geldin"
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
            case .welcome: return "Odak süreni Simpo ile yönet. Birkaç adımda kişiselleştirelim."
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
