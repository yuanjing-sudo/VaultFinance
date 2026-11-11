import Foundation

// MARK: - VaultData

/// Top-level encrypted store for all user data.
/// Defined here (previously referenced but missing) so LocalStorage can encode/decode it.
struct VaultData: Codable {
    var profile: UserProfile
    var goals: [FinancialGoal]
    var categories: [BudgetCategory]
    var transactions: [Transaction]
    var assets: [AssetHolding]
    var liabilities: [Liability]
    var lessons: [Lesson]
    var achievements: [Achievement]
    var healthScores: [FinancialHealthScore]
    var spendingDays: [SpendingDay]
    var spendingStreak: SpendingStreak
    var piggyBank: PiggyBank
    var piggyDeposits: [PiggyDeposit]
    var bills: [Bill]
    var subscriptions: [Subscription]
    var creditScores: [CreditScoreRecord]
    var taxProfile: TaxProfile
    var watchlist: [WatchlistItem]
    var recurringTransactions: [RecurringTransaction]
    var challenges: [SavingsChallenge]
    var financialEvents: [FinancialEvent]
    var netWorthSnapshots: [NetWorthSnapshot]
    var reminders: [Reminder]
    var themeSettings: AppThemeSettings
    var roundUpSettings: RoundUpSettings

    init(
        profile: UserProfile,
        goals: [FinancialGoal] = [],
        categories: [BudgetCategory] = [],
        transactions: [Transaction] = [],
        assets: [AssetHolding] = [],
        liabilities: [Liability] = [],
        lessons: [Lesson] = [],
        achievements: [Achievement] = [],
        healthScores: [FinancialHealthScore] = [],
        spendingDays: [SpendingDay] = [],
        spendingStreak: SpendingStreak = .init(),
        piggyBank: PiggyBank = .init(),
        piggyDeposits: [PiggyDeposit] = [],
        bills: [Bill] = [],
        subscriptions: [Subscription] = [],
        creditScores: [CreditScoreRecord] = [],
        taxProfile: TaxProfile = .init(),
        watchlist: [WatchlistItem] = [],
        recurringTransactions: [RecurringTransaction] = [],
        challenges: [SavingsChallenge] = [],
        financialEvents: [FinancialEvent] = [],
        netWorthSnapshots: [NetWorthSnapshot] = [],
        reminders: [Reminder] = [],
        themeSettings: AppThemeSettings = .init(),
        roundUpSettings: RoundUpSettings = .init()
    ) {
        self.profile = profile
        self.goals = goals
        self.categories = categories
        self.transactions = transactions
        self.assets = assets
        self.liabilities = liabilities
        self.lessons = lessons
        self.achievements = achievements
        self.healthScores = healthScores
        self.spendingDays = spendingDays
        self.spendingStreak = spendingStreak
        self.piggyBank = piggyBank
        self.piggyDeposits = piggyDeposits
        self.bills = bills
        self.subscriptions = subscriptions
        self.creditScores = creditScores
        self.taxProfile = taxProfile
        self.watchlist = watchlist
        self.recurringTransactions = recurringTransactions
        self.challenges = challenges
        self.financialEvents = financialEvents
        self.netWorthSnapshots = netWorthSnapshots
        self.reminders = reminders
        self.themeSettings = themeSettings
        self.roundUpSettings = roundUpSettings
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case profile, goals, categories, transactions, assets, liabilities, lessons,
             achievements, healthScores, spendingDays, spendingStreak, piggyBank,
             piggyDeposits, bills, subscriptions, creditScores, taxProfile, watchlist,
             recurringTransactions, challenges, financialEvents, netWorthSnapshots,
             reminders, themeSettings, roundUpSettings
    }

