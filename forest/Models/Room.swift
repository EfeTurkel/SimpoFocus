import Foundation
import SwiftUI
import Combine

private enum RoomAssetID {
    static let woodDesk = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    static let focusTimer = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
    static let ergonomicChair = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
    static let meditationMat = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
    static let silentPlant = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
    static let vintageLamp = UUID(uuidString: "00000000-0000-0000-0000-000000000203")!
    static let retroConsole = UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
    static let vinylPlayer = UUID(uuidString: "00000000-0000-0000-0000-000000000302")!
    static let miniLibrary = UUID(uuidString: "00000000-0000-0000-0000-000000000303")!
    static let demoPlant = UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
    static let bambooDesk = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
    static let zenPlant = UUID(uuidString: "00000000-0000-0000-0000-000000000502")!
    static let warmLight = UUID(uuidString: "00000000-0000-0000-0000-000000000503")!
    static let lakeView = UUID(uuidString: "00000000-0000-0000-0000-000000000601")!
    static let hammock = UUID(uuidString: "00000000-0000-0000-0000-000000000602")!
    static let woodShelf = UUID(uuidString: "00000000-0000-0000-0000-000000000603")!
}

private enum RoomThemeID {
    static let starter = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    static let lake = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
}

struct RoomAsset: Identifiable, Hashable {
    let id: UUID
    let nameKey: String
    let descriptionKey: String
    let price: Double
    let iconName: String

    init(id: UUID, nameKey: String, descriptionKey: String, price: Double, iconName: String) {
        self.id = id
        self.nameKey = nameKey
        self.descriptionKey = descriptionKey
        self.price = price
        self.iconName = iconName
    }
}

struct RoomTheme: Identifiable {
    let id: UUID
    let name: String
    let background: LinearGradient
    let assets: [RoomAsset]

    init(id: UUID, name: String, background: LinearGradient, assets: [RoomAsset]) {
        self.id = id
        self.name = name
        self.background = background
        self.assets = assets
    }
}

struct PlacedItem: Identifiable {
    let id = UUID()
    let asset: RoomAsset
}

struct MarketSection: Identifiable {
    let id = UUID()
    let titleKey: String
    let assets: [RoomAsset]

    init(titleKey: String, assets: [RoomAsset]) {
        self.titleKey = titleKey
        self.assets = assets
    }
}

struct RoomSnapshot: Codable {
    let currentThemeID: UUID
    let ownedThemes: [UUID]
    let unlockedAssets: [UUID]
    let placedAssets: [UUID]
}

final class RoomViewModel: ObservableObject {
    @Published private(set) var unlockedAssets: Set<UUID> = []
    @Published private(set) var placedItems: [PlacedItem] = []
    @Published var ownedThemes: [UUID] = []
    @Published private(set) var currentTheme: RoomTheme
    let changePublisher = PassthroughSubject<Void, Never>()

    let themes: [RoomTheme]
    let marketSections: [MarketSection]

    private let localization: LocalizationManager

