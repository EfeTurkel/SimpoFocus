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
        } else {
            feedback = FeedbackMessage(message: loc("BANK_ERROR_GENERIC"), color: .red)
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
        } else {
            feedback = FeedbackMessage(message: loc("BANK_ERROR_GENERIC"), color: .red)
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
                .foregroundStyle(.white)
                .padding(10)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(text)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                .shadow(color: .black.opacity(0.25), radius: 18, y: 12)
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
        VStack(alignment: .leading, spacing: 18) {
            Text(loc("BANK_ACCOUNT"))
                .font(.callout.weight(.medium))
                .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))

            VStack(alignment: .leading, spacing: 12) {
                SummaryRow(title: loc("BANK_AVAILABLE"), value: available)
                SummaryRow(title: loc("BANK_STAKED"), value: staked)
                SummaryRow(title: loc("BANK_EARNED"), value: earned, highlight: true)
            }

            HStack(spacing: 16) {
                InfoChip(title: loc("BANK_YEARLY_RATE"), value: ratePercent)
                InfoChip(title: loc("BANK_DAILY_RATE"), value: dailyPercent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(themeManager.currentTheme.getCardBackground(for: colorScheme))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
        )
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
                .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
            Spacer()
            Text(value, format: .currency(code: "TRY"))
                .font(.title3.weight(highlight ? .bold : .medium))
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
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
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
            Text(value)
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        VStack(alignment: .leading, spacing: 20) {
            Text(loc("BANK_ACTIONS"))
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

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
        .padding(24)
        .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.8), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("BANK_AVAILABLE_LABEL"))
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                    Text(balance, format: .currency(code: "TRY"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                }
                Spacer()
            }

            HStack(spacing: 16) {
                TextField(loc("BANK_AMOUNT_PLACEHOLDER"), value: $amount, formatter: formatter)
                    .focused($isFocused)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.getCardBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme).opacity(isFocused ? 1.5 : 1), lineWidth: 1)
                    )

                Button(action: action) {
                    Text(loc(buttonTitle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: gradient.stops.map { $0.color },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(22)
        .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.6), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
        )
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
                    .foregroundStyle(.white.opacity(0.6))
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
        VStack(alignment: .leading, spacing: 18) {
            Text(loc("BANK_INFO"))
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))

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
        .padding(24)
        .background(themeManager.currentTheme.getCardBackground(for: colorScheme).opacity(0.8), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(themeManager.currentTheme.getCardStroke(for: colorScheme), lineWidth: 1)
        )
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
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    .frame(width: 34, height: 34)
                    .background(themeManager.currentTheme.getCardBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme))
                    Text(relative)
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.getSecondaryTextColor(for: colorScheme).opacity(0.7))
                }

                Spacer()
            }
        }
    }
}

