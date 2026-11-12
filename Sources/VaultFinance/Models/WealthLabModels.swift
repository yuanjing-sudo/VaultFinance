import Foundation

// MARK: - Safe to Spend

/// A decomposed daily spending allowance so the user always knows what is
/// genuinely discretionary after fixed commitments and goal contributions.
struct SafeToSpendBreakdown: Codable, Hashable {
    var dailyAllowance: Double
    var spentToday: Double
    var remainingToday: Double
    var daysLeftInMonth: Int
    var monthlyDiscretionary: Double
    var fixedCommitments: Double
    var goalContributions: Double
    var projectedSavings: Double
    var safetyBuffer: Double

    var isOverToday: Bool { spentToday > dailyAllowance }
    var progress: Double {
        guard dailyAllowance > 0 else { return 0 }
        return min(spentToday / dailyAllowance, 1)
    }
}

// MARK: - Debt Payoff

enum PayoffStrategy: String, Codable, CaseIterable, Identifiable {
    case snowball = "Snowball"
    case avalanche = "Avalanche"
    case minimum = "Minimum Only"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .snowball: return "Smallest balance first — quick wins."
        case .avalanche: return "Highest interest first — least interest paid."
        case .minimum: return "Pay only the minimums — baseline."
        }
    }

    var icon: String {
        switch self {
        case .snowball: return "snowflake"
        case .avalanche: return "mountain.2.fill"
        case .minimum: return "clock.fill"
        }
    }
}

struct DebtAccountInput: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var balance: Double
    var apr: Double
    var minPayment: Double
}

struct PayoffMonthEntry: Identifiable, Hashable {
    var id = UUID()
    var month: Int
    var accountTitle: String
    var payment: Double
    var balanceAfter: Double
    var interest: Double
}

struct PayoffSummary: Identifiable, Hashable {
    var id = UUID()
    var strategy: PayoffStrategy
    var months: Int
    var totalInterest: Double
    var totalPaid: Double
    var debtFreeDate: Date
    var payoffOrder: [String]

    var yearsText: String {
        let years = months / 12
        let rem = months % 12
        if years == 0 { return "\(rem) mo" }
        return rem == 0 ? "\(years) yr" : "\(years) yr \(rem) mo"
    }
}

// MARK: - Automation Rules

enum AutomationTrigger: String, Codable, CaseIterable, Identifiable {
    case weeklyReview = "Weekly review"
    case payday = "Payday"
    case budgetSurplus = "Budget surplus"
    case budgetOverspend = "Budget overspend"
    case billPaid = "Bill paid"
    case lowSafeToSpend = "Low safe-to-spend"
    case categorySpend = "Category spend"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .weeklyReview: return "calendar.badge.clock"
        case .payday: return "banknote.fill"
        case .budgetSurplus: return "arrow.down.circle.fill"
        case .budgetOverspend: return "exclamationmark.triangle.fill"
        case .billPaid: return "checkmark.seal.fill"
        case .lowSafeToSpend: return "gauge.with.dots.needle.bottom.50percent"
        case .categorySpend: return "tag.fill"
        }
    }
}

enum AutomationAction: String, Codable, CaseIterable, Identifiable {
    case feedPiggy = "Feed piggy bank"
    case fundGoal = "Fund a goal"
    case topUpBudget = "Top up a budget"
    case createReminder = "Create reminder"
    case flagOverspend = "Flag overspend"
    case logNote = "Log a note"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .feedPiggy: return "pawprint.fill"
        case .fundGoal: return "target"
        case .topUpBudget: return "list.bullet.rectangle"
        case .createReminder: return "bell.fill"
        case .flagOverspend: return "flag.fill"
        case .logNote: return "note.text"
        }
    }
}

struct AutomationRule: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var trigger: AutomationTrigger
    var action: AutomationAction
    var amount: Double
    var threshold: Double
    var category: CategoryType?
    var isEnabled: Bool
    var lastRun: Date?
    var runCount: Int
    var notes: String

    init(id: UUID = UUID(), name: String, trigger: AutomationTrigger = .budgetSurplus,
         action: AutomationAction = .feedPiggy, amount: Double = 25,
         threshold: Double = 0, category: CategoryType? = nil,
         isEnabled: Bool = true, lastRun: Date? = nil, runCount: Int = 0,
         notes: String = "") {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.action = action
        self.amount = amount
        self.threshold = threshold
        self.category = category
        self.isEnabled = isEnabled
        self.lastRun = lastRun
        self.runCount = runCount
        self.notes = notes
    }
}

struct AutomationRun: Codable, Identifiable, Hashable {
    var id: UUID
    var ruleId: UUID
    var ruleName: String
    var date: Date
    var amount: Double
    var detail: String

    init(id: UUID = UUID(), ruleId: UUID, ruleName: String, date: Date = Date(),
         amount: Double = 0, detail: String = "") {
        self.id = id
        self.ruleId = ruleId
        self.ruleName = ruleName
        self.date = date
        self.amount = amount
        self.detail = detail
    }
}

