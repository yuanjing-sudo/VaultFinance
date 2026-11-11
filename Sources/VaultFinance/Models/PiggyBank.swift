import Foundation

// MARK: - Piggy Bank

/// A visual piggy bank that grows "fatter" (larger) as the user deposits more savings.
/// The piggy has multiple fullness levels based on deposited amount vs savings goal.
struct PiggyBank: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var targetAmount: Double        // savings goal for this piggy
    var depositedAmount: Double     // total deposited into this piggy
    var currency: String
    var isBroken: Bool              // if true, funds have been withdrawn
    var breakDate: Date?
    var lastDepositDate: Date?
    var depositCount: Int
    var personality: PiggyPersonality
    var colorTheme: String          // hex color for the piggy

    init(
        id: UUID = UUID(),
        name: String = "My Savings Piggy",
        targetAmount: Double = 1000.0,
        depositedAmount: Double = 0,
        currency: String = "USD",
        isBroken: Bool = false,
        breakDate: Date? = nil,
        lastDepositDate: Date? = nil,
        depositCount: Int = 0,
        personality: PiggyPersonality = .classic,
        colorTheme: String = "#F5A623"
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.depositedAmount = depositedAmount
        self.currency = currency
        self.isBroken = isBroken
        self.breakDate = breakDate
        self.lastDepositDate = lastDepositDate
        self.depositCount = depositCount
        self.personality = personality
        self.colorTheme = colorTheme
    }

    /// Progress from 0 to 1 toward the target.
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(depositedAmount / targetAmount, 1.0)
    }

    var percentFull: Double { progress * 100 }

    var remaining: Double { max(targetAmount - depositedAmount, 0) }

    var isFull: Bool { depositedAmount >= targetAmount }

    /// "Fatness" scale factor: 1.0 = skinny (empty), up to 1.6 = very fat (full).
    /// This drives the visual scale of the piggy in PiggyBankView.
    var fatnessScale: Double {
        let base: Double = 1.0
        let maxScale: Double = 1.6
        return base + (maxScale - base) * progress
    }

    var level: PiggyLevel {
        let p = progress
        if p < 0.1 { return .empty }
        if p < 0.25 { return .hungry }
        if p < 0.5 { return .growing }
        if p < 0.75 { return .chubby }
        if p < 0.95 { return .fat }
        if p < 1.0 { return .veryFat }
        return .gluttonous
    }

    var levelEmoji: String { level.emoji }
    var levelDescription: String { level.description }
    var levelColor: String { level.color }
}

enum PiggyPersonality: String, Codable, CaseIterable {
    case classic = "Classic"
    case glitter = "Glitter"
    case stealth = "Stealth"
    case rainbow = "Rainbow"
    case gold = "Gold"

    var icon: String {
        switch self {
        case .classic: return "pawprint.fill"
        case .glitter: return "sparkles.fill"
        case .stealth: return "eye.fill"
        case .rainbow: return "rainbow.fill"
        case .gold: return "crown.fill"
        }
    }
    var localized: String { rawValue }
}

enum PiggyLevel: String, Codable {
    case empty = "Empty"
    case hungry = "Hungry"
    case growing = "Growing"
    case chubby = "Chubby"
    case fat = "Fat"
    case veryFat = "Very Fat"
    case gluttonous = "Gluttonous"

    var emoji: String {
        switch self {
        case .empty: return "🐷"
        case .hungry: return "🐷💨"
        case .growing: return "🐽"
        case .chubby: return "🐖"
        case .fat: return "🐷🍩"
        case .veryFat: return "🐷🍰"
        case .gluttonous: return "🐷👑"
        }
    }
    var description: String {
        switch self {
        case .empty: return "Time to feed the piggy!"
        case .hungry: return "A little snack for the piggy."
        case .growing: return "The piggy is growing."
        case .chubby: return "Getting chubby — nice saving!"
        case .fat: return "The piggy is quite fat now."
        case .veryFat: return "Very fat piggy — almost full!"
        case .gluttonous: return "Gluttonous piggy! Goal reached!"
        }
    }
    var color: String {
        switch self {
        case .empty: return "#9CA3AF"
        case .hungry: return "#FBBF24"
        case .growing: return "#3B82F6"
        case .chubby: return "#10B981"
        case .fat: return "#8B5CF6"
        case .veryFat: return "#EC4899"
        case .gluttonous: return "#EF4444"
        }
    }
}

