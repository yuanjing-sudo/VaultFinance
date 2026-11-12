import Foundation
import SwiftUI
import Security

@MainActor
class LocalStorage: ObservableObject {
    static let shared = LocalStorage()

    private let keychainService = KeychainService.shared
    static let defaultStorageKey = "vault_finance_data_v1"
    static let dataKey = "vault_data"
    static let keyKey = "vault_key"
    static let hasSetupKey = "vault_setup"

    @Published var profile: UserProfile = .init()
    @Published var goals: [FinancialGoal] = []
    @Published var categories: [BudgetCategory] = []
    @Published var transactions: [Transaction] = []
    @Published var assets: [AssetHolding] = []
    @Published var liabilities: [Liability] = []
    @Published var lessons: [Lesson] = []
    @Published var achievements: [Achievement] = []
    @Published var healthScores: [FinancialHealthScore] = []
    @Published var spendingDays: [SpendingDay] = []
    @Published var spendingStreak: SpendingStreak = .init()
    @Published var piggyBank: PiggyBank = .init()
    @Published var piggyDeposits: [PiggyDeposit] = []
    @Published var bills: [Bill] = []
    @Published var subscriptions: [Subscription] = []
    @Published var creditScores: [CreditScoreRecord] = []
    @Published var taxProfile: TaxProfile = .init()
    @Published var watchlist: [WatchlistItem] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var challenges: [SavingsChallenge] = []
    @Published var financialEvents: [FinancialEvent] = []
    @Published var netWorthSnapshots: [NetWorthSnapshot] = []
    @Published var reminders: [Reminder] = []
    @Published var themeSettings: AppThemeSettings = .init()
    @Published var roundUpSettings: RoundUpSettings = .init()

    // MARK: - Wealth Lab
    @Published var automationRules: [AutomationRule] = []
    @Published var automationRuns: [AutomationRun] = []
    @Published var portfolioHoldings: [PortfolioHolding] = []
    @Published var taxDocuments: [TaxDocument] = []
    @Published var subscriptionReviews: [SubscriptionReview] = []
    @Published var weeklyQuests: [WeeklyQuest] = []
    @Published var streakShields: [StreakShield] = []
    @Published var buddies: [AccountabilityBuddy] = []
    @Published var buddyChallenges: [BuddyChallenge] = []
    @Published var personalizedPlan: PersonalizedPlan?

    private var isSetup: Bool { keychainService.hasKey(forKey: LocalStorage.hasSetupKey) }

    init() {
        if !isSetup {
            setupEncryptionKey()
        }
        load()
    }

    private func setupEncryptionKey() {
        keychainService.set(Data([1]), forKey: LocalStorage.hasSetupKey)
    }