// MARK: - Portfolio Tracker

struct PortfolioHolding: Codable, Identifiable, Hashable {
    var id: UUID
    var symbol: String
    var name: String
    var shares: Double
    var averageCost: Double
    var currentPrice: Double
    var assetClass: String      // Stock / ETF / Crypto / Bond / Cash
    var targetWeight: Double    // percent of portfolio
    var lastUpdated: Date

    init(id: UUID = UUID(), symbol: String, name: String = "", shares: Double = 0,
         averageCost: Double = 0, currentPrice: Double = 0,
         assetClass: String = "Stock", targetWeight: Double = 0,
         lastUpdated: Date = Date()) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.averageCost = averageCost
        self.currentPrice = currentPrice
        self.assetClass = assetClass
        self.targetWeight = targetWeight
        self.lastUpdated = lastUpdated
    }

    var marketValue: Double { shares * currentPrice }
    var costBasis: Double { shares * averageCost }
    var gainLoss: Double { marketValue - costBasis }
    var gainLossPercent: Double { costBasis > 0 ? gainLoss / costBasis * 100 : 0 }
}

struct AllocationSlice: Identifiable, Hashable {
    var id: String { label }
    var label: String
    var value: Double
    var colorKey: String
}

struct RebalanceAction: Identifiable, Hashable {
    var id: String { symbol }
    var symbol: String
    var currentPercent: Double
    var targetPercent: Double
    var drift: Double
    var dollarAction: Double  // positive = buy, negative = sell
    var recommendation: String
}

// MARK: - Subscription Intelligence

struct DetectedSubscription: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var averageAmount: Double
    var occurrences: Int
    var lastCharge: Date
    var estimatedMonthly: Double
    var priceHikePercent: Double
    var candidateCategory: CategoryType
}

struct SpendingAnomaly: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var amount: Double
    var average: Double
    var deviationPercent: Double
    var date: Date
    var category: CategoryType
    var message: String
}

// MARK: - Weekly Quests & Streak Shields

struct WeeklyQuest: Codable, Identifiable, Hashable {
    enum QuestKind: String, Codable, CaseIterable {
        case save = "Save"
        case noSpend = "No-spend"
        case logSpending = "Log spending"
        case feedPiggy = "Feed piggy"
        case reviewBudget = "Review budget"
        case learn = "Learn"
    }

    var id: UUID
    var title: String
    var detail: String
    var icon: String
    var target: Double
    var progress: Double
    var xp: Int
    var isComplete: Bool
    var weekStart: Date
    var kind: QuestKind

    init(id: UUID = UUID(), title: String, detail: String, icon: String = "star.fill",
         target: Double = 1, progress: Double = 0, xp: Int = 50,
         isComplete: Bool = false, weekStart: Date = Date(), kind: QuestKind = .save) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
        self.target = target
        self.progress = progress
        self.xp = xp
        self.isComplete = isComplete
        self.weekStart = weekStart
        self.kind = kind
    }

    var fraction: Double { target > 0 ? min(progress / target, 1) : 0 }
}

struct StreakShield: Codable, Identifiable, Hashable {
    var id: UUID
    var earnedDate: Date
    var usedDate: Date?
    var source: String

    init(id: UUID = UUID(), earnedDate: Date = Date(), usedDate: Date? = nil, source: String = "Milestone") {
        self.id = id
        self.earnedDate = earnedDate
        self.usedDate = usedDate
        self.source = source
    }

    var isUsed: Bool { usedDate != nil }
}

// MARK: - Account ability Buddies (local, no cloud)

struct AccountabilityBuddy: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var emoji: String
    var streak: Int
    var weeklySaved: Double
    var isMe: Bool

    init(id: UUID = UUID(), name: String, emoji: String = "🙂", streak: Int = 0,
         weeklySaved: Double = 0, isMe: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.streak = streak
        self.weeklySaved = weeklySaved
        self.isMe = isMe
    }
}

struct BuddyChallenge: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var buddyName: String
    var target: Double
    var myProgress: Double
    var buddyProgress: Double
    var endsOn: Date
    var isActive: Bool
    var reward: String

    init(id: UUID = UUID(), title: String, buddyName: String, target: Double = 100,
         myProgress: Double = 0, buddyProgress: Double = 0,
         endsOn: Date = Date().addingTimeInterval(86400 * 7), isActive: Bool = true,
         reward: String = "Bragging rights") {
        self.id = id
        self.title = title
        self.buddyName = buddyName
        self.target = target
        self.myProgress = myProgress
        self.buddyProgress = buddyProgress
        self.endsOn = endsOn
        self.isActive = isActive
        self.reward = reward
    }

    var myFraction: Double { target > 0 ? min(myProgress / target, 1) : 0 }
    var buddyFraction: Double { target > 0 ? min(buddyProgress / target, 1) : 0 }
}
