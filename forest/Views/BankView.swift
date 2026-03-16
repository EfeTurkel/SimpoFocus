import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BankView: View {
    @EnvironmentObject private var bank: BankService
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var depositAmount: Double = 100
    @State private var withdrawAmount: Double = 50
    @State private var feedback: FeedbackMessage?
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    private let amountRange: ClosedRange<Double> = 0...100000

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let feedback {
                    ToastMessage(text: feedback.message, tint: feedback.color)
                }

                BankSummaryCard(available: wallet.availableBalance,
                                 staked: wallet.stakedBalance,
                                 earned: wallet.earnedFromInterest,
                                 rate: bank.annualInterestRate)
                    .environmentObject(localization)

                BankInfoSection(lastRateUpdate: bank.lastRateUpdate,
                                lastInterestApplied: bank.lastInterestApplied)
                    .environmentObject(localization)

                BankActionsSection(depositAmount: $depositAmount,
                                   withdrawAmount: $withdrawAmount,
                                   available: wallet.availableBalance,
                                   staked: wallet.stakedBalance,
                                   onDeposit: deposit,
                                   onWithdraw: withdraw)
                    .environmentObject(localization)
            }
            .padding(24)
        }
        .scrollIndicators(.never)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            bank.applyDailyInterestIfNeeded(to: wallet)
            bank.updateWeeklyRateIfNeeded()
        }
        .onAppear {
            bank.applyDailyInterestIfNeeded(to: wallet)
            bank.updateWeeklyRateIfNeeded()
        }
        .gesture(
            TapGesture().onEnded { dismissKeyboard() }
        )
        .simultaneousGesture(
            DragGesture().onChanged { _ in dismissKeyboard() }
        )
    }

    private func deposit() {
        bank.applyDailyInterestIfNeeded(to: wallet)
        bank.updateWeeklyRateIfNeeded()

        let requested = roundTwo(depositAmount)
        guard requested > 0 else {
            feedback = FeedbackMessage(message: loc("BANK_ERROR_INVALID_DEPOSIT"), color: .red)
            return
        }

        guard requested <= wallet.availableBalance else {
            let formatted = wallet.availableBalance.formatted(.currency(code: "TRY"))
            feedback = FeedbackMessage(message: loc("BANK_ERROR_INSUFFICIENT", formatted), color: .red)
            return
        }

        let success = wallet.stake(amount: requested, description: "TXN_STAKE_DEPOSIT")
        if success {
            depositAmount = 0
            let formatted = "₺" + String(format: "%.2f", requested)
            feedback = FeedbackMessage(message: loc("BANK_SUCCESS_DEPOSIT", formatted), color: .green)
            scheduleDismiss()
        } else {
            feedback = FeedbackMessage(message: loc("BANK_ERROR_GENERIC"), color: .red)
            scheduleDismiss()
        }
    }

    private func withdraw() {
        bank.applyDailyInterestIfNeeded(to: wallet)
        bank.updateWeeklyRateIfNeeded()

        let requested = roundTwo(withdrawAmount)
        guard requested > 0 else {
            feedback = FeedbackMessage(message: loc("BANK_ERROR_INVALID_WITHDRAW"), color: .red)
            return
        }

        guard requested <= wallet.stakedBalance else {
            let formatted = wallet.stakedBalance.formatted(.currency(code: "TRY"))
            feedback = FeedbackMessage(message: loc("BANK_ERROR_OVER_STAKED", formatted), color: .red)
            return
        }

        let success = wallet.unstake(amount: requested, description: "TXN_STAKE_WITHDRAW")
        if success {
            withdrawAmount = 0
            let formatted = "₺" + String(format: "%.2f", requested)
            feedback = FeedbackMessage(message: loc("BANK_SUCCESS_WITHDRAW", formatted), color: .green)
            scheduleDismiss()
        } else {
            feedback = FeedbackMessage(message: loc("BANK_ERROR_GENERIC"), color: .red)
            scheduleDismiss()
        }
    }

    private func scheduleDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(DS.Animation.quickSpring) { feedback = nil }
        }
    }

    private func roundTwo(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct FeedbackMessage {
    let message: String
    let color: Color
}

private struct ToastMessage: View {
    let text: String
    let tint: Color
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline)
                .onGlassPrimary()
                .padding(10)
                .background(themeManager.currentTheme.getCardBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

            Text(text)
                .font(.callout.weight(.semibold))
                .onGlassPrimary()
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
        )
    }
}

private struct BankSummaryCard: View {
    let available: Double
    let staked: Double
    let earned: Double
    let rate: Double
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.card) {
            Text(loc("BANK_ACCOUNT"))
                .font(DS.Typography.caption)
                .onGlassSecondary()

            VStack(alignment: .leading, spacing: DS.Padding.section) {
                SummaryRow(title: loc("BANK_AVAILABLE"), value: available)
                SummaryRow(title: loc("BANK_STAKED"), value: staked)
                SummaryRow(title: loc("BANK_EARNED"), value: earned, highlight: true)
            }

            HStack(spacing: DS.Padding.section) {
                InfoChip(title: loc("BANK_YEARLY_RATE"), value: ratePercent)
                InfoChip(title: loc("BANK_DAILY_RATE"), value: dailyPercent)
            }
        }
        .padding(DS.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    private var ratePercent: String {
        String(format: "%.2f%%", rate * 100)
    }

    private var dailyPercent: String {
        String(format: "%.3f%%", rate / 365 * 100)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct SummaryRow: View {
    let title: String
    let value: Double
    var highlight: Bool = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Text(title)
                .onGlassSecondary()
            Spacer()
            Text(value, format: .currency(code: "TRY"))
                .font(.title3.weight(highlight ? .bold : .medium))
                .onGlassPrimary()
        }
    }
}

