import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingCategoryPicker = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("FOCUS_NOW"))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                    Text(timer.phase.displayName(using: localization))
                        .font(.title.weight(.bold))
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        showingStats.toggle()
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(12)
                            .background(.white.opacity(0.85), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.4)))
                    }

                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(12)
                            .background(.white.opacity(0.85), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.4)))
                    }
                }
            }

            let subtitleKey = timer.phase.isFocus ? "FOCUS_SUBTITLE_FOCUS" : "FOCUS_SUBTITLE_BREAK"
            TimerCard(remainingSeconds: timer.remainingSeconds,
                      subtitle: loc(subtitleKey))
                .padding(.top, 8)
            
            // Category selector (only show during focus)
            if timer.phase == .focus {
                CategorySelector(
                    selectedCategory: timer.selectedCategory,
                    onTap: { showingCategoryPicker = true }
                )
                .environmentObject(localization)
            }

            CompactSoundToggle(isOn: Binding(get: { timer.tickingEnabled }, set: { timer.tickingEnabled = $0 }),
                               title: loc("SOUND_TITLE"),
                               onText: loc("STATE_ON"),
                               offText: loc("STATE_OFF"))

#if canImport(UIKit)
            if timer.shouldPromptBackgroundRefresh {
                BackgroundRefreshPrompt()
                    .environmentObject(timer)
                    .environmentObject(localization)
            }
#endif

            ControlStack(timer: timer)

            ProgressSection(streak: timer.streak,
                            completed: timer.completedFocusSessions,
                            phase: timer.phase,
                            timer: timer,
                            dailyTarget: market.dailyTarget)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        // Align bottom spacing with other tabs; root adds shared bottom padding
        .padding(.bottom, 0)
        .sheet(isPresented: $showingSettings) {
            TimerSettingsView()
        }
        .sheet(isPresented: $showingStats) {
            YearlyAnalyticsView()
                .environmentObject(timer)
                .environmentObject(localization)
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(selectedCategory: $timer.selectedCategory)
                .environmentObject(localization)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension FocusView {
    func loc(_ key: String, fallback: String? = nil, arguments: CVarArg... ) -> String {
        localization.translate(key, fallback: fallback, arguments: arguments)
    }
}

#if canImport(UIKit)
private struct BackgroundRefreshPrompt: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color("LakeBlue"))
                    .font(.title3)
                Text(loc("FOCUS_BACKGROUND_REFRESH_TITLE"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            }

            Text(loc("FOCUS_BACKGROUND_REFRESH_MESSAGE"))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))

            Button {
                openSettings()
                timer.acknowledgeBackgroundRefreshPrompt()
            } label: {
                Text(loc("FOCUS_BACKGROUND_REFRESH_BUTTON"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color("LakeBlue"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("LakeBlue").opacity(0.4), lineWidth: 1)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, arguments: arguments)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
#endif

private struct TimerCard: View {
    let remainingSeconds: Int
    let subtitle: String
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 18) {
            Text(formattedTime(remainingSeconds))
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                .shadow(radius: 12)

            Text(subtitle)
                .font(.footnote.weight(.medium))
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(themeManager.currentTheme.cardBackground(for: colorScheme).opacity(themeManager.currentTheme == .gradient ? 2.5 : 1))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
        )
    }

    private func formattedTime(_ seconds: Int) -> String {
        guard seconds > 0 else { return "00:00" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

private struct CompactSoundToggle: View {
    @Binding var isOn: Bool
    let title: String
    let onText: String
    let offText: String
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                .frame(width: 44, height: 44)
                .background(themeManager.currentTheme.cardBackground(for: colorScheme).opacity(1.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                Text(isOn ? onText : offText)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color("ForestGreen"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(themeManager.currentTheme.cardBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
        )
    }
}

private struct ControlStack: View {
    @ObservedObject var timer: PomodoroTimerService
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 12) {
            ControlButton(title: loc(timer.isRunning ? "CONTROL_PAUSE" : "CONTROL_START"), icon: timer.isRunning ? "pause.fill" : "play.fill", style: .primary) {
                timer.isRunning ? timer.pause() : timer.start()
            }

            ControlButton(title: loc("CONTROL_SKIP"), icon: "forward.end.fill", style: .secondary) {
                timer.skipPhase()
            }

            ControlButton(title: loc("CONTROL_RESET"), icon: "arrow.counterclockwise", style: .tertiary) {
                timer.reset()
            }
        }
    }

    private func loc(_ key: String, _ args: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: args)
    }
}

private struct ControlButton: View {
    enum Style {
        case primary
        case secondary
        case tertiary
    }

    let title: String
    let icon: String
    let style: Style
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.callout.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(textColor)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            // Primary button always has gradient background which is dark, so text is white
            return .white
        case .secondary, .tertiary:
            return themeManager.currentTheme.primaryTextColor(for: colorScheme)
        }
    }

    private var background: some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .secondary:
                themeManager.currentTheme.cardBackground(for: colorScheme)
            case .tertiary:
                if themeManager.currentTheme == .gradient {
                    LinearGradient(colors: [Color("LakeNight"), Color("ForestGreen")], startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    themeManager.currentTheme.cardBackground(for: colorScheme)
                }
            }
        }
    }
}

