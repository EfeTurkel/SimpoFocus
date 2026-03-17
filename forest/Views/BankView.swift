import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BankView: View {
    @EnvironmentObject private var bank: BankService
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var depositAmount: Double = .zero
    @State private var withdrawAmount: Double = .zero
    @State private var feedbackMessage: String?
    @State private var isSuccess: Bool = true
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Summary
            summarySection

            // MARK: - Actions
            actionsSection
        }
        // Removed the .padding(.horizontal) similar to HomeView, as FinanceView provides it
        // Or keep matching padding
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            if let feedbackMessage {
                feedbackBanner(feedbackMessage, isSuccess: isSuccess)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, -16)
                    .zIndex(1)
            }
        }
        .gesture(TapGesture().onEnded { dismissKeyboard() })
        .simultaneousGesture(DragGesture().onChanged { _ in dismissKeyboard() })
        // Removed `.task` and `.onAppear` calls to `bank.applyDailyInterestIfNeeded` that caused the infinite freeze loop.
        // The interest will still be applied manually on any deposit/withdraw action.
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("BANK_ACCOUNT", fallback: "Banka Hesabı"))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .onGlassPrimary()
                    Text(loc("BANK_STAKED_DESC", fallback: "Faiz kazandıran tasarruflarınız"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                balanceCard(
                    title: loc("BANK_AVAILABLE", fallback: "Kullanılabilir"),
                    amount: wallet.availableBalance,
                    icon: "tray",
                    isPrimary: false
                )
                
                balanceCard(
                    title: loc("BANK_STAKED", fallback: "Bankada"),
                    amount: wallet.stakedBalance,
                    icon: "building.columns.fill",
                    isPrimary: true
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    private func balanceCard(title: String, amount: Double, icon: String, isPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(isPrimary ? themeManager.currentTheme.getPrimaryTextColor(for: colorScheme) : Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(amount, format: .currency(code: "TRY"))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(isPrimary ? 0.03 : 0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(isPrimary ? 0.08 : 0.04), lineWidth: 0.5)
        )
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 16) {
            actionInputRow(
                title: loc("BANK_DEPOSIT_TITLE", fallback: "Yatır"),
                balance: wallet.availableBalance,
                amount: $depositAmount,
                actionTitle: loc("BANK_DEPOSIT_BUTTON", fallback: "Yatır"),
                action: deposit
            )

            Divider().opacity(0.5)

            actionInputRow(
                title: loc("BANK_WITHDRAW_TITLE", fallback: "Çek"),
                balance: wallet.stakedBalance,
                amount: $withdrawAmount,
                actionTitle: loc("BANK_WITHDRAW_BUTTON", fallback: "Çek"),
                action: withdraw
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private func actionInputRow(title: String, balance: Double, amount: Binding<Double>, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .onGlassPrimary()
                Spacer()
                Text("Max: \(balance.formatted(.currency(code: "TRY")))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }

            HStack(spacing: 12) {
                TextField("0", value: amount, formatter: formatter)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.currentTheme.getPrimaryTextColor(for: colorScheme))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.primary.opacity(0.05), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Feedback Banner

    private func feedbackBanner(_ text: String, isSuccess: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isSuccess ? "checkmark" : "exclamationmark.triangle")
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundStyle(isSuccess ? .green : .red.opacity(0.9))
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.02))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
    }

    // MARK: - Actions

    private func deposit() {
        dismissKeyboard()
        bank.applyDailyInterestIfNeeded(to: wallet)

        let requested = roundTwo(depositAmount)
        guard requested > 0 else {
            showFeedback(loc("BANK_ERROR_INVALID_DEPOSIT", fallback: "Geçersiz miktar"), success: false)
            return
        }

        guard requested <= wallet.availableBalance else {
            showFeedback(loc("BANK_ERROR_INSUFFICIENT_BARE", fallback: "Yetersiz bakiye"), success: false)
            return
        }

        let success = wallet.stake(amount: requested, description: "TXN_STAKE_DEPOSIT")
        if success {
            depositAmount = .zero
            let formatted = "₺" + String(format: "%.2f", requested)
            showFeedback(loc("BANK_SUCCESS_DEPOSIT", fallback: "Yatırıldı: \(formatted)"), success: true)
        } else {
            showFeedback(loc("BANK_ERROR_GENERIC", fallback: "Hata oluştu"), success: false)
        }
    }

    private func withdraw() {
        dismissKeyboard()
        bank.applyDailyInterestIfNeeded(to: wallet)

        let requested = roundTwo(withdrawAmount)
        guard requested > 0 else {
            showFeedback(loc("BANK_ERROR_INVALID_WITHDRAW", fallback: "Geçersiz miktar"), success: false)
            return
        }

        guard requested <= wallet.stakedBalance else {
            showFeedback(loc("BANK_ERROR_OVER_STAKED_BARE", fallback: "Bankada yeterli bakiye yok"), success: false)
            return
        }

        let success = wallet.unstake(amount: requested, description: "TXN_STAKE_WITHDRAW")
        if success {
            withdrawAmount = .zero
            let formatted = "₺" + String(format: "%.2f", requested)
            showFeedback(loc("BANK_SUCCESS_WITHDRAW", fallback: "Çekildi: \(formatted)"), success: true)
        } else {
            showFeedback(loc("BANK_ERROR_GENERIC", fallback: "Hata oluştu"), success: false)
        }
    }

    private func showFeedback(_ text: String, success: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            feedbackMessage = text
            isSuccess = success
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                feedbackMessage = nil
            }
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

    private func loc(_ key: String, fallback: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: fallback, arguments: arguments)
    }
}
