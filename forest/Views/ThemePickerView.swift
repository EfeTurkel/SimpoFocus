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

    private func isThemeLocked(_ theme: RoomTheme) -> Bool {
        !entitlements.hasAllThemes && theme.id != room.themes.first?.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Padding.element) {
                        ForEach(Array(room.themes.enumerated()), id: \.element.id) { index, theme in
                            let locked = isThemeLocked(theme)
                            themeRow(theme: theme, locked: locked)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(
                                    DS.Animation.defaultSpring.delay(DS.Animation.staggerDelay(index: index, base: 0.05)),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, DS.Padding.screen)
                    .padding(.vertical, DS.Padding.section)
                }
            }
            .navigationTitle(loc("THEME_PICKER_TITLE"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("HOME_NAV_CLOSE")) { dismiss() }
                        .onGlassPrimary()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                withAnimation(DS.Animation.defaultSpring) {
                    appeared = true
                }
            }
        }
    }

    private func themeRow(theme: RoomTheme, locked: Bool) -> some View {
        Button {
            if locked {
                showingPaywall = true
            } else {
                withAnimation(DS.Animation.defaultSpring) {
                    room.switchTheme(to: theme, wallet: wallet)
                }
            }
        } label: {
            HStack(spacing: DS.Padding.section) {
                Circle()
                    .fill(theme.background)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.subheadline.weight(.semibold))
                        .onGlassPrimary()

                    if locked {
                        Label(loc("PRO_BADGE"), systemImage: "crown.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    } else if !room.ownedThemes.contains(theme.id) {
                        Text(loc("THEME_PRICE_COINS", 500))
                            .font(.footnote)
                            .onGlassSecondary()
                    }
                }

                Spacer()

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.body)
                        .foregroundStyle(.orange)
                } else if room.currentTheme.id == theme.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("ForestGreen"))
                }
            }
            .padding(DS.Padding.card - 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .fill(.clear)
            )
            .liquidGlass(.card, edgeMask: [.all])
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .stroke(
                        room.currentTheme.id == theme.id ? Color("ForestGreen") : .clear,
                        lineWidth: 2
                    )
            )
            .opacity(locked ? 0.65 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}
