import Foundation

// MARK: - Core Money Models

struct Money: Codable, Identifiable, Hashable {
    let id = UUID()
    var amount: Double
    var currency: String

    init(amount: Double = 0, currency: String = "USD") {
        self.amount = amount
        self.currency = currency
    }

    static func == (lhs: Money, rhs: Money) -> Bool {
        lhs.id == rhs.id
    }

    func formatted(in context: FormatContext) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount.formatted(.number))"
    }

    func formatted() -> String {
        formatted(in: FormatContext())
    }
}

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var age: Int?
    var country: String?
    var currency: String
    var employmentStatus: EmploymentStatus
    var monthlyIncome: Double
    var otherIncome: [Money]
    var existingSavings: Double
    var notes: String

    // Additional editable profile factors
    var riskTolerance: String          // conservative / moderate / aggressive
    var investmentExperience: String   // beginner / intermediate / advanced
    var dependents: Int
    var maritalStatus: String?         // single / partnered / married / divorced / widowed
    var housingStatus: String?         // rent / own / with-family / other
    var debtComfortLevel: String       // low / medium / high
    var savingsTargetPercent: Double   // target % of income to save each month

    init(id: UUID = UUID(), age: Int? = nil, country: String? = nil, currency: String = "USD",
         employmentStatus: EmploymentStatus = .unemployed, monthlyIncome: Double = 0,
         otherIncome: [Money] = [], existingSavings: Double = 0,
         riskTolerance: String = "moderate", investmentExperience: String = "beginner",
         dependents: Int = 0, maritalStatus: String? = nil, housingStatus: String? = nil,
         debtComfortLevel: String = "medium", savingsTargetPercent: Double = 20) {
        self.id = id
        self.age = age
        self.country = country
        self.currency = currency
        self.employmentStatus = employmentStatus
        self.monthlyIncome = monthlyIncome
        self.otherIncome = otherIncome
        self.existingSavings = existingSavings
        self.riskTolerance = riskTolerance
        self.investmentExperience = investmentExperience
        self.dependents = dependents
        self.maritalStatus = maritalStatus
        self.housingStatus = housingStatus
        self.debtComfortLevel = debtComfortLevel
        self.savingsTargetPercent = savingsTargetPercent
    }

    var totalMonthlyIncome: Double {
        otherIncome.reduce(monthlyIncome) { $0 + $1.amount }
    }

    enum EmploymentStatus: String, Codable {
        case employed = "Employed"
        case selfEmployed = "Self-Employed"
        case student = "Student"
        case unemployed = "Unemployed"
        case retired = "Retired"
        var localized: String { self.rawValue }
    }
}

// MARK: - Financial Goals

enum GoalTimeHorizon: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case yearly = "Yearly"
    case lifelong = "Lifelong"

    var localized: String { self.rawValue }
}

struct FinancialGoal: Codable, Identifiable {
    let id: UUID
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var horizon: GoalTimeHorizon
    var targetDate: Date?
    var notes: String

    init(id: UUID = UUID(), title: String, targetAmount: Double, currentAmount: Double = 0,
         horizon: GoalTimeHorizon = .yearly, targetDate: Date? = nil) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.horizon = horizon
        self.targetDate = targetDate
    }

    var percentComplete: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount * 100, 100)
    }

    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }

    var isComplete: Bool { currentAmount >= targetAmount }
}

// MARK: - Budget Categories

enum CategoryType: String, Codable, CaseIterable {
    case needsFixed = "Needs (Fixed)"
    case needsVariable = "Needs (Variable)"
    case wants = "Wants"
    case savings = "Savings"

    var localized: String { self.rawValue }
}

extension CategoryType {
    var iconName: String {
        switch self {
        case .needsFixed: return "house.fill"
        case .needsVariable: return "cart.fill"
        case .wants: return "star.fill"
        case .savings: return "pencil.righthalf.and.dollar.fill"
        }
    }