private struct InfoChip: View {
    let title: String
    let value: String
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DS.Typography.micro)
                .onGlassSecondary()
            Text(value)
                .font(DS.Typography.cardTitle)
                .onGlassPrimary()
        }
        .padding(.vertical, DS.Padding.element)
        .padding(.horizontal, DS.Padding.section)
        .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.8), in: RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }
}

private struct BankActionsSection: View {
    @Binding var depositAmount: Double
    @Binding var withdrawAmount: Double
    let available: Double
    let staked: Double
    let onDeposit: () -> Void
    let onWithdraw: () -> Void
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.card) {
            Text(loc("BANK_ACTIONS"))
                .font(DS.Typography.sectionTitle)
                .onGlassPrimary()

            VStack(spacing: 18) {
                ActionCard(title: loc("BANK_DEPOSIT_TITLE"),
                           subtitle: loc("BANK_DEPOSIT_SUB"),
                           balance: available,
                           amount: $depositAmount,
                           gradient: Gradient(colors: [Color("ForestGreen"), Color("LakeBlue")]),
                           buttonTitle: loc("BANK_DEPOSIT_BUTTON"),
                           action: onDeposit)
                .environmentObject(localization)

                ActionCard(title: loc("BANK_WITHDRAW_TITLE"),
                           subtitle: loc("BANK_WITHDRAW_SUB"),
                           balance: staked,
                           amount: $withdrawAmount,
                           gradient: Gradient(colors: [Color("LakeNight"), Color("ForestGreen")]),
                           buttonTitle: loc("BANK_WITHDRAW_BUTTON"),
                           action: onWithdraw)
                .environmentObject(localization)
            }
        }
        .padding(DS.Padding.card)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let balance: Double
    @Binding var amount: Double
    let gradient: Gradient
    let buttonTitle: String
    let action: () -> Void

    @FocusState private var isFocused: Bool
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.section) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .onGlassPrimary()
                Text(subtitle)
                    .font(.caption2)
                    .onGlassSecondary()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("BANK_AVAILABLE_LABEL"))
                        .font(.caption2)
                        .onGlassSecondary()
                    Text(balance, format: .currency(code: "TRY"))
                        .font(.subheadline.weight(.semibold))
                        .onGlassPrimary()
                }
                Spacer()
            }

            HStack(spacing: 12) {
                TextField(loc("BANK_AMOUNT_PLACEHOLDER"), value: $amount, formatter: formatter)
                    .focused($isFocused)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, DS.Padding.section)
                    .padding(.vertical, DS.Padding.section)
                    .onGlassPrimary()
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                            .fill(Color("ForestGreen").opacity(0.06))
                    )

                Button(action: action) {
                    Text(loc(buttonTitle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color("ForestGreen"), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                }
            }
        }
        .padding(DS.Padding.card)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct AmountControl: View {
    let title: String
    @Binding var amount: Double
    let maxAmount: Double
    let actionTitle: String
    let action: () -> Void

    @EnvironmentObject private var localization: LocalizationManager

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(loc("BANK_MAX_FORMAT", maxAmount.formatted(.currency(code: "TRY"))))
                    .font(.caption)
                    .onGlassSecondary()
            }

            HStack(spacing: 12) {
                TextField(loc("BANK_AMOUNT_PLACEHOLDER"), value: $amount, formatter: formatter)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)
                Spacer()
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

private struct BankInfoSection: View {
    let lastRateUpdate: Date
    let lastInterestApplied: Date
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    private var relativeFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        formatter.unitsStyle = .full
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: localization.language.localeIdentifier)
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.card) {
            Text(loc("BANK_INFO"))
                .font(DS.Typography.sectionTitle)
                .onGlassPrimary()

            InfoRow(icon: "calendar.badge.clock",
                    title: loc("BANK_LAST_RATE"),
                    description: dateFormatter.string(from: lastRateUpdate),
                    relative: relativeFormatter.localizedString(for: lastRateUpdate, relativeTo: Date()))
                .environmentObject(localization)

            InfoRow(icon: "arrow.down.to.line",
                    title: loc("BANK_LAST_INTEREST"),
                    description: dateFormatter.string(from: lastInterestApplied),
                    relative: relativeFormatter.localizedString(for: lastInterestApplied, relativeTo: Date()))
                .environmentObject(localization)
        }
        .padding(DS.Padding.card)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(Color.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }

    private struct InfoRow: View {
        let icon: String
        let title: String
        let description: String
        let relative: String
        @EnvironmentObject private var localization: LocalizationManager
        @ObservedObject private var themeManager = ThemeManager.shared
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .onGlassSecondary()
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .onGlassPrimary()
                    Text(description)
                        .font(.caption)
                        .onGlassSecondary()
                    Text(relative)
                        .font(.caption2)
                        .onGlassSecondary()
                }

                Spacer()
            }
        }
    }
}

