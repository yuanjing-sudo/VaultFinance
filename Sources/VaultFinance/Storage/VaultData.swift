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
        spendingStreak: SpendingStreak = .init()
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
    }
}