    var color: String {
        switch self {
        case .needsFixed: return "red"
        case .needsVariable: return "orange"
        case .wants: return "purple"
        case .savings: return "green"
        }
    }
}

struct BudgetCategory: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: CategoryType
    var budgetedAmount: Double
    var spentAmount: Double
    var rolloverAmount: Double
    var rolloverDirection: RolloverDirection
    var month: Date
    var notes: String

    init(id: UUID = UUID(), name: String, type: CategoryType, budgetedAmount: Double = 0,
         spentAmount: Double = 0, rolloverAmount: Double = 0, rolloverDirection: RolloverDirection = .carry,
         month: Date = Date(), notes: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.budgetedAmount = budgetedAmount
        self.spentAmount = spentAmount
        self.rolloverAmount = rolloverAmount
        self.rolloverDirection = rolloverDirection
        self.month = month
        self.notes = notes
    }

    var remaining: Double { budgetedAmount - spentAmount }
    var overBudget: Double { spentAmount - budgetedAmount }
    var isOverBudget: Bool { spentAmount > budgetedAmount }
    var percentUsed: Double { budgetedAmount > 0 ? spentAmount / budgetedAmount * 100 : 0 }
    var effectiveBudget: Double { budgetedAmount + rolloverAmount }
}

enum RolloverDirection: String, Codable, CaseIterable {
    case carry = "Carry to next month"
    case save = "Move to savings"
    case transfer = "Transfer to another category"
    case goal = "Apply to goal"

    var localized: String { self.rawValue }
}

// MARK: - Transactions

struct Transaction: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var categoryId: UUID
    var category: CategoryType
    var date: Date
    var notes: String
    var merchant: String

    init(id: UUID = UUID(), title: String, amount: Double, categoryId: UUID, category: CategoryType,
         date: Date = Date(), notes: String = "", merchant: String = "") {
        self.id = id
        self.title = title
        self.amount = amount
        self.categoryId = categoryId
        self.category = category
        self.date = date
        self.notes = notes
        self.merchant = merchant
    }

    var formattedAmount: String {
        Money(amount: amount).formatted(in: .init())
    }
}

// MARK: - Rollover

struct MonthBudgetSnapshot: Codable, Identifiable {
    let id: UUID
    let month: Date
    let categories: [BudgetCategory]
    let income: Double
    let createdAt: Date
}

// MARK: - Assets & Wealth

enum AssetCategory: String, Codable, CaseIterable {
    case cash = "Cash & Deposits"
    case stock = "Stocks & ETFs"
    case realEstate = "Real Estate"
    case alternative = "Alternatives (Gold/Commodities)"

    var iconName: String {
        switch self {
        case .cash: return "bank.fill"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .realEstate: return "house.fill"
        case .alternative: return "diamond.fill"
        }
    }

    var color: String {
        switch self {
        case .cash: return "blue"
        case .stock: return "green"
        case .realEstate: return "teal"
        case .alternative: return "amber"
        }
    }
}

struct AssetHolding: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: AssetCategory
    var quantity: Double
    var costBasis: Double  // total purchased
    var currentMarketValue: Double
    var notes: String
    var lastUpdated: Date

    init(id: UUID = UUID(), title: String, category: AssetCategory, quantity: Double = 0,
         costBasis: Double = 0, currentMarketValue: Double = 0, notes: String = "",
         lastUpdated: Date = Date()) {
        self.id = id
        self.title = title
        self.category = category
        self.quantity = quantity
        self.costBasis = costBasis
        self.currentMarketValue = currentMarketValue
        self.notes = notes
        self.lastUpdated = lastUpdated
    }

    var unrealizedGainLoss: Double { currentMarketValue - costBasis }
    var unrealizedGainLossPercent: Double {
        costBasis > 0 ? unrealizedGainLoss / costBasis * 100 : 0
    }
}

