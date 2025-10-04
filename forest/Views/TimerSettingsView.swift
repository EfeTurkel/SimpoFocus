import SwiftUI

struct TimerSettingsView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var focusMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var dailyTarget: Double = 4
    @State private var soundEnabled: Bool = true
    @State private var hapticsEnabled: Bool = true
    @State private var autoStartBreaks: Bool = false
    @State private var sessionsBeforeLongBreakValue: Double = 4
    @State private var tickingEnabled: Bool = true
    @State private var selectedTickSound: PomodoroTimerService.TickSound = .classic
    @State private var overrideMute: Bool = false
    @State private var tickVolume: Double = 0.55
    @State private var notificationsEnabled: Bool = false
    @State private var selectedLanguage: AppLanguage = LocalizationManager.shared.language

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color("ForestGreen").opacity(0.35), Color("LakeNight").opacity(0.6)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            SettingsHeaderCard(focus: $focusMinutes,
                                               shortBreak: $shortBreakMinutes,
                                               longBreak: $longBreakMinutes,
                                               dailyTarget: $dailyTarget,
                                               sessionsBeforeLongBreak: $sessionsBeforeLongBreakValue)
                                .environmentObject(localization)

                            GlassSection(title: loc("SETTINGS_SECTION_DURATIONS_TITLE"),
                                         subtitle: loc("SETTINGS_SECTION_DURATIONS_SUBTITLE"),
                                         icon: "timer") {
                                VStack(spacing: 18) {
                                    DurationSlider(title: loc("SETTINGS_TILE_FOCUS"), value: $focusMinutes, range: 10...50, color: Color("ForestGreen"))
                                    DurationSlider(title: loc("SETTINGS_DURATION_SHORT_TITLE"), value: $shortBreakMinutes, range: 3...15, color: Color("LakeBlue"))
                                    DurationSlider(title: loc("SETTINGS_DURATION_LONG_TITLE"), value: $longBreakMinutes, range: 10...30, color: Color("LakeNight"), valueColor: Color.white.opacity(0.9))
                                }
                            }

                            GlassSection(title: loc("SETTINGS_SECTION_GOALS_TITLE"),
                                         subtitle: loc("SETTINGS_SECTION_GOALS_SUBTITLE"),
                                         icon: "target") {
                                VStack(spacing: 16) {
                                    StepperSetting(title: loc("SETTINGS_STEPPER_DAILY"), value: $dailyTarget, range: 2...12, step: 1)
                                        .environmentObject(localization)
                                    StepperSetting(title: loc("SETTINGS_STEPPER_LONG"), value: $sessionsBeforeLongBreakValue, range: 2...10, step: 1)
                                        .environmentObject(localization)

                                    TargetProgressPreview(title: loc("SETTINGS_TARGET_TITLE_DAILY"), value: Int(dailyTarget), unit: loc("SETTINGS_UNIT_POMODORO"))
                                        .environmentObject(localization)
                                    TargetProgressPreview(title: loc("SETTINGS_TARGET_TITLE_LONG"), value: Int(sessionsBeforeLongBreakValue), unit: loc("SETTINGS_UNIT_FOCUS"))
                                        .environmentObject(localization)
                                }
                            }

                            GlassSection(title: loc("SETTINGS_SECTION_ALERTS_TITLE"),
                                         subtitle: loc("SETTINGS_SECTION_ALERTS_SUBTITLE"),
                                         icon: "bell.badge.fill") {
                                VStack(spacing: 14) {
                                    ToggleSetting(title: loc("SETTINGS_TOGGLE_SOUND_TITLE"), description: loc("SETTINGS_TOGGLE_SOUND_DESC"), isOn: $soundEnabled, icon: "speaker.wave.2.fill")
                                    Divider().blendMode(.overlay)
                                    ToggleSetting(title: loc("SETTINGS_TOGGLE_HAPTIC_TITLE"), description: loc("SETTINGS_TOGGLE_HAPTIC_DESC"), isOn: $hapticsEnabled, icon: "hand.tap.fill")
                                    Divider().blendMode(.overlay)
                                    ToggleSetting(title: loc("SETTINGS_TOGGLE_AUTO_TITLE"), description: loc("SETTINGS_TOGGLE_AUTO_DESC"), isOn: $autoStartBreaks, icon: "play.circle.fill")
                                    Divider().blendMode(.overlay)
                                    ToggleSetting(title: loc("SETTINGS_TOGGLE_NOTIF_TITLE"), description: loc("SETTINGS_TOGGLE_NOTIF_DESC"), isOn: $notificationsEnabled, icon: "bell.fill")
                                }
                            }