private struct ProgressSection: View {
    let streak: Int
    let completed: Int
    let phase: PomodoroPhase
    @ObservedObject var timer: PomodoroTimerService
    let dailyTarget: Int
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 18) {
            GoalProgressView(phase: phase,
                              timer: timer)

            HStack(spacing: 18) {
                StatCard(titleKey: "STAT_STREAK", value: loc("STAT_STREAK_VALUE", fallback: "x%d", arguments: streak), icon: "flame.fill")
                StatCard(titleKey: "STAT_SESSIONS", value: "\(completed)", icon: "leaf.fill")
                StatCard(titleKey: "STAT_PHASE", value: phaseDisplayName, icon: phaseIcon)
            }
        }
        .padding(20)
        .background(themeManager.currentTheme.cardBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
        )
    }

    private var phaseIcon: String {
        switch phase {
        case .focus: return "timer"
        case .shortBreak: return "sun.max.fill"
        case .longBreak: return "moon.zzz"
        case .idle: return "pause"
        }
    }

    private var phaseDisplayName: String {
        switch phase {
        case .focus: return loc("PHASE_FOCUS_LABEL")
        case .shortBreak: return loc("PHASE_SHORT_LABEL")
        case .longBreak: return loc("PHASE_LONG_LABEL")
        case .idle: return loc("PHASE_IDLE_LABEL")
        }
    }

    private func progressValue() -> Double {
        let total: Double
        switch phase {
        case .focus:
            total = Double(timer.focusDuration)
        case .shortBreak:
            total = Double(timer.shortBreakDuration)
        case .longBreak:
            total = Double(timer.longBreakDuration)
        case .idle:
            return 0
        }
        guard total > 0 else { return 0 }
        let remaining = Double(timer.remainingSeconds)
        let clampedRemaining = min(max(remaining, 0), total)
        let progress = 1 - (clampedRemaining / total)
        return min(max(progress, 0), 1)
    }

    private func loc(_ key: String, fallback: String? = nil, arguments: CVarArg...) -> String {
        localization.translate(key, fallback: fallback, arguments: arguments)
    }
}

private struct GoalProgressView: View {
    let phase: PomodoroPhase
    @ObservedObject var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    private var normalizedProgress: Double {
        let target = market.dailyTarget
        guard target > 0 else { return 0 }
        return min(Double(timer.completedFocusSessions) / Double(target), 1)
    }

    private var phaseCompletion: Double {
        let totalSeconds: Double
        switch phase {
        case .focus:
            totalSeconds = Double(timer.focusDuration)
        case .shortBreak:
            totalSeconds = Double(timer.shortBreakDuration)
        case .longBreak:
            totalSeconds = Double(timer.longBreakDuration)
        case .idle:
            totalSeconds = 0
        }
        guard totalSeconds > 0 else { return 0 }
        let elapsed = totalSeconds - Double(timer.remainingSeconds)
        return min(max(elapsed / totalSeconds, 0), 1)
    }

    private var phasePercentText: String {
        String(format: "%%%.0f", phaseCompletion * 100)
    }

    private var goalStatus: String {
        String(format: loc("STATS_GOAL_VALUE"), timer.completedFocusSessions, market.dailyTarget)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("FOCUS_PHASE_PROGRESS"))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                    Text(phasePercentText)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(loc("HOME_STATS_TITLE"))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                    Text(goalStatus)
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                }
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
                    .frame(height: 16)

                GeometryReader { geometry in
                    let width = geometry.size.width * normalizedProgress
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(width, 6), height: 16)
                }
                .frame(height: 16)
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.cardBackground(for: colorScheme).opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loc(_ key: String) -> String {
        localization.translate(key, fallback: key)
    }
}

private struct StatCard: View {
    let titleKey: String
    let value: String
    let icon: String
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(loc(titleKey))
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
        }
        .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.currentTheme.cardBackground(for: colorScheme).opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loc(_ key: String) -> String {
        localization.translate(key, fallback: key)
    }
}

private struct CategorySelector: View {
    let selectedCategory: FocusCategory
    let onTap: () -> Void
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: selectedCategory.icon)
                    .font(.title3)
                    .foregroundStyle(selectedCategory.color)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selectedCategory.color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("CATEGORY_TITLE"))
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
                    Text(selectedCategory.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor(for: colorScheme))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(themeManager.currentTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(themeManager.currentTheme.cardStroke(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func loc(_ key: String) -> String {
        localization.translate(key, fallback: key)
    }
}