// MARK: - Deposit Record

struct PiggyDeposit: Codable, Identifiable, Hashable {
    let id: UUID
    var piggyId: UUID
    var amount: Double
    var date: Date
    var note: String
    var source: DepositSource

    enum DepositSource: String, Codable, CaseIterable {
        case manual = "Manual"
        case budgetRollover = "Budget Rollover"
        case goalTransfer = "Goal Transfer"
        case roundUp = "Round Up"
        case achievementReward = "Achievement Reward"
        var localized: String { rawValue }
    }

    init(id: UUID = UUID(), piggyId: UUID, amount: Double, date: Date = Date(),
         note: String = "", source: DepositSource = .manual) {
        self.id = id
        self.piggyId = piggyId
        self.amount = amount
        self.date = date
        self.note = note
        self.source = source
    }
}

// MARK: - Bill

enum BillFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    var localized: String { rawValue }
}

enum BillStatus: String, Codable, CaseIterable {
    case upcoming = "Upcoming"
    case paid = "Paid"
    case overdue = "Overdue"
    case partial = "Partial"
    var localized: String { rawValue }
    var color: String {
        switch self {
        case .upcoming: return "#3B82F6"
        case .paid: return "#10B981"
        case .overdue: return "#EF4444"
        case .partial: return "#F59E0B"
        }
    }
}

struct Bill: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var frequency: BillFrequency
    var nextDueDate: Date
    var status: BillStatus
    var category: String
    var notes: String
    var autoPay: Bool
    var lastPaidDate: Date?
    var paidAmount: Double

    init(id: UUID = UUID(), title: String, amount: Double, frequency: BillFrequency = .monthly,
         nextDueDate: Date = Date(), status: BillStatus = .upcoming, category: String = "Bills",
         notes: String = "", autoPay: Bool = false, lastPaidDate: Date? = nil, paidAmount: Double = 0) {
        self.id = id
        self.title = title
        self.amount = amount
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.status = status
        self.category = category
        self.notes = notes
        self.autoPay = autoPay
        self.lastPaidDate = lastPaidDate
        self.paidAmount = paidAmount
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
    }
    var isDueSoon: Bool { daysUntilDue <= 7 && daysUntilDue >= 0 }
    var isOverdue: Bool { status == .overdue }
}

// MARK: - Subscription

enum SubscriptionBillingCycle: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    var localized: String { rawValue }
}

struct Subscription: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var cycle: SubscriptionBillingCycle
    var nextBillingDate: Date
    var category: String
    var notes: String
    var isActive: Bool
    var trialEndDate: Date?
    var cancellationDate: Date?

    init(id: UUID = UUID(), title: String, amount: Double, cycle: SubscriptionBillingCycle = .monthly,
         nextBillingDate: Date = Date(), category: String = "Subscriptions",
         notes: String = "", isActive: Bool = true, trialEndDate: Date? = nil,
         cancellationDate: Date? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.cycle = cycle
        self.nextBillingDate = nextBillingDate
        self.category = category
        self.notes = notes
        self.isActive = isActive
        self.trialEndDate = trialEndDate
        self.cancellationDate = cancellationDate
    }

    var daysUntilBilling: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
    }
    var annualizedCost: Double {
        let multiplier: Double
        switch cycle {
        case .weekly: multiplier = 52
        case .monthly: multiplier = 12
        case .quarterly: multiplier = 4
        case .yearly: multiplier = 1
        }
        return amount * multiplier
    }
}