struct Liability: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var type: LiabilityType
    var balance: Double
    var interestRate: Double  // annual %
    var monthlyPayment: Double
    var notes: String

    init(id: UUID = UUID(), title: String, type: LiabilityType = .loan, balance: Double = 0,
         interestRate: Double = 0, monthlyPayment: Double = 0, notes: String = "") {
        self.id = id
        self.title = title
        self.type = type
        self.balance = balance
        self.interestRate = interestRate
        self.monthlyPayment = monthlyPayment
        self.notes = notes
    }

    enum LiabilityType: String, Codable, CaseIterable {
        case mortgage = "Mortgage"
        case loan = "Loan"
        case creditCard = "Credit Card"
        case other = "Other"

        var localized: String { self.rawValue }
    }
}

// MARK: - Investment Education

struct MarketStock: Codable, Identifiable, Hashable {
    let id: UUID
    var symbol: String
    var name: String
    var price: Double
    var changePercent: Double
    var marketCap: Double
    var peRatio: Double
    var revenueGrowth: Double
    var profitMargin: Double
    var riskLevel: InvestmentRisk
    var trendReason: String
    var description: String

    enum InvestmentRisk: String, Codable, CaseIterable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        var localized: String { self.rawValue }
    }

    init(id: UUID = UUID(), symbol: String, name: String, price: Double = 0,
         changePercent: Double = 0, marketCap: Double = 0, peRatio: Double = 0,
         revenueGrowth: Double = 0, profitMargin: Double = 0, riskLevel: InvestmentRisk = .moderate,
         trendReason: String = "", description: String = "") {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.price = price
        self.changePercent = changePercent
        self.marketCap = marketCap
        self.peRatio = peRatio
        self.revenueGrowth = revenueGrowth
        self.profitMargin = profitMargin
        self.riskLevel = riskLevel
        self.trendReason = trendReason
        self.description = description
    }
}

// MARK: - Learning & Gamification

struct Lesson: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var durationMinutes: Int
    var difficulty: LessonDifficulty
    var locked: Bool
    var xp: Int

    enum LessonDifficulty: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"

        var localized: String { self.rawValue }
    }

    init(id: UUID = UUID(), title: String, description: String, durationMinutes: Int = 10,
         difficulty: LessonDifficulty = .beginner, locked: Bool = true, xp: Int = 50) {
        self.id = id
        self.title = title
        self.description = description
        self.durationMinutes = durationMinutes
        self.difficulty = difficulty
        self.locked = locked
        self.xp = xp
    }
}

struct Achievement: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
    var unlocked: Bool
    var unlockedAt: Date?
    var condition: AchievementCondition

    enum AchievementCondition: String, Codable, CaseIterable {
        case budgetStreak = "Budget for 7 days straight"
        case firstSaving = "Made your first save"
        case goalReached = "Reached a savings goal"
        case wealthMilestone = "Reached $10,000 net worth"
        case lessonComplete = "Completed 5 lessons"
        var localized: String { self.rawValue }
    }

    init(id: UUID = UUID(), title: String, description: String, icon: String, unlocked: Bool = false,
         unlockedAt: Date? = nil, condition: AchievementCondition = .firstSaving) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
        self.condition = condition
    }
}

struct QuizQuestion: Codable, Identifiable, Hashable {
    let id: UUID
    var question: String
    var options: [String]
    var correctIndex: Int
    var explanation: String

    init(id: UUID = UUID(), question: String, options: [String], correctIndex: Int, explanation: String) {
        self.id = id
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
    }
}

// MARK: - AI & Reports

enum AICapability: String, Codable, CaseIterable {
    case budgeting = "Budgeting AI"
    case savings = "Savings AI"
    case spending = "Spending AI"
    case goals = "Goal AI"
    case wealth = "Wealth AI"
    case education = "Education AI"
    case lifestyle = "Lifestyle AI"
    case news = "News AI"

    var localized: String { self.rawValue }
}

struct FinancialHealthScore: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var score: Int  // 0-100
    var factors: [HealthFactor]
    var recommendation: String

    struct HealthFactor: Codable, Identifiable, Hashable {
        let id: UUID
        var name: String
        var score: Int
        var weight: Int
        var description: String
    }
}
