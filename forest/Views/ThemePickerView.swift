import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showingPaywall = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.sheetBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(loc("THEME_PICKER_SUBTITLE", fallback: "Uygulama genelindeki görsel temayı seçin."))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.top, 16)

                        LazyVStack(spacing: 16) {
                            ForEach(Array(room.themes.enumerated()), id: \.element.id) { index, theme in
                                let locked = isThemeLocked(theme)
                                themeRow(theme: theme, locked: locked)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 16)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.05),
                                        value: appeared
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(loc("THEME_PICKER_TITLE", fallback: "Temalar"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .padding(8)
                            .background(Color.primary.opacity(0.05), in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
        }
    }

    private func themeRow(theme: RoomTheme, locked: Bool) -> some View {
        let isSelected = room.currentTheme.id == theme.id

        return Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            if locked {
                showingPaywall = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    room.switchTheme(to: theme, wallet: wallet)
                }
            }
        }) {
            themeRowContent(theme: theme, locked: locked, isSelected: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func themeRowContent(theme: RoomTheme, locked: Bool, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            // Theme Preview Bubble
            Circle()
                .fill(theme.background)
                .frame(width: 48, height: 48)
                .overlay(
                    Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.custom("Rounded", size: 17).weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))

                if locked {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text(loc("PRO_BADGE", fallback: "PRO"))
                            .font(.custom("Rounded", size: 11).weight(.bold))
                            .tracking(1)
                    }
                    .foregroundStyle(.orange)
                } else if !room.ownedThemes.contains(theme.id) {
                    Text(loc("THEME_PRICE_COINS", fallback: "500 Token", String(500)))
                        .font(.custom("Rounded", size: 13).weight(.regular))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text(isSelected ? loc("THEME_ACTIVE", fallback: "Kullanımda") : loc("THEME_OWNED", fallback: "Sahipsiniz"))
                        .font(.custom("Rounded", size: 13).weight(.regular))
                        .foregroundStyle(isSelected ? themeManager.currentTheme.primaryTextColor(for: colorScheme) : Color.secondary)
                }
            }

            Spacer()

            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange.opacity(0.8))
            } else if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor(for: colorScheme))
                    .padding(8)
                    .background(themeManager.currentTheme.primaryTextColor(for: colorScheme).opacity(0.08), in: Circle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(isSelected ? 0.04 : 0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(isSelected ? 0.15 : 0.05), lineWidth: isSelected ? 1 : 0.5)
        )
        .opacity(locked ? 0.7 : 1)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }

    private func isThemeLocked(_ theme: RoomTheme) -> Bool {
        !entitlements.hasAllThemes && theme.id != room.themes.first?.id
    }

    private func loc(_ key: String, fallback: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: fallback, arguments: arguments)
    }
}