    // MARK: - Backward-compatible decoding
    // Older vaults won't contain the newer keys, so every field is decoded
    // with a sensible fallback instead of failing the whole vault.

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile = try c.decodeIfPresent(UserProfile.self, forKey: .profile) ?? UserProfile()
        goals = try c.decodeIfPresent([FinancialGoal].self, forKey: .goals) ?? []
        categories = try c.decodeIfPresent([BudgetCategory].self, forKey: .categories) ?? []
        transactions = try c.decodeIfPresent([Transaction].self, forKey: .transactions) ?? []
        assets = try c.decodeIfPresent([AssetHolding].self, forKey: .assets) ?? []
        liabilities = try c.decodeIfPresent([Liability].self, forKey: .liabilities) ?? []
        lessons = try c.decodeIfPresent([Lesson].self, forKey: .lessons) ?? []
        achievements = try c.decodeIfPresent([Achievement].self, forKey: .achievements) ?? []
        healthScores = try c.decodeIfPresent([FinancialHealthScore].self, forKey: .healthScores) ?? []
        spendingDays = try c.decodeIfPresent([SpendingDay].self, forKey: .spendingDays) ?? []
        spendingStreak = try c.decodeIfPresent(SpendingStreak.self, forKey: .spendingStreak) ?? SpendingStreak()
        piggyBank = try c.decodeIfPresent(PiggyBank.self, forKey: .piggyBank) ?? PiggyBank()
        piggyDeposits = try c.decodeIfPresent([PiggyDeposit].self, forKey: .piggyDeposits) ?? []
        bills = try c.decodeIfPresent([Bill].self, forKey: .bills) ?? []
        subscriptions = try c.decodeIfPresent([Subscription].self, forKey: .subscriptions) ?? []
        creditScores = try c.decodeIfPresent([CreditScoreRecord].self, forKey: .creditScores) ?? []
        taxProfile = try c.decodeIfPresent(TaxProfile.self, forKey: .taxProfile) ?? TaxProfile()
        watchlist = try c.decodeIfPresent([WatchlistItem].self, forKey: .watchlist) ?? []
        recurringTransactions = try c.decodeIfPresent([RecurringTransaction].self, forKey: .recurringTransactions) ?? []
        challenges = try c.decodeIfPresent([SavingsChallenge].self, forKey: .challenges) ?? []
        financialEvents = try c.decodeIfPresent([FinancialEvent].self, forKey: .financialEvents) ?? []
        netWorthSnapshots = try c.decodeIfPresent([NetWorthSnapshot].self, forKey: .netWorthSnapshots) ?? []
        reminders = try c.decodeIfPresent([Reminder].self, forKey: .reminders) ?? []
        themeSettings = try c.decodeIfPresent(AppThemeSettings.self, forKey: .themeSettings) ?? AppThemeSettings()
        roundUpSettings = try c.decodeIfPresent(RoundUpSettings.self, forKey: .roundUpSettings) ?? RoundUpSettings()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(profile, forKey: .profile)
        try c.encode(goals, forKey: .goals)
        try c.encode(categories, forKey: .categories)
        try c.encode(transactions, forKey: .transactions)
        try c.encode(assets, forKey: .assets)
        try c.encode(liabilities, forKey: .liabilities)
        try c.encode(lessons, forKey: .lessons)
        try c.encode(achievements, forKey: .achievements)
        try c.encode(healthScores, forKey: .healthScores)
        try c.encode(spendingDays, forKey: .spendingDays)
        try c.encode(spendingStreak, forKey: .spendingStreak)
        try c.encode(piggyBank, forKey: .piggyBank)
        try c.encode(piggyDeposits, forKey: .piggyDeposits)
        try c.encode(bills, forKey: .bills)
        try c.encode(subscriptions, forKey: .subscriptions)
        try c.encode(creditScores, forKey: .creditScores)
        try c.encode(taxProfile, forKey: .taxProfile)
        try c.encode(watchlist, forKey: .watchlist)
        try c.encode(recurringTransactions, forKey: .recurringTransactions)
        try c.encode(challenges, forKey: .challenges)
        try c.encode(financialEvents, forKey: .financialEvents)
        try c.encode(netWorthSnapshots, forKey: .netWorthSnapshots)
        try c.encode(reminders, forKey: .reminders)
        try c.encode(themeSettings, forKey: .themeSettings)
        try c.encode(roundUpSettings, forKey: .roundUpSettings)
    }
}