    func load() {
        guard let data = keychainService.data(forKey: LocalStorage.dataKey) else {
            refresh()
            return
        }
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(VaultData.self, from: data)
            apply(decoded: decoded)
        } catch {
            print("Failed to decode data: \(error)")
            refresh()
        }
    }

    func save() {
        let data = VaultData(
            profile: profile, goals: goals, categories: categories,
            transactions: transactions, assets: assets, liabilities: liabilities,
            lessons: lessons, achievements: achievements, healthScores: healthScores,
            spendingDays: spendingDays, spendingStreak: spendingStreak,
            piggyBank: piggyBank, piggyDeposits: piggyDeposits,
            bills: bills, subscriptions: subscriptions,
            creditScores: creditScores, taxProfile: taxProfile, watchlist: watchlist,
            recurringTransactions: recurringTransactions, challenges: challenges,
            financialEvents: financialEvents, netWorthSnapshots: netWorthSnapshots,
            reminders: reminders, themeSettings: themeSettings, roundUpSettings: roundUpSettings,
            automationRules: automationRules, automationRuns: automationRuns,
            portfolioHoldings: portfolioHoldings, taxDocuments: taxDocuments,
            subscriptionReviews: subscriptionReviews, weeklyQuests: weeklyQuests,
            streakShields: streakShields, buddies: buddies,
            buddyChallenges: buddyChallenges, personalizedPlan: personalizedPlan
        )
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(data) else { return }
        keychainService.set(encoded, forKey: LocalStorage.dataKey)
    }

    func refresh() {
        apply(decoded: VaultData.demoData())
    }

    private func apply(decoded: VaultData) {
        profile = decoded.profile
        goals = decoded.goals
        categories = decoded.categories
        transactions = decoded.transactions
        assets = decoded.assets
        liabilities = decoded.liabilities
        lessons = decoded.lessons
        achievements = decoded.achievements
        healthScores = decoded.healthScores
        spendingDays = decoded.spendingDays
        spendingStreak = decoded.spendingStreak
        piggyBank = decoded.piggyBank
        piggyDeposits = decoded.piggyDeposits
        bills = decoded.bills
        subscriptions = decoded.subscriptions
        creditScores = decoded.creditScores
        taxProfile = decoded.taxProfile
        watchlist = decoded.watchlist
        recurringTransactions = decoded.recurringTransactions
        challenges = decoded.challenges
        financialEvents = decoded.financialEvents
        netWorthSnapshots = decoded.netWorthSnapshots
        reminders = decoded.reminders
        themeSettings = decoded.themeSettings
        roundUpSettings = decoded.roundUpSettings
        automationRules = decoded.automationRules
        automationRuns = decoded.automationRuns
        portfolioHoldings = decoded.portfolioHoldings
        taxDocuments = decoded.taxDocuments
        subscriptionReviews = decoded.subscriptionReviews
        weeklyQuests = decoded.weeklyQuests
        streakShields = decoded.streakShields
        buddies = decoded.buddies
        buddyChallenges = decoded.buddyChallenges
        personalizedPlan = decoded.personalizedPlan
    }

    /// Record spending for a day and recompute the streak.
    func recordSpending(date: Date, amount: Double, category: CategoryType, notes: String = "") {
        let startOfDay = Calendar.current.startOfDay(for: date)
        if let index = spendingDays.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            spendingDays[index].amount += amount
            spendingDays[index].transactionCount += 1
            spendingDays[index].notes = notes
        } else {
            spendingDays.append(SpendingDay(date: startOfDay, amount: amount, transactionCount: 1, goalMet: amount <= spendingStreak.dailyGoal, notes: notes))
        }
        spendingStreak = SpendingStreak.compute(from: spendingDays, dailyGoal: spendingStreak.dailyGoal)
        save()
    }

    // MARK: - Weekly quests

    func ensureWeeklyQuests(force: Bool = false) {
        let weekStart = WealthLabEngine.currentWeekStart()
        let needsRefresh = force || weeklyQuests.isEmpty
            || weeklyQuests.contains { !Calendar.current.isDate($0.weekStart, inSameDayAs: weekStart) }
        guard needsRefresh else { return }
        weeklyQuests = WealthLabEngine.generateQuests(
            spendingDays: spendingDays,
            transactions: transactions,
            deposits: piggyDeposits,
            categories: categories,
            dailyGoal: spendingStreak.dailyGoal
        )
        save()
    }

    func useStreakShield() -> Bool {
        guard let index = streakShields.firstIndex(where: { !$0.isUsed }) else { return false }
        streakShields[index].usedDate = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let day = Calendar.current.startOfDay(for: yesterday)
        if !spendingDays.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            spendingDays.append(SpendingDay(date: day, amount: 0, transactionCount: 0,
                                           goalMet: true, notes: "Streak shield used"))
        }
        spendingStreak = SpendingStreak.compute(from: spendingDays, dailyGoal: spendingStreak.dailyGoal)
        save()
        return true
    }

    // MARK: - Automation

    @discardableResult
    func runAutomationRules() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let monthTransactions = transactions.filter { $0.date >= monthStart && $0.date <= now && $0.amount > 0 }
        let spent = monthTransactions.reduce(0) { $0 + $1.amount }
        let budgeted = categories.reduce(0) { $0 + $1.budgetedAmount }
        let safe = WealthLabEngine.safeToSpend(profile: profile, transactions: transactions,
                                               bills: bills, goals: goals, now: now)
        let weekday = calendar.component(.weekday, from: now)
        let day = calendar.component(.day, from: now)
        let paydayEvent = financialEvents.contains {
            $0.type == .income && calendar.isDateInToday($0.date)
        }
        let billPaidToday = bills.contains { bill in
            guard let paid = bill.lastPaidDate else { return false }
            return calendar.isDateInToday(paid)
        }

        var generated: [AutomationRun] = []
        for index in automationRules.indices {
            let rule = automationRules[index]
            var context = WealthLabEngine.AutomationContext()
            context.isWeeklyReview = weekday == 1
            context.isPayday = paydayEvent || day == 1 || day == 15
            context.budgetSurplus = max(budgeted - spent, 0)
            context.budgetOverspend = max(spent - budgeted, 0)
            context.billPaid = billPaidToday
            context.safeToSpend = safe.remainingToday
            if let category = rule.category {
                context.category = category
                context.categorySpent = monthTransactions
                    .filter { $0.category == category }
                    .reduce(0) { $0 + $1.amount }
            } else {
                context.categorySpent = spent
            }

            guard let run = WealthLabEngine.evaluate(rule: rule, context: context, now: now) else { continue }
            applyAutomation(action: rule.action, amount: run.amount, note: rule.name, now: now)
            automationRules[index].lastRun = now
            automationRules[index].runCount += 1
            generated.append(run)
        }

        if !generated.isEmpty {
            automationRuns.insert(contentsOf: generated, at: 0)
            automationRuns = Array(automationRuns.prefix(50))
            save()
        }
        return generated.count
    }

    private func applyAutomation(action: AutomationAction, amount: Double, note: String, now: Date) {
        switch action {
        case .feedPiggy:
            guard amount > 0 else { return }
            piggyBank.depositedAmount += amount
            piggyBank.depositCount += 1
            piggyBank.lastDepositDate = now
            piggyDeposits.append(PiggyDeposit(piggyId: piggyBank.id, amount: amount,
                                              date: now, note: "Automation: \(note)",
                                              source: .budgetRollover))
        case .fundGoal:
            guard amount > 0, let index = goals.firstIndex(where: { !$0.isComplete }) else { return }
            goals[index].currentAmount += amount
        case .topUpBudget:
            guard amount > 0 else { return }
            if let index = categories.firstIndex(where: { $0.type == .wants }) {
                categories[index].budgetedAmount += amount
            } else if let index = categories.indices.first {
                categories[index].budgetedAmount += amount
            }
        case .createReminder:
            reminders.append(Reminder(title: "Automation: \(note)",
                                      date: now.addingTimeInterval(86_400),
                                      repeatRule: .none))
        case .flagOverspend:
            reminders.append(Reminder(title: "Check overspend — \(note)",
                                      date: now.addingTimeInterval(3_600),
                                      repeatRule: .none))
        case .logNote:
            break
        }
    }
}

