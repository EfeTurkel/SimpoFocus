import SwiftUI

struct RoomView: View {
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showingThemePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                currentThemePreview
                themeActions
            }
            .padding(24)
        }
        .scrollIndicators(.never)
        .background(room.currentTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environmentObject(room)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ev Temaları")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("Temaları keşfet, yeni atmosferler aç ve odanı motivasyonuna göre şekillendir.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var currentThemePreview: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AKTİF TEMA")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)

                    Text(room.currentTheme.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Temanın odaklanmana etkisi: +%\(min(Int(wallet.passiveIncomeBoost * 100), 100))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                Image(systemName: "paintbrush.pointed.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(room.currentTheme.assets) { asset in
                    themeAssetCard(asset)
                }
            }
        }
        .padding(22)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func themeAssetCard(_ asset: RoomAsset) -> some View {
        VStack(spacing: 8) {
            Image(systemName: asset.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(localizedName(for: asset))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(localizedDescription(for: asset))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func localizedName(for asset: RoomAsset) -> String {
        localization.translate(asset.nameKey, fallback: asset.nameKey)
    }

    private func localizedDescription(for asset: RoomAsset) -> String {
        localization.translate(asset.descriptionKey, fallback: asset.descriptionKey)
    }

    private var themeActions: some View {
        VStack(spacing: 18) {
            Button {
                showingThemePicker = true
            } label: {
                Label("Tema Seç", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color("ForestGreen"), Color("LakeBlue")], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }

            Text("Yeni temalar açtıkça ev sekmesinde dekorasyon seçeneklerin artar.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
} 