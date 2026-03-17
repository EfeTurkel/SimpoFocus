import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var timer: PomodoroTimerService
    @EnvironmentObject private var market: MarketViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingCategoryPicker = false
    @State private var showingPaywall = false
    @State private var showProNudge = false
    @AppStorage("sessionsSinceLastProNudge") private var sessionsSinceNudge: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, DS.Padding.screen)
                .padding(.top, 8)

            Spacer(minLength: 16)

            CircularTimerView(
                progress: phaseProgress,
                dailyGoalProgress: dailyGoalProgress,
                timeText: formattedTime(timer.remainingSeconds),
                subtitle: timer.phase.displayName(using: localization),
                isRunning: timer.isRunning,
                focusScore: timer.focusScore
            )
            .padding(.horizontal, DS.Padding.xl)

            if timer.phase == .focus {
                categoryPill
                    .padding(.top, DS.Padding.section)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer(minLength: DS.Padding.section)

            controlButtons
                .padding(.horizontal, DS.Padding.screen + DS.Padding.card)

            if showProNudge {
                proSessionNudge
                    .padding(.top, 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            Spacer(minLength: DS.Padding.section)

            Spacer(minLength: DS.Padding.section)
        }
        .animation(DS.Animation.defaultSpring, value: timer.phase)
        .animation(.easeInOut(duration: 0.3), value: showProNudge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingSettings) { TimerSettingsView() }
        .sheet(isPresented: $showingStats) {
            YearlyAnalyticsView()
                .environmentObject(timer)
                .environmentObject(localization)
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(selectedCategory: $timer.selectedCategory)
                .environmentObject(localization)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .onChange(of: timer.completedFocusSessions) { _, _ in
            guard !entitlements.isPro else { return }
            sessionsSinceNudge += 1
            if sessionsSinceNudge >= 3 {
                sessionsSinceNudge = 0
                withAnimation { showProNudge = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation { showProNudge = false }
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(loc("FOCUS_NOW"))
                    .font(DS.Typography.caption)
                    .onGlassSecondary()
                Text(timer.phase.displayName(using: localization))
                    .font(DS.Typography.sectionTitle)
                    .onGlassPrimary()
            }

            Spacer()

            HStack(spacing: 10) {
                if !entitlements.isPro {
                    Button { showingPaywall = true } label: {
                        Image(systemName: "crown.fill")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.orange)
                            .frame(width: 40, height: 40)
                    }
                }
                Button { showingStats.toggle() } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.body.weight(.medium))
                        .onGlassSecondary()
                        .frame(width: 40, height: 40)
                }
                Button { showingSettings.toggle() } label: {
                    Image(systemName: "gearshape")
                        .font(.body.weight(.medium))
                        .onGlassSecondary()
                        .frame(width: 40, height: 40)
                }
            }
        }
    }

    // MARK: - Category Pill

    private var categoryPill: some View {
        Button { showingCategoryPicker = true } label: {
            HStack(spacing: 8) {
                Image(systemName: timer.selectedCategory.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(timer.selectedCategory.color)
                Text(timer.selectedCategory.displayName)
                    .font(DS.Typography.caption)
                    .onGlassPrimary()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .onGlassSecondary()
            }
            .padding(.horizontal, DS.Padding.section)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(timer.selectedCategory.color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: DS.Padding.card) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                timer.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3.weight(.medium))
                    .onGlassSecondary()
            }
            .buttonStyle(CircleButtonStyle(size: 52))

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                timer.isRunning ? timer.pause() : timer.start()
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(CircleButtonStyle(size: 72, filled: true))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                timer.skipPhase()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title3.weight(.medium))
                    .onGlassSecondary()
            }
            .buttonStyle(CircleButtonStyle(size: 52))
        }
    }

    // MARK: - Progress

    private var dailyProgressBar: some View {
        let target = market.dailyTarget
        let progress = target > 0 ? min(Double(timer.completedFocusSessions) / Double(target), 1) : 0

        return VStack(spacing: 6) {
            HStack {
                Text(loc("FOCUS_PHASE_PROGRESS"))
                    .font(DS.Typography.micro)
                    .onGlassSecondary()
                Spacer()
                Text("\(timer.completedFocusSessions)/\(target)")
                    .font(DS.Typography.caption)
                    .onGlassPrimary()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("ForestGreen").opacity(0.12))
                    Capsule()
                        .fill(Color("ForestGreen"))
                        .frame(width: max(geo.size.width * progress, 6))
                        .animation(DS.Animation.defaultSpring, value: progress)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Stats Chips (removed)

    // MARK: - Helpers

    private var phaseProgress: Double {
        let total: Double
        switch timer.phase {
        case .focus: total = Double(timer.focusDuration)
        case .shortBreak: total = Double(timer.shortBreakDuration)
        case .longBreak: total = Double(timer.longBreakDuration)
        case .idle: return 0
        }
        guard total > 0 else { return 0 }
        return min(max(1.0 - Double(timer.remainingSeconds) / total, 0), 1)
    }

    private var phaseIcon: String {
        switch timer.phase {
        case .focus: return "timer"
        case .shortBreak: return "sun.max.fill"
        case .longBreak: return "moon.zzz"
        case .idle: return "pause"
        }
    }

    private var phaseShort: String {
        switch timer.phase {
        case .focus: return loc("PHASE_FOCUS_LABEL")
        case .shortBreak: return loc("PHASE_SHORT_LABEL")
        case .longBreak: return loc("PHASE_LONG_LABEL")
        case .idle: return loc("PHASE_IDLE_LABEL")
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        guard seconds > 0 else { return "00:00" }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    private var dailyGoalProgress: Double {
        let target = market.dailyTarget
        guard target > 0 else { return 0 }
        return min(max(Double(timer.completedFocusSessions) / Double(target), 0), 1)
    }

    // MARK: - Pro Session Nudge

    private var proSessionNudge: some View {
        Button { showingPaywall = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                Text(loc("PRO_SESSION_NUDGE", fallback: "Earn 2x coins with Pro"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .onGlassSecondary()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color("ForestGreen").opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func loc(_ key: String, fallback: String? = nil, arguments: CVarArg...) -> String {
        localization.translate(key, fallback: fallback, arguments: arguments)
    }
}

// MARK: - Circular Timer View

private struct CircularTimerView: View {
    let progress: Double
    let dailyGoalProgress: Double
    let timeText: String
    let subtitle: String
    let isRunning: Bool
    let focusScore: Int
    @State private var breatheScale: CGFloat = 1.0

    private let ringSize: CGFloat = 252
    private let strokeWidth: CGFloat = 12
    
    // Middle ring parameters (daily goal)
    private let middleRingSize: CGFloat = 270
    private let middleStrokeWidth: CGFloat = 9
    
    // Outer ring parameters (focus score)
    private let outerRingSize: CGFloat = 288
    private let outerStrokeWidth: CGFloat = 7

    var body: some View {
        ZStack {
            // MARK: - Glow / Halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("ForestGreen").opacity(isRunning ? 0.22 : 0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: outerRingSize * 0.62
                    )
                )
                .frame(width: outerRingSize + 40, height: outerRingSize + 40)
                .blur(radius: isRunning ? 6 : 10)
                .opacity(isRunning ? 1.0 : 0.7)

            // MARK: - Outer Focus Score Ring
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: outerStrokeWidth)
                .frame(width: outerRingSize, height: outerRingSize)

            Circle()
                .trim(from: 0, to: CGFloat(focusScore) / 100.0)
                .stroke(
                    Color.purple.opacity(0.75),
                    style: StrokeStyle(lineWidth: outerStrokeWidth, lineCap: .round)
                )
                .frame(width: outerRingSize, height: outerRingSize)
                .rotationEffect(.degrees(-90))
                .animation(DS.Animation.defaultSpring, value: focusScore)
                .shadow(color: Color.purple.opacity(isRunning ? 0.25 : 0.12), radius: isRunning ? 10 : 6)

            // MARK: - Middle Daily Goal Ring
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: middleStrokeWidth)
                .frame(width: middleRingSize, height: middleRingSize)

            Circle()
                .trim(from: 0, to: dailyGoalProgress)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: middleStrokeWidth, lineCap: .round)
                )
                .frame(width: middleRingSize, height: middleRingSize)
                .rotationEffect(.degrees(-90))
                .animation(DS.Animation.defaultSpring, value: dailyGoalProgress)
                .shadow(color: Color.orange.opacity(isRunning ? 0.25 : 0.12), radius: isRunning ? 10 : 6)
            
            // MARK: - Inner Timer Ring
            Circle()
                .stroke(Color("ForestGreen").opacity(0.1), lineWidth: strokeWidth)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color("ForestGreen"),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(DS.Animation.defaultSpring, value: progress)
                .shadow(color: Color("ForestGreen").opacity(isRunning ? 0.35 : 0.18), radius: isRunning ? 14 : 8)

            VStack(spacing: 4) {
                Text(timeText)
                    .font(DS.Typography.heroTimer)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(DS.Animation.quickSpring, value: timeText)
                    .onGlassPrimary()

                Text(subtitle)
                    .font(DS.Typography.caption)
                    .onGlassSecondary()
            }
        }
        .scaleEffect(breatheScale)
        .onChange(of: isRunning) { _, running in
            if running {
                withAnimation(DS.Animation.breathing) {
                    breatheScale = 1.035
                }
            } else {
                withAnimation(DS.Animation.quickSpring) {
                    breatheScale = 1.0
                }
            }
        }
        .onAppear {
            if isRunning {
                withAnimation(DS.Animation.breathing) {
                    breatheScale = 1.035
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeText) remaining, \(subtitle)")
    }
}
