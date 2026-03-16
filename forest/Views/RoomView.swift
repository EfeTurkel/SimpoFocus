import SwiftUI

struct RoomView: View {
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showingThemePicker = false
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Padding.card) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                currentThemePreview
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                themeActions
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 28)
            }
            .padding(.horizontal, DS.Padding.screen)
            .padding(.vertical, DS.Padding.card)
        }
        .scrollIndicators(.never)
        .background(room.currentTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environmentObject(room)
        }
        .onAppear {
            withAnimation(DS.Animation.defaultSpring.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        GlassSection(cornerRadius: DS.Radius.xl) {
            VStack(alignment: .leading, spacing: DS.Padding.element) {
                Text(loc("ROOM_HEADER_TITLE"))
                    .font(.title2.weight(.semibold))
                    .onGlassPrimary()

                Text(loc("ROOM_HEADER_DESC"))
                    .font(.callout)
                    .onGlassSecondary()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var currentThemePreview: some View {
        GlassSection(cornerRadius: DS.Radius.xl) {
            VStack(spacing: DS.Padding.section) {
                HStack(alignment: .top, spacing: DS.Padding.section) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc("ROOM_ACTIVE_THEME"))
                            .font(.caption2.weight(.medium))
                            .onGlassSecondary()
                            .textCase(.uppercase)

                        Text(room.currentTheme.name)
                            .font(.headline.weight(.semibold))
                            .onGlassPrimary()

                        Text(loc("ROOM_THEME_EFFECT", min(Int(wallet.passiveIncomeBoost * 100), 100)))
                            .font(.caption)
                            .onGlassSecondary()
                    }

                    Spacer()

                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.title2)
                        .onGlassPrimary()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Padding.section) {
                    ForEach(room.currentTheme.assets) { asset in
                        themeAssetCard(asset)
                    }
                }
            }
        }
    }

    private func themeAssetCard(_ asset: RoomAsset) -> some View {
        VStack(spacing: 8) {
            Image(systemName: asset.iconName)
                .font(.title2)
                .onGlassPrimary()
                .frame(width: 54, height: 54)

            Text(localizedName(for: asset))
                .font(.subheadline.weight(.semibold))
                .onGlassPrimary()
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(localizedDescription(for: asset))
                .font(.caption)
                .onGlassSecondary()
                .multilineTextAlignment(.center)
        }
        .padding(DS.Padding.section)
    }

    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }

    private func localizedName(for asset: RoomAsset) -> String {
        localization.translate(asset.nameKey, fallback: asset.nameKey)
    }

    private func localizedDescription(for asset: RoomAsset) -> String {
        localization.translate(asset.descriptionKey, fallback: asset.descriptionKey)
    }

    private var themeActions: some View {
        GlassSection(cornerRadius: DS.Radius.large) {
            VStack(spacing: DS.Padding.section) {
                Button {
                    showingThemePicker = true
                } label: {
                    Label(loc("ROOM_CHOOSE_THEME"), systemImage: "sparkles")
                }
                .buttonStyle(PrimaryCTAStyle())

                Text(loc("ROOM_UNLOCK_HINT"))
                    .font(.footnote)
                    .onGlassSecondary()
                    .multilineTextAlignment(.center)
            }
        }
    }
}
