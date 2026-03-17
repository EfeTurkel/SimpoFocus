import Foundation

struct SyncedAppSettings: Codable {
    var onboardingCompleted: Bool
    var userName: String
    var paywallLaunchCount: Int
    var paywallLastShownDate: String
    var specialOfferLastMilestoneShown: Int
    var specialOfferMilestoneShowCount: Int
    var lifetimeOfferShown: Bool
    var proWelcomeBonusGranted: Bool
    var proMonthlyBonusLastYearMonth: String
    var sessionsSinceLastProNudge: Int
    var selectedTab: String
    var appLanguage: String
    var appTheme: String
    var entitlementIsPro: Bool
    var customCategoriesData: Data?

    static let `default` = SyncedAppSettings(
        onboardingCompleted: false,
        userName: "",
        paywallLaunchCount: 0,
        paywallLastShownDate: "",
        specialOfferLastMilestoneShown: 0,
        specialOfferMilestoneShowCount: 0,
        lifetimeOfferShown: false,
        proWelcomeBonusGranted: false,
        proMonthlyBonusLastYearMonth: "",
        sessionsSinceLastProNudge: 0,
        selectedTab: "forest",
        appLanguage: "en",
        appTheme: "system",
        entitlementIsPro: false,
        customCategoriesData: nil
    )

    init(onboardingCompleted: Bool,
         userName: String,
         paywallLaunchCount: Int,
         paywallLastShownDate: String,
         specialOfferLastMilestoneShown: Int,
         specialOfferMilestoneShowCount: Int,
         lifetimeOfferShown: Bool,
         proWelcomeBonusGranted: Bool,
         proMonthlyBonusLastYearMonth: String,
         sessionsSinceLastProNudge: Int,
         selectedTab: String,
         appLanguage: String,
         appTheme: String,
         entitlementIsPro: Bool,
         customCategoriesData: Data?) {
        self.onboardingCompleted = onboardingCompleted
        self.userName = userName
        self.paywallLaunchCount = paywallLaunchCount
        self.paywallLastShownDate = paywallLastShownDate
        self.specialOfferLastMilestoneShown = specialOfferLastMilestoneShown
        self.specialOfferMilestoneShowCount = specialOfferMilestoneShowCount
        self.lifetimeOfferShown = lifetimeOfferShown
        self.proWelcomeBonusGranted = proWelcomeBonusGranted
        self.proMonthlyBonusLastYearMonth = proMonthlyBonusLastYearMonth
        self.sessionsSinceLastProNudge = sessionsSinceLastProNudge
        self.selectedTab = selectedTab
        self.appLanguage = appLanguage
        self.appTheme = appTheme
        self.entitlementIsPro = entitlementIsPro
        self.customCategoriesData = customCategoriesData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
        paywallLaunchCount = try container.decodeIfPresent(Int.self, forKey: .paywallLaunchCount) ?? 0
        paywallLastShownDate = try container.decodeIfPresent(String.self, forKey: .paywallLastShownDate) ?? ""
        specialOfferLastMilestoneShown = try container.decodeIfPresent(Int.self, forKey: .specialOfferLastMilestoneShown) ?? 0
        specialOfferMilestoneShowCount = try container.decodeIfPresent(Int.self, forKey: .specialOfferMilestoneShowCount) ?? 0
        lifetimeOfferShown = try container.decodeIfPresent(Bool.self, forKey: .lifetimeOfferShown) ?? false
        proWelcomeBonusGranted = try container.decodeIfPresent(Bool.self, forKey: .proWelcomeBonusGranted) ?? false
        proMonthlyBonusLastYearMonth = try container.decodeIfPresent(String.self, forKey: .proMonthlyBonusLastYearMonth) ?? ""
        sessionsSinceLastProNudge = try container.decodeIfPresent(Int.self, forKey: .sessionsSinceLastProNudge) ?? 0
        selectedTab = try container.decodeIfPresent(String.self, forKey: .selectedTab) ?? "forest"
        appLanguage = try container.decodeIfPresent(String.self, forKey: .appLanguage) ?? "en"
        appTheme = try container.decodeIfPresent(String.self, forKey: .appTheme) ?? "system"
        entitlementIsPro = try container.decodeIfPresent(Bool.self, forKey: .entitlementIsPro) ?? false
        customCategoriesData = try container.decodeIfPresent(Data.self, forKey: .customCategoriesData)
    }
}

struct UserStateSnapshot: Codable {
    var wallet: WalletViewModel.Snapshot
    var market: MarketViewModel.Snapshot
    var bank: BankSnapshot
    var timer: PomodoroTimerService.Snapshot
    var room: RoomSnapshot
    var appSettings: SyncedAppSettings
    var updatedAt: Date
    var deviceId: String
}