@MainActor
class KeychainService {
    static let shared = KeychainService()
    private init() {}

    func set(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    func hasKey(forKey key: String) -> Bool { data(forKey: key) != nil }
}

extension VaultData {
    static func demoData() -> VaultData {
        let now = Date()
        return VaultData(
            profile: .init(
                age: 28,
                country: "US",
                currency: "USD",
                employmentStatus: .employed,
                monthlyIncome: 5000,
                otherIncome: [.init(amount: 200)],
                existingSavings: 15000
            ),
            goals: [
                .init(title: "Emergency Fund", targetAmount: 15000, currentAmount: 6000, horizon: .lifelong),
                .init(title: "Laptop", targetAmount: 3000, currentAmount: 500, horizon: .yearly),
                .init(title: "Travel", targetAmount: 5000, currentAmount: 1200, horizon: .yearly),
            ],
            categories: [
                .init(name: "Rent/Housing", type: .needsFixed, budgetedAmount: 2000, spentAmount: 2000, month: now),
                .init(name: "Food", type: .needsVariable, budgetedAmount: 500, spentAmount: 450, month: now),
                .init(name: "Groceries", type: .needsVariable, budgetedAmount: 400, spentAmount: 380, month: now),
                .init(name: "Transport", type: .needsVariable, budgetedAmount: 200, spentAmount: 180, month: now),
                .init(name: "Restaurants", type: .wants, budgetedAmount: 300, spentAmount: 340, month: now),
                .init(name: "Entertainment", type: .wants, budgetedAmount: 150, spentAmount: 120, month: now),
                .init(name: "Emergency Fund", type: .savings, budgetedAmount: 750, spentAmount: 750, month: now),
                .init(name: "Investments", type: .savings, budgetedAmount: 750, spentAmount: 600, month: now),
            ],
            transactions: [
                .init(id: UUID(), title: "Weekly Groceries", amount: 120, categoryId: UUID(), category: .needsVariable, date: Calendar.current.date(byAdding: .day, value: -1, to: now)!, notes: "Supermarket"),
                .init(id: UUID(), title: "Dinner Out", amount: 65, categoryId: UUID(), category: .wants, date: Calendar.current.date(byAdding: .day, value: -2, to: now)!, notes: "Local restaurant"),
                .init(id: UUID(), title: "Gas", amount: 55, categoryId: UUID(), category: .needsVariable, date: Calendar.current.date(byAdding: .day, value: -3, to: now)!, notes: "Petrol station"),
                .init(id: UUID(), title: "Netflix", amount: 18, categoryId: UUID(), category: .needsFixed, date: Calendar.current.date(byAdding: .day, value: -5, to: now)!, notes: "Monthly subscription"),
                .init(id: UUID(), title: "Savings Deposit", amount: -750, categoryId: UUID(), category: .savings, date: Calendar.current.date(byAdding: .day, value: -10, to: now)!, notes: "Emergency fund"),
            ],
            assets: [
                .init(id: UUID(), title: "Savings Account", category: .cash, quantity: 1, costBasis: 15000, currentMarketValue: 15000),
                .init(id: UUID(), title: "SPY ETF", category: .stock, quantity: 10, costBasis: 4000, currentMarketValue: 5200),
                .init(id: UUID(), title: "Gold Bar", category: .alternative, quantity: 1, costBasis: 2500, currentMarketValue: 2800),
            ],
            liabilities: [
                .init(id: UUID(), title: "Car Loan", type: .loan, balance: 8000, interestRate: 4.5, monthlyPayment: 350),
            ],
            lessons: [
                .init(id: UUID(), title: "Budgeting Basics", description: "Learn the 50/30/20 rule and how to build a budget.", durationMinutes: 8, difficulty: .beginner, locked: false, xp: 50),
                .init(id: UUID(), title: "Needs vs Wants", description: "Understand the difference and why it matters.", durationMinutes: 6, difficulty: .beginner, locked: false, xp: 40),
                .init(id: UUID(), title: "Compound Interest", description: "How your money grows over time.", durationMinutes: 10, difficulty: .intermediate, locked: true, xp: 60),
                .init(id: UUID(), title: "Stocks vs ETFs", description: "Diversification explained simply.", durationMinutes: 12, difficulty: .advanced, locked: true, xp: 70),
            ],
            achievements: [
                .init(id: UUID(), title: "First Step", description: "Created your first budget", icon: "checkmark.circle.fill", unlocked: true, unlockedAt: now),
                .init(id: UUID(), title: "Saver", description: "Made your first savings transfer", icon: "pencil.righthalf.and.dollar.fill", unlocked: false),
                .init(id: UUID(), title: "Streak", description: "Budgeted for 7 days straight", icon: "flame.fill", unlocked: false),
            ],
            healthScores: [
                .init(
                    id: UUID(),
                    date: now,
                    score: 62,
                    factors: [
                        .init(id: UUID(), name: "Savings Consistency", score: 70, weight: 25, description: "How consistently you save month over month."),
                        .init(id: UUID(), name: "Budget Compliance", score: 55, weight: 25, description: "How well you stayed within your allocations."),
                        .init(id: UUID(), name: "Emergency Fund", score: 50, weight: 30, description: "Months of expenses you could cover from savings."),
                        .init(id: UUID(), name: "Debt Management", score: 75, weight: 20, description: "Health of your debt obligations."),
                        .init(id: UUID(), name: "Goal Progress", score: 60, weight: 15, description: "Progress toward your financial goals."),
                    ],
                    recommendation: "Good health with room to improve. Focus on your weakest area."
                )
            ],
            piggyBank: .init(
                name: "Vault Piggy",
                targetAmount: 5000,
                depositedAmount: 1250,
                currency: "USD",
                personality: .classic,
                colorTheme: "#F5A623"
            ),
            piggyDeposits: [
                .init(piggyId: UUID(), amount: 500, date: Calendar.current.date(byAdding: .day, value: -10, to: now)!, note: "Paycheck savings", source: .manual),
                .init(piggyId: UUID(), amount: 300, date: Calendar.current.date(byAdding: .day, value: -5, to: now)!, note: "Budget rollover", source: .budgetRollover),
                .init(piggyId: UUID(), amount: 200, date: Calendar.current.date(byAdding: .day, value: -2, to: now)!, note: "Round up", source: .roundUp),
                .init(piggyId: UUID(), amount: 250, date: now, note: "Bonus", source: .manual),
            ],
            bills: [
                .init(title: "Electricity", amount: 120, frequency: .monthly, nextDueDate: Calendar.current.date(byAdding: .day, value: 5, to: now)!, status: .upcoming, category: "Utilities", autoPay: true),
                .init(title: "Internet", amount: 60, frequency: .monthly, nextDueDate: Calendar.current.date(byAdding: .day, value: 12, to: now)!, status: .upcoming, category: "Utilities", autoPay: false),
                .init(title: "Car Insurance", amount: 150, frequency: .monthly, nextDueDate: Calendar.current.date(byAdding: .day, value: -2, to: now)!, status: .overdue, category: "Transport", autoPay: false),
                .init(title: "Phone Bill", amount: 80, frequency: .monthly, nextDueDate: Calendar.current.date(byAdding: .day, value: 20, to: now)!, status: .upcoming, category: "Utilities", autoPay: true),
            ],
            subscriptions: [
                .init(title: "Netflix", amount: 15.99, cycle: .monthly, nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: now)!, category: "Entertainment", isActive: true),
                .init(title: "Spotify", amount: 9.99, cycle: .monthly, nextBillingDate: Calendar.current.date(byAdding: .day, value: 10, to: now)!, category: "Entertainment", isActive: true),
                .init(title: "Gym Membership", amount: 49.99, cycle: .monthly, nextBillingDate: Calendar.current.date(byAdding: .day, value: 15, to: now)!, category: "Health", isActive: true),
                .init(title: "iCloud Storage", amount: 2.99, cycle: .monthly, nextBillingDate: Calendar.current.date(byAdding: .day, value: 25, to: now)!, category: "Utilities", isActive: true),
            ],
            creditScores: [
                .init(date: Calendar.current.date(byAdding: .month, value: -3, to: now)!, score: 688, bureau: "Equifax"),
                .init(date: Calendar.current.date(byAdding: .month, value: -2, to: now)!, score: 702, bureau: "Equifax"),
                .init(date: Calendar.current.date(byAdding: .month, value: -1, to: now)!, score: 715, bureau: "Equifax"),
                .init(date: now, score: 729, bureau: "Equifax"),
            ],
            watchlist: [
                .init(symbol: "AAPL", name: "Apple Inc.", price: 229.87, changePercent: 1.2, targetPrice: 250, alertAbove: true),
                .init(symbol: "TSLA", name: "Tesla Inc.", price: 251.44, changePercent: -2.1, targetPrice: 200, alertAbove: false),
                .init(symbol: "VOO", name: "Vanguard S&P 500 ETF", price: 512.35, changePercent: 0.6, targetPrice: 550, alertAbove: true),
            ],
            challenges: [
                .init(title: "52-Week Challenge", description: "Save $1 more each week for a year.", targetAmount: 1378, savedAmount: 276, type: .fiftyTwoWeek, daysCompleted: 23),
                .init(title: "No-Spend Weekend", description: "Zero discretionary spending this weekend.", targetAmount: 100, savedAmount: 40, type: .noSpend, daysCompleted: 4),
            ],
            financialEvents: [
                .init(title: "Paycheck", date: Calendar.current.date(byAdding: .day, value: 2, to: now)!, amount: 2500, type: .income),
                .init(title: "Emergency Fund Goal", date: Calendar.current.date(byAdding: .month, value: 2, to: now)!, amount: 15000, type: .goal),
                .init(title: "Credit Card Due", date: Calendar.current.date(byAdding: .day, value: 7, to: now)!, amount: 340, type: .bill),
            ],
            netWorthSnapshots: [
                .init(date: Calendar.current.date(byAdding: .month, value: -5, to: now)!, assets: 28000, liabilities: 11000),
                .init(date: Calendar.current.date(byAdding: .month, value: -4, to: now)!, assets: 29500, liabilities: 10500),
                .init(date: Calendar.current.date(byAdding: .month, value: -3, to: now)!, assets: 30500, liabilities: 9800),
                .init(date: Calendar.current.date(byAdding: .month, value: -2, to: now)!, assets: 32000, liabilities: 9200),
                .init(date: Calendar.current.date(byAdding: .month, value: -1, to: now)!, assets: 33800, liabilities: 8600),
                .init(date: now, assets: 35600, liabilities: 8000),
            ],
            reminders: [
                .init(title: "Review monthly budget", date: Calendar.current.date(byAdding: .day, value: 1, to: now)!, repeatRule: .monthly),
                .init(title: "Deposit into piggy bank", date: Calendar.current.date(byAdding: .day, value: 3, to: now)!, repeatRule: .weekly),
            ],
            automationRules: [
                .init(name: "Surplus to piggy", trigger: .budgetSurplus, action: .feedPiggy,
                      amount: 25, threshold: 50, notes: "Feed the piggy when the budget is healthy."),
                .init(name: "Payday goal boost", trigger: .payday, action: .fundGoal,
                      amount: 100, threshold: 0, notes: "Top up the closest goal on payday."),
                .init(name: "Weekly review nudge", trigger: .weeklyReview, action: .createReminder,
                      amount: 0, threshold: 0, notes: "Sunday money check-in."),
                .init(name: "Low safe-to-spend alert", trigger: .lowSafeToSpend, action: .flagOverspend,
                      amount: 0, threshold: 20, notes: "Warn when today is nearly used up."),
            ],
            portfolioHoldings: [
                .init(symbol: "VOO", name: "Vanguard S&P 500 ETF", shares: 8, averageCost: 420,
                      currentPrice: 512.35, assetClass: "ETF", targetWeight: 40),
                .init(symbol: "AAPL", name: "Apple Inc.", shares: 6, averageCost: 180,
                      currentPrice: 229.87, assetClass: "Stock", targetWeight: 25),
                .init(symbol: "BTC", name: "Bitcoin", shares: 0.15, averageCost: 40000,
                      currentPrice: 67000, assetClass: "Crypto", targetWeight: 15),
                .init(symbol: "CASH", name: "High-yield cash", shares: 5000, averageCost: 1,
                      currentPrice: 1, assetClass: "Cash", targetWeight: 20),
            ],
            taxDocuments: [
                .init(title: "W-2 — Acme Corp", kind: .w2, taxYear: 2025, amount: 60000,
                      dueDate: Calendar.current.date(byAdding: .month, value: 3, to: now)!, isFiled: true),
                .init(title: "1099 — Freelance", kind: .form1099, taxYear: 2025, amount: 4200,
                      dueDate: Calendar.current.date(byAdding: .month, value: 3, to: now)!),
                .init(title: "Mortgage interest", kind: .form1098, taxYear: 2025, amount: 2500,
                      dueDate: Calendar.current.date(byAdding: .month, value: 3, to: now)!),
                .init(title: "Home office receipts", kind: .receipt, taxYear: 2025, amount: 840),
            ],
            subscriptionReviews: [
                .init(subscriptionTitle: "Netflix", monthlyCost: 15.99, verdict: .keep,
                      lastReviewed: now, note: "Watched every week."),
                .init(subscriptionTitle: "Spotify", monthlyCost: 9.99, verdict: .review,
                      lastReviewed: Calendar.current.date(byAdding: .day, value: -45, to: now)!,
                      note: "Price increased — check the family plan.", priceHikeDetected: true),
                .init(subscriptionTitle: "Gym Membership", monthlyCost: 49.99, verdict: .cancel,
                      lastReviewed: Calendar.current.date(byAdding: .day, value: -60, to: now)!,
                      note: "Only visited twice this quarter."),
            ],
            weeklyQuests: [],
            streakShields: [
                .init(earnedDate: Calendar.current.date(byAdding: .day, value: -12, to: now)!, source: "7-day streak"),
                .init(earnedDate: Calendar.current.date(byAdding: .day, value: -3, to: now)!, source: "Quest reward"),
            ],
            buddies: [
                .init(name: "You", emoji: "🦊", streak: 6, weeklySaved: 120, isMe: true),
                .init(name: "Maya", emoji: "🐼", streak: 9, weeklySaved: 95),
                .init(name: "Noah", emoji: "🐯", streak: 4, weeklySaved: 160),
            ],
            buddyChallenges: [
                .init(title: "No-spend weekend", buddyName: "Maya", target: 100,
                      myProgress: 40, buddyProgress: 55,
                      endsOn: Calendar.current.date(byAdding: .day, value: 3, to: now)!,
                      reward: "Pick the next movie"),
                .init(title: "Coffee fund sprint", buddyName: "Noah", target: 75,
                      myProgress: 75, buddyProgress: 60,
                      endsOn: Calendar.current.date(byAdding: .day, value: 1, to: now)!,
                      reward: "Loser buys coffee"),
            ]
        )
    }
}
