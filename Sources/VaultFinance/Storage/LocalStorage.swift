import Foundation
import SwiftUI

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

    private var isSetup: Bool { keychainService.hasKey(forKey: LocalStorage.hasSetupKey) }

    init() {
        if !isSetup {
            setupEncryptionKey()
        }
        load()
    }

    private func setupEncryptionKey() {
        let password = "vault_default_passphrase_\(UUID().uuidString.prefix(8))"
        let data = Data(password.utf8)
        let sha = SHA256.hash(data: data)
        keychainService.set(Data(sha), forKey: LocalStorage.keyKey)
        keychainService.set(Data(true), forKey: LocalStorage.hasSetupKey)
    }

    private func encryptionKey() -> Data? {
        keychainService.data(forKey: LocalStorage.keyKey)
    }

    func load() {
        guard let data = keychainService.data(forKey: LocalStorage.dataKey),
              let key = encryptionKey()
        else {
            refresh()
            return
        }
        do {
            let decrypted = try AES.GCM.open(encrypted: data, using: SymmetricKey(data: key))
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(VaultData.self, from: decrypted)
            apply(decoded: decoded)
        } catch {
            print("Failed to decrypt data: \(error)")
            refresh()
        }
    }

    func save() {
        let data = VaultData(
            profile: profile, goals: goals, categories: categories,
            transactions: transactions, assets: assets, liabilities: liabilities,
            lessons: lessons, achievements: achievements, healthScores: healthScores,
            spendingDays: spendingDays, spendingStreak: spendingStreak
        )
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(data) else { return }
        guard let key = encryptionKey() else { return }
        do {
            let sealed = try AES.GCM.seal(encoded, using: SymmetricKey(data: key))
            keychainService.set(sealed.combined, forKey: LocalStorage.dataKey)
        } catch {
            print("Failed to encrypt: \(error)")
        }
    }

    func refresh() {
        apply(VaultData.demoData())
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
}

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
            ]
        )
    }
}