    init(snapshot: RoomSnapshot? = nil,
         localization: LocalizationManager = .shared) {
        self.localization = localization
        let studyCollection = MarketSection(
            titleKey: "HOME_MARKET_SECTION_WORKSHOP",
            assets: [
                RoomAsset(id: RoomAssetID.woodDesk, nameKey: "ROOM_ASSET_WOOD_DESK", descriptionKey: "ROOM_DESC_WOOD_DESK", price: 320, iconName: "table.furniture"),
                RoomAsset(id: RoomAssetID.focusTimer, nameKey: "ROOM_ASSET_FOCUS_TIMER", descriptionKey: "ROOM_DESC_FOCUS_TIMER", price: 140, iconName: "hourglass"),
                RoomAsset(id: RoomAssetID.ergonomicChair, nameKey: "ROOM_ASSET_ERGO_CHAIR", descriptionKey: "ROOM_DESC_ERGO_CHAIR", price: 260, iconName: "chair")
            ]
        )

        let relaxationCollection = MarketSection(
            titleKey: "HOME_MARKET_SECTION_RELAX",
            assets: [
                RoomAsset(id: RoomAssetID.meditationMat, nameKey: "ROOM_ASSET_MEDITATION_MAT", descriptionKey: "ROOM_DESC_MEDITATION_MAT", price: 180, iconName: "circle.dotted"),
                RoomAsset(id: RoomAssetID.silentPlant, nameKey: "ROOM_ASSET_SILENT_PLANT", descriptionKey: "ROOM_DESC_SILENT_PLANT", price: 120, iconName: "leaf"),
                RoomAsset(id: RoomAssetID.vintageLamp, nameKey: "ROOM_ASSET_VINTAGE_LAMP", descriptionKey: "ROOM_DESC_VINTAGE_LAMP", price: 150, iconName: "lightbulb")
            ]
        )

        let collectibles = MarketSection(
            titleKey: "HOME_MARKET_SECTION_COLLECTION",
            assets: [
                RoomAsset(id: RoomAssetID.retroConsole, nameKey: "ROOM_ASSET_RETRO_CONSOLE", descriptionKey: "ROOM_DESC_RETRO_CONSOLE", price: 420, iconName: "gamecontroller"),
                RoomAsset(id: RoomAssetID.vinylPlayer, nameKey: "ROOM_ASSET_VINYL_PLAYER", descriptionKey: "ROOM_DESC_VINYL_PLAYER", price: 380, iconName: "music.note"),
                RoomAsset(id: RoomAssetID.miniLibrary, nameKey: "ROOM_ASSET_MINI_LIBRARY", descriptionKey: "ROOM_DESC_MINI_LIBRARY", price: 260, iconName: "books.vertical")
            ]
        )

        let demoCollection = MarketSection(
            titleKey: "HOME_MARKET_SECTION_STARTER",
            assets: [
                RoomAsset(id: RoomAssetID.demoPlant, nameKey: "ROOM_ASSET_MINI_PLANT", descriptionKey: "ROOM_DESC_MINI_PLANT", price: 1, iconName: "leaf.circle")
            ]
        )

        marketSections = [demoCollection, studyCollection, relaxationCollection, collectibles]

        themes = [
            RoomTheme(
                id: RoomThemeID.starter,
                name: localization.translate("ROOM_THEME_STARTER"),
                background: LinearGradient(
                    colors: [Color("ForestGreen"), Color("ForestDark")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                assets: [
                    RoomAsset(id: RoomAssetID.bambooDesk, nameKey: "ROOM_ASSET_BAMBOO_DESK", descriptionKey: "ROOM_DESC_BAMBOO_DESK", price: 150, iconName: "desk"),
                    RoomAsset(id: RoomAssetID.zenPlant, nameKey: "ROOM_ASSET_ZEN_PLANT", descriptionKey: "ROOM_DESC_ZEN_PLANT", price: 200, iconName: "leaf"),
                    RoomAsset(id: RoomAssetID.warmLight, nameKey: "ROOM_ASSET_WARM_LIGHT", descriptionKey: "ROOM_DESC_WARM_LIGHT", price: 120, iconName: "lightbulb")
                ]
            ),
            RoomTheme(
                id: RoomThemeID.lake,
                name: localization.translate("ROOM_THEME_LAKE"),
                background: LinearGradient(
                    colors: [Color("LakeBlue"), Color("LakeNight")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                assets: [
                    RoomAsset(id: RoomAssetID.lakeView, nameKey: "ROOM_ASSET_LAKE_VIEW", descriptionKey: "ROOM_DESC_LAKE_VIEW", price: 280, iconName: "sun.max"),
                    RoomAsset(id: RoomAssetID.hammock, nameKey: "ROOM_ASSET_HAMMOCK", descriptionKey: "ROOM_DESC_HAMMOCK", price: 350, iconName: "bed.double"),
                    RoomAsset(id: RoomAssetID.woodShelf, nameKey: "ROOM_ASSET_WOOD_SHELF", descriptionKey: "ROOM_DESC_WOOD_SHELF", price: 220, iconName: "books.vertical")
                ]
            )
        ]

        currentTheme = themes[0]
        ownedThemes = [themes[0].id]

        if let snapshot {
            apply(snapshot)
        }
    }

    var availableMarketSections: [MarketSection] {
        marketSections
    }

    var ownedAssets: [RoomAsset] {
        allAssets.filter { unlockedAssets.contains($0.id) }
    }

    private var allAssets: [RoomAsset] {
        themes.flatMap { $0.assets } + marketSections.flatMap { $0.assets }
    }

    private func asset(for id: UUID) -> RoomAsset? {
        allAssets.first { $0.id == id }
    }

    private func theme(for id: UUID) -> RoomTheme? {
        themes.first { $0.id == id }
    }

    func unlock(asset: RoomAsset, wallet: WalletViewModel) -> Bool {
        guard !unlockedAssets.contains(asset.id) else { return true }
        guard wallet.spend(amount: asset.price, description: localization.translate(asset.nameKey)) else { return false }
        unlockedAssets.insert(asset.id)
        changePublisher.send()
        return true
    }

    func place(asset: RoomAsset) {
        guard unlockedAssets.contains(asset.id) else { return }
        placedItems.append(PlacedItem(asset: asset))
        changePublisher.send()
    }

    func remove(assetID: UUID) {
        placedItems.removeAll { $0.asset.id == assetID }
        changePublisher.send()
    }

    func switchTheme(to theme: RoomTheme, wallet: WalletViewModel) {
        if !ownedThemes.contains(theme.id) {
            let success = wallet.spend(amount: 500, description: LocalizationManager.shared.translate("TXN_THEME_UNLOCK", arguments: [theme.name]))
            if success {
                ownedThemes.append(theme.id)
            } else {
                return
            }
        }
        currentTheme = theme
        changePublisher.send()
    }

    func snapshot() -> RoomSnapshot {
        RoomSnapshot(currentThemeID: currentTheme.id,
                     ownedThemes: ownedThemes,
                     unlockedAssets: Array(unlockedAssets),
                     placedAssets: placedItems.map { $0.asset.id })
    }

    private func apply(_ snapshot: RoomSnapshot) {
        unlockedAssets = Set(snapshot.unlockedAssets)
        ownedThemes = snapshot.ownedThemes.filter { theme(for: $0) != nil }
        if let restoredTheme = theme(for: snapshot.currentThemeID) {
            currentTheme = restoredTheme
        }
        placedItems = snapshot.placedAssets.compactMap { id in
            asset(for: id).map { PlacedItem(asset: $0) }
        }
        if ownedThemes.isEmpty {
            ownedThemes = [themes[0].id]
        }
        changePublisher.send()
    }
}

