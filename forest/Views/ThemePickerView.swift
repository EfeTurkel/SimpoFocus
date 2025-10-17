import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var room: RoomViewModel
    @EnvironmentObject private var wallet: WalletViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(room.themes) { theme in
                    Button {
                        room.switchTheme(to: theme, wallet: wallet)
                    } label: {
                        HStack {
                            Circle()
                                .fill(theme.background)
                                .frame(width: 48, height: 48)
                            VStack(alignment: .leading) {
                                Text(theme.name)
                                if !room.ownedThemes.contains(theme.id) {
                                    Text("500 TRY")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if room.currentTheme.id == theme.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.clear)
                        )
                        .liquidGlass(.card, edgeMask: [.top, .bottom])
                    }
                }
            }
            .navigationTitle("Tema Seç")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