#if canImport(UIKit)
                            NotificationStatusCard(isEnabled: $notificationsEnabled)
                                .environmentObject(timer)
                                .environmentObject(localization)
#endif

                            GlassSection(title: loc("SETTINGS_SECTION_SOUND_TITLE"),
                                         subtitle: loc("SETTINGS_SECTION_SOUND_SUBTITLE"),
                                         icon: "metronome.fill") {
                                VStack(spacing: 16) {
                                    ToggleSetting(title: loc("SETTINGS_TOGGLE_TICK_TITLE"), description: loc("SETTINGS_TOGGLE_TICK_DESC"), isOn: $tickingEnabled, icon: "speaker.wave.3.fill")

                                    ToggleSetting(title: loc("SETTINGS_TOGGLE_OVERRIDE_TITLE"), description: loc("SETTINGS_TOGGLE_OVERRIDE_DESC"), isOn: $overrideMute, icon: "bell.fill")
                                        .disabled(!tickingEnabled)
                                        .opacity(tickingEnabled ? 1 : 0.4)

                                    Picker(loc("SETTINGS_PICKER_TICK"), selection: $selectedTickSound) {
                                        ForEach(PomodoroTimerService.TickSound.allCases) { sound in
                                            Text(sound.displayName).tag(sound)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(!tickingEnabled)

                                    VolumeSlider(value: $tickVolume)
                                        .disabled(!tickingEnabled)
                                        .opacity(tickingEnabled ? 1 : 0.5)
                                        .environmentObject(localization)

                                    Button {
                                        timer.setTickSound(selectedTickSound)
                                        timer.overrideMute = overrideMute
                                        timer.tickVolume = tickVolume
                                        if tickingEnabled {
                                            timer.previewTick()
                                        }
                                    } label: {
                                        Label(loc("SETTINGS_BUTTON_PREVIEW"), systemImage: "play.circle")
                                            .font(.subheadline.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            )
                                            .foregroundStyle(.white)
                                    }
                                    .disabled(!tickingEnabled)
                                    .opacity(tickingEnabled ? 1 : 0.4)
                                }
                            }

                            GlassSection(title: loc("SETTINGS_SECTION_LANGUAGE_TITLE"),
                                         subtitle: loc("SETTINGS_SECTION_LANGUAGE_SUBTITLE"),
                                         icon: "globe") {
                                VStack(spacing: 16) {
                                    Picker(loc("SETTINGS_LANGUAGE_PICKER"), selection: $selectedLanguage) {
                                        ForEach(AppLanguage.allCases) { language in
                                            Text(language.displayName).tag(language)
                                        }
                                    }
                                    .pickerStyle(.segmented)

                                    Text(loc("SETTINGS_LANGUAGE_NOTE"))
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }

#if canImport(UIKit)
                            MakerSection()
#endif
                        }
                        .padding(.vertical, 12)
                    }

                    actionBar
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle(loc("SETTINGS_TITLE"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            focusMinutes = Double(timer.focusDuration) / 60
            shortBreakMinutes = Double(timer.shortBreakDuration) / 60
            longBreakMinutes = Double(timer.longBreakDuration) / 60
            dailyTarget = Double(market.dailyTarget)
            sessionsBeforeLongBreakValue = Double(timer.sessionsBeforeLongBreak)
            soundEnabled = timer.soundEnabled
            hapticsEnabled = timer.hapticsEnabled
            autoStartBreaks = timer.autoStartBreaks
            tickingEnabled = timer.tickingEnabled
            selectedTickSound = timer.selectedTickSound
            overrideMute = timer.overrideMute
            tickVolume = timer.tickVolume
            notificationsEnabled = timer.notificationsEnabled
            selectedLanguage = localization.language
        }
        .onChange(of: selectedLanguage) { _, newValue in
            localization.language = newValue
        }
        .onChange(of: tickVolume) { _, newValue in
            timer.tickVolume = newValue
            timer.setTickSound(selectedTickSound)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Label(loc("SETTINGS_BUTTON_CANCEL"), systemImage: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                        timer.adjustDurations(
                            focus: Int(focusMinutes * 60),
                            shortBreak: Int(shortBreakMinutes * 60),
                            longBreak: Int(longBreakMinutes * 60)
                        )
                market.dailyTarget = Int(dailyTarget)
                timer.sessionsBeforeLongBreak = Int(sessionsBeforeLongBreakValue)
                timer.soundEnabled = soundEnabled
                timer.hapticsEnabled = hapticsEnabled
                timer.autoStartBreaks = autoStartBreaks
                timer.tickingEnabled = tickingEnabled
                timer.setTickSound(selectedTickSound)
                timer.overrideMute = overrideMute
                timer.tickVolume = tickVolume
                timer.notificationsEnabled = notificationsEnabled
                PersistenceController.shared.saveTimer(timer)
                PersistenceController.shared.saveMarket(market)
                localization.language = selectedLanguage
                        dismiss()
            } label: {
                Label(loc("SETTINGS_BUTTON_SAVE"), systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 12)
    }
}

private extension TimerSettingsView {
    func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, arguments: arguments)
    }
}

