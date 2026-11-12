import Foundation

// MARK: - Tax Document Vault

enum TaxDocumentKind: String, Codable, CaseIterable, Identifiable {
    case w2 = "W-2"
    case form1099 = "1099"
    case form1098 = "1098"
    case receipt = "Receipt"
    case deduction = "Deduction"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .w2: return "doc.text.fill"
        case .form1099: return "doc.plaintext.fill"
        case .form1098: return "house.fill"
        case .receipt: return "receipt.fill"
        case .deduction: return "minus.circle.fill"
        case .other: return "folder.fill"
        }
    }

    var tint: String {
        switch self {
        case .w2: return "blue"
        case .form1099: return "green"
        case .form1098: return "orange"
        case .receipt: return "purple"
        case .deduction: return "teal"
        case .other: return "pink"
        }
    }
}

struct TaxDocument: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var kind: TaxDocumentKind
    var taxYear: Int
    var amount: Double
    var addedDate: Date
    var dueDate: Date?
    var isFiled: Bool
    var notes: String

    init(id: UUID = UUID(), title: String, kind: TaxDocumentKind = .other,
         taxYear: Int = Calendar.current.component(.year, from: Date()),
         amount: Double = 0, addedDate: Date = Date(), dueDate: Date? = nil,
         isFiled: Bool = false, notes: String = "") {
        self.id = id
        self.title = title
        self.kind = kind
        self.taxYear = taxYear
        self.amount = amount
        self.addedDate = addedDate
        self.dueDate = dueDate
        self.isFiled = isFiled
        self.notes = notes
    }
}

struct TaxDeadline: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var date: Date
    var detail: String
    var icon: String
}

// MARK: - Subscription Review

enum SubscriptionVerdict: String, Codable, CaseIterable, Identifiable {
    case keep = "Keep"
    case review = "Review"
    case cancel = "Cancel"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .keep: return "checkmark.circle.fill"
        case .review: return "questionmark.circle.fill"
        case .cancel: return "xmark.circle.fill"
        }
    }

    var tint: String {
        switch self {
        case .keep: return "green"
        case .review: return "orange"
        case .cancel: return "red"
        }
    }
}

struct SubscriptionReview: Codable, Identifiable, Hashable {
    var id: UUID
    var subscriptionTitle: String
    var monthlyCost: Double
    var verdict: SubscriptionVerdict
    var lastReviewed: Date
    var note: String
    var priceHikeDetected: Bool

    init(id: UUID = UUID(), subscriptionTitle: String, monthlyCost: Double = 0,
         verdict: SubscriptionVerdict = .review, lastReviewed: Date = Date(),
         note: String = "", priceHikeDetected: Bool = false) {
        self.id = id
        self.subscriptionTitle = subscriptionTitle
        self.monthlyCost = monthlyCost
        self.verdict = verdict
        self.lastReviewed = lastReviewed
        self.note = note
        self.priceHikeDetected = priceHikeDetected
    }

    var annualCost: Double { monthlyCost * 12 }
}

// MARK: - Bill Negotiation

struct NegotiationOpportunity: Identifiable, Hashable {
    var id: UUID { billId }
    var billId: UUID
    var title: String
    var currentMonthly: Double
    var targetMonthly: Double
    var estimatedAnnualSavings: Double
    var script: String
    var priority: Int
}

// MARK: - Personalized Plan (onboarding quiz)

struct PlanCategory: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var type: CategoryType
    var percent: Double
    var amount: Double

    init(id: UUID = UUID(), name: String, type: CategoryType, percent: Double, amount: Double) {
        self.id = id
        self.name = name
        self.type = type
        self.percent = percent
        self.amount = amount
    }
}

struct PersonalizedPlan: Codable, Hashable {
    var recommendedEmergencyFund: Double
    var recommendedSavingsRate: Double
    var recommendedInvestingPercent: Double
    var suggestedBudget: [PlanCategory]
    var riskProfile: String
    var steps: [String]
    var createdAt: Date

    init(recommendedEmergencyFund: Double = 0, recommendedSavingsRate: Double = 20,
         recommendedInvestingPercent: Double = 10, suggestedBudget: [PlanCategory] = [],
         riskProfile: String = "Balanced", steps: [String] = [], createdAt: Date = Date()) {
        self.recommendedEmergencyFund = recommendedEmergencyFund
        self.recommendedSavingsRate = recommendedSavingsRate
        self.recommendedInvestingPercent = recommendedInvestingPercent
        self.suggestedBudget = suggestedBudget
        self.riskProfile = riskProfile
        self.steps = steps
        self.createdAt = createdAt
    }
}

// MARK: - Multi-currency

struct CurrencyRate: Identifiable, Hashable {
    var id: String { code }
    var code: String
    var name: String
    var perUSD: Double
    var symbol: String
}

// MARK: - Statement / CSV Import

struct ImportedTransaction: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var title: String
    var amount: Double
    var category: CategoryType
    var isDuplicate: Bool
}

// MARK: - Financial Health Timeline Point

struct HealthTimelinePoint: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var score: Int
    var label: String
}

// MARK: - Piggy Skins & Seasons

struct PiggySkin: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var hex: String
    var personality: PiggyPersonality
    var unlockHint: String
    var requiredDeposits: Int
}

enum PiggySeason: String, CaseIterable, Identifiable {
    case spring = "Spring Bloom"
    case summer = "Summer Splash"
    case autumn = "Autumn Harvest"
    case winter = "Winter Glow"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }

    var tint: String {
        switch self {
        case .spring: return "#10B981"
        case .summer: return "#F59E0B"
        case .autumn: return "#EA580C"
        case .winter: return "#38BDF8"
        }
    }
}

// MARK: - Challenge templates

struct LabChallengeTemplate: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var detail: String
    var icon: String
    var target: Double
    var days: Int
    var rewardXP: Int
    var tint: String
}
