import Foundation

// MARK: - Credit Score

struct CreditScoreRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var score: Int              // 300...850
    var bureau: String
    var factors: [String]

    init(id: UUID = UUID(), date: Date = Date(), score: Int = 700,
         bureau: String = "Equifax", factors: [String] = []) {
        self.id = id
        self.date = date
        self.score = score
        self.bureau = bureau
        self.factors = factors
    }

    var band: String {
        switch score {
        case ..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Excellent"
        }
    }

    var bandColor: String {
        switch score {
        case ..<580: return "red"
        case 580..<670: return "orange"
        case 670..<740: return "gold"
        case 740..<800: return "green"
        default: return "teal"
        }
    }

    var normalized: Double { Double(max(0, min(score - 300, 550))) / 550.0 }
}

// MARK: - Tax Profile

struct TaxProfile: Codable, Hashable {
    var filingStatus: FilingStatus
    var taxYear: Int
    var grossIncome: Double
    var preTaxDeductions: Double
    var stateTaxRate: Double     // percent
    var dependents: Int

    enum FilingStatus: String, Codable, CaseIterable {
        case single = "Single"
        case marriedJoint = "Married Filing Jointly"
        case marriedSeparate = "Married Filing Separately"
        case headOfHousehold = "Head of Household"
        var localized: String { rawValue }
    }

    init(filingStatus: FilingStatus = .single, taxYear: Int = 2026,
         grossIncome: Double = 60000, preTaxDeductions: Double = 0,
         stateTaxRate: Double = 5, dependents: Int = 0) {
        self.filingStatus = filingStatus
        self.taxYear = taxYear
        self.grossIncome = grossIncome
        self.preTaxDeductions = preTaxDeductions
        self.stateTaxRate = stateTaxRate
        self.dependents = dependents
    }
}

// MARK: - Watchlist & Price Alerts

struct WatchlistItem: Codable, Identifiable, Hashable {
    let id: UUID
    var symbol: String
    var name: String
    var price: Double
    var changePercent: Double
    var targetPrice: Double?
    var alertAbove: Bool
    var notes: String

    init(id: UUID = UUID(), symbol: String, name: String = "", price: Double = 0,
         changePercent: Double = 0, targetPrice: Double? = nil, alertAbove: Bool = true,
         notes: String = "") {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.price = price
        self.changePercent = changePercent
        self.targetPrice = targetPrice
        self.alertAbove = alertAbove
        self.notes = notes
    }

    var isAlertTriggered: Bool {
        guard let targetPrice else { return false }
        return alertAbove ? price >= targetPrice : price <= targetPrice
    }
}

// MARK: - Recurring Transactions

struct RecurringTransaction: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var category: CategoryType
    var frequency: BillFrequency
    var nextDate: Date
    var isActive: Bool
    var autoRecord: Bool
    var notes: String

    init(id: UUID = UUID(), title: String, amount: Double, category: CategoryType = .needsVariable,
         frequency: BillFrequency = .monthly, nextDate: Date = Date(), isActive: Bool = true,
         autoRecord: Bool = false, notes: String = "") {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.frequency = frequency
        self.nextDate = nextDate
        self.isActive = isActive
        self.autoRecord = autoRecord
        self.notes = notes
    }
}

// MARK: - Savings Challenges

struct SavingsChallenge: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var targetAmount: Double
    var savedAmount: Double
    var type: ChallengeType
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var daysCompleted: Int

    enum ChallengeType: String, Codable, CaseIterable {
        case fiftyTwoWeek = "52-Week"
        case noSpend = "No-Spend"
        case roundUp = "Round-Up"
        case weekly = "Weekly"
        case custom = "Custom"
        var localized: String { rawValue }
    }

    init(id: UUID = UUID(), title: String, description: String = "", targetAmount: Double = 1000,
         savedAmount: Double = 0, type: ChallengeType = .custom, startDate: Date = Date(),
         endDate: Date = Date().addingTimeInterval(86400 * 52), isActive: Bool = true,
         daysCompleted: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.daysCompleted = daysCompleted
    }

    var progress: Double { targetAmount > 0 ? min(savedAmount / targetAmount, 1) : 0 }
    var remaining: Double { max(targetAmount - savedAmount, 0) }
    var isComplete: Bool { savedAmount >= targetAmount }
}

// MARK: - Financial Events

struct FinancialEvent: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var amount: Double
    var type: EventType
    var notes: String

    enum EventType: String, Codable, CaseIterable {
        case bill = "Bill"
        case income = "Income"
        case goal = "Goal Deadline"
        case subscription = "Subscription"
        case reminder = "Reminder"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .bill: return "doc.fill"
            case .income: return "arrow.down.circle.fill"
            case .goal: return "target"
            case .subscription: return "eyes"
            case .reminder: return "bell.fill"
            case .custom: return "star.fill"
            }
        }

        var color: String {
            switch self {
            case .bill: return "red"
            case .income: return "green"
            case .goal: return "blue"
            case .subscription: return "purple"
            case .reminder: return "orange"
            case .custom: return "teal"
            }
        }
    }

    init(id: UUID = UUID(), title: String, date: Date = Date(), amount: Double = 0,
         type: EventType = .custom, notes: String = "") {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.type = type
        self.notes = notes
    }
}

// MARK: - Net Worth Snapshots

struct NetWorthSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var assets: Double
    var liabilities: Double

    init(id: UUID = UUID(), date: Date = Date(), assets: Double = 0, liabilities: Double = 0) {
        self.id = id
        self.date = date
        self.assets = assets
        self.liabilities = liabilities
    }

    var netWorth: Double { assets - liabilities }
}

// MARK: - Reminders

struct Reminder: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var isEnabled: Bool
    var repeatRule: RepeatRule

    enum RepeatRule: String, Codable, CaseIterable {
        case none = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        var localized: String { rawValue }
    }

    init(id: UUID = UUID(), title: String, date: Date = Date(), isEnabled: Bool = true,
         repeatRule: RepeatRule = .none) {
        self.id = id
        self.title = title
        self.date = date
        self.isEnabled = isEnabled
        self.repeatRule = repeatRule
    }
}

// MARK: - App Theme Settings

struct AppThemeSettings: Codable, Hashable {
    var accent: String
    var useGradients: Bool
    var showConfetti: Bool
    var hapticsEnabled: Bool
    var currency: String

    init(accent: String = "blue", useGradients: Bool = true, showConfetti: Bool = true,
         hapticsEnabled: Bool = true, currency: String = "USD") {
        self.accent = accent
        self.useGradients = useGradients
        self.showConfetti = showConfetti
        self.hapticsEnabled = hapticsEnabled
        self.currency = currency
    }
}

// MARK: - Round-Up Settings

struct RoundUpSettings: Codable, Hashable {
    var isEnabled: Bool
    var roundTo: Double          // e.g. 1.00, 5.00
    var piggyId: UUID?

    init(isEnabled: Bool = false, roundTo: Double = 1.0, piggyId: UUID? = nil) {
        self.isEnabled = isEnabled
        self.roundTo = roundTo
        self.piggyId = piggyId
    }
}