#if canImport(UIKit)
private struct NotificationStatusCard: View {
    @Binding var isEnabled: Bool
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var localization: LocalizationManager

    private var backgroundRefreshEnabled: Bool {
        timer.backgroundRefreshAvailable
    }

    var body: some View {
        GlassSection(title: loc("SETTINGS_SECTION_BACKGROUND_TITLE"),
                     subtitle: loc("SETTINGS_SECTION_BACKGROUND_SUBTITLE"),
                     icon: "icloud.and.arrow.down") {
            VStack(alignment: .leading, spacing: 12) {
                statusLabel

                if !isEnabled {
                    Button {
                        requestNotifications()
                    } label: {
                        Label(loc("SETTINGS_BACKGROUND_ALLOW_NOTIF"), systemImage: "bell.badge")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color("ForestGreen"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                if isEnabled && !backgroundRefreshEnabled {
                    Button {
                        openSettings()
                    } label: {
                        Label(loc("SETTINGS_BACKGROUND_OPEN_SETTINGS"), systemImage: "gear")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color("LakeBlue"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: backgroundRefreshEnabled && isEnabled ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(backgroundRefreshEnabled && isEnabled ? Color("ForestGreen") : Color("LakeBlue"))

            VStack(alignment: .leading, spacing: 4) {
                Text(loc(backgroundRefreshEnabled && isEnabled ? "SETTINGS_BACKGROUND_READY_TITLE" : "SETTINGS_BACKGROUND_ALERT_TITLE"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(descriptionText)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var descriptionText: String {
        if !isEnabled {
            return loc("SETTINGS_BACKGROUND_ENABLE_NOTIF")
        }
        if !backgroundRefreshEnabled {
            return loc("SETTINGS_BACKGROUND_ENABLE_REFRESH")
        }
        return loc("SETTINGS_BACKGROUND_ALL_GOOD")
    }

    private func requestNotifications() {
        isEnabled = true
        timer.notificationsEnabled = true
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, arguments: arguments)
    }
}

private struct MakerSection: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        GlassSection(title: loc("SETTINGS_SECTION_CREATOR_TITLE"),
                     subtitle: loc("SETTINGS_SECTION_CREATOR_SUBTITLE"),
                     icon: "person.crop.circle.badge.checkmark") {
            HStack(spacing: 14) {
                MakerLinkButton(title: loc("SETTINGS_CREATOR_LINKEDIN"), tint: Color(red: 0.0, green: 0.47, blue: 0.71), action: { openLink("https://tr.linkedin.com/in/efetu") }) {
                    LinkBadgeLabel(symbol: "in", tint: Color(red: 0.0, green: 0.47, blue: 0.71))
                }

                MakerLinkButton(title: loc("SETTINGS_CREATOR_X"), tint: .black, action: { openLink("https://x.com/efetu0x") }) {
                    LinkBadgeLabel(symbol: "X", tint: .black)
                }

                MakerLinkButton(title: loc("SETTINGS_CREATOR_EMAIL"), tint: Color("LakeBlue"), action: openMail) {
                    Image(systemName: "envelope.fill")
                        .font(.title2.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, arguments: arguments)
    }

    private func openLink(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }

    private func openMail() {
        let subject = loc("SETTINGS_CREATOR_EMAIL_SUBJECT")
        guard let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:einheiten.ebooks-2p@icloud.com?subject=\(encoded)") else { return }
        openURL(url)
    }
}

private struct MakerLinkButton<Label: View>: View {
    let title: String
    let tint: Color
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                label()
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LinkBadgeLabel: View {
    let symbol: String
    let tint: Color

    var body: some View {
        Text(symbol)
            .font(.title2.weight(.heavy))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.9), in: Capsule())
            .foregroundStyle(.white)
    }
}
#endif

private struct SettingsHeaderCard: View {
    @Binding var focus: Double
    @Binding var shortBreak: Double
    @Binding var longBreak: Double
    @Binding var dailyTarget: Double
    @Binding var sessionsBeforeLongBreak: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("SETTINGS_HEADER_TITLE"))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(loc("SETTINGS_HEADER_SUBTITLE"))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text(loc("SETTINGS_HEADER_ACTION"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.1), in: Capsule())
            }

            HStack(spacing: 16) {
                SummaryTile(title: loc("SETTINGS_TILE_FOCUS"), value: loc("SETTINGS_DURATION_FORMAT", Int(focus)), icon: "bolt.fill", color: Color("ForestGreen"))
                SummaryTile(title: loc("SETTINGS_TILE_BREAKS"), value: loc("SETTINGS_DURATION_FORMAT", Int(shortBreak + longBreak)), icon: "pause.circle.fill", color: Color("LakeBlue"))
                SummaryTile(title: loc("SETTINGS_TILE_LONG"), value: "\(Int(sessionsBeforeLongBreak))x", icon: "hourglass", color: Color("LakeNight"))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .padding(10)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct GlassSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct DurationSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    var valueColor: Color?
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(loc("SETTINGS_DURATION_FORMAT", Int(value)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle((valueColor ?? color).opacity(0.95))
            }

            Slider(value: $value, in: range, step: 1)
                .tint(color)
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct ToggleSetting: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let icon: String
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

private struct StepperSetting: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Stepper(value: $value, in: range, step: step) {
                Text(loc("SETTINGS_STEPPER_VALUE_SESSIONS", Int(value)))
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct TargetProgressPreview: View {
    let title: String
    let value: Int
    let unit: String
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            ProgressView(value: min(Double(value) / 8.0, 1.0))
                .tint(Color("ForestGreen"))
                .frame(height: 12)
                .background(Color.white.opacity(0.08), in: Capsule())
            Text(loc("SETTINGS_TARGET_LABEL", value, unit))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct VolumeSlider: View {
    @Binding var value: Double
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(loc("SETTINGS_VOLUME_LABEL"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(loc("SETTINGS_PERCENT_FORMAT", Int(value * 100)))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Slider(value: $value, in: 0.2...1.0)
                .tint(Color("ForestGreen"))
        }
        .padding(.vertical, 4)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

