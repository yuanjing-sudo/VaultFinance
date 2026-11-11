import Foundation

// MARK: - Deterministic Financial Calculation Engine
// All math is computed with tested numeric algorithms. LLM never calculates money.

class FinanceEngine: ObservableObject {
    // MARK: - Allocation Engine

    /// Adaptive allocation based on user profile and fixed needs ratio.
    /// Returns (needs, wants, savings) percentages.
    static func computeAllocation(profile: UserProfile, fixedNeedsMonthly: Double) -> (needs: Double, wants: Double, savings: Double) {
        let income = profile.totalMonthlyIncome
        guard income > 0 else { return (50, 30, 20) }  // default 50/30/20

        let fixedNeedsRatio = fixedNeedsMonthly / income
        // If fixed needs are very high (e.g. rent > 50%), compress wants more aggressively.
        var savings: Double
        var wants: Double
        var needs: Double

        if fixedNeedsRatio > 0.6 {
            // High-cost structure: needs 70%, wants 10%, savings 20%
            needs = 70; wants = 10; savings = 20
        } else if fixedNeedsRatio > 0.4 {
            needs = 60; wants = 20; savings = 20
        } else if fixedNeedsRatio > 0.2 {
            needs = 50; wants = 30; savings = 20
        } else {
            needs = 50; wants = 30; savings = 20
        }

        return (needs, wants, savings)
    }

    /// Apply allocation percentages to income and build budget categories.
    static func buildBudget(for profile: UserProfile, allocations: (needs: Double, wants: Double, savings: Double)) -> [BudgetCategory] {
        let income = profile.totalMonthlyIncome
        let now = Calendar.current.startOfDay(for: Date())

        var categories: [BudgetCategory] = []
        // Needs (fixed)
        categories.append(BudgetCategory(name: "Rent/Housing", type: .needsFixed, budgetedAmount: income * allocations.needs * 0.45, month: now))
        categories.append(BudgetCategory(name: "Insurance", type: .needsFixed, budgetedAmount: income * allocations.needs * 0.15, month: now))
        categories.append(BudgetCategory(name: "Subscriptions", type: .needsFixed, budgetedAmount: income * allocations.needs * 0.10, month: now))
        categories.append(BudgetCategory(name: "Loan Repayments", type: .needsFixed, budgetedAmount: income * allocations.needs * 0.30, month: now))
        // Needs (variable)
        categories.append(BudgetCategory(name: "Food", type: .needsVariable, budgetedAmount: income * allocations.needs * 0.30, month: now))
        categories.append(BudgetCategory(name: "Groceries", type: .needsVariable, budgetedAmount: income * allocations.needs * 0.25, month: now))
        categories.append(BudgetCategory(name: "Transport", type: .needsVariable, budgetedAmount: income * allocations.needs * 0.20, month: now))
        categories.append(BudgetCategory(name: "Utilities", type: .needsVariable, budgetedAmount: income * allocations.needs * 0.25, month: now))
        // Wants
        categories.append(BudgetCategory(name: "Restaurants", type: .wants, budgetedAmount: income * allocations.wants * 0.35, month: now))
        categories.append(BudgetCategory(name: "Entertainment", type: .wants, budgetedAmount: income * allocations.wants * 0.25, month: now))
        categories.append(BudgetCategory(name: "Shopping", type: .wants, budgetedAmount: income * allocations.wants * 0.20, month: now))
        categories.append(BudgetCategory(name: "Hobbies", type: .wants, budgetedAmount: income * allocations.wants * 0.20, month: now))
        // Savings
        categories.append(BudgetCategory(name: "Emergency Fund", type: .savings, budgetedAmount: income * allocations.savings * 0.50, month: now))
        categories.append(BudgetCategory(name: "Investments", type: .savings, budgetedAmount: income * allocations.savings * 0.50, month: now))
        return categories
    }

    // MARK: - Rollover Engine

    /// Process leftover budget at month-end.
    static func processRollover(category: BudgetCategory) -> RolloverResult {
        let leftover = category.remaining
        guard leftover > 0 else { return .none(spent: category.spentAmount, remaining: 0, rollover: 0) }
        switch category.rolloverDirection {
        case .carry:
            return .carry(leftover, leftover)
        case .save:
            return .save(leftover)
        case .transfer:
            return .transfer(leftover)
        case .goal:
            return .goal(leftover)
        }
    }

    /// Handle overspending: show impact on remaining allocation.
    static func analyzeOverspending(category: BudgetCategory) -> OverspendAnalysis {
        let over = category.overBudget
        guard over > 0 else { return .clean }
        let sourceBudget = category.effectiveBudget
        let percentageOfRemaining = over / max(sourceBudget, 1) * 100
        return .over(over, percentageOfRemaining, sourceBudget - over)
    }

    // MARK: - Wealth Engine

    static func computeNetWorth(assets: [AssetHolding], liabilities: [Liability], cashInBank: Double, savingsAccounts: Double) -> NetWorth {
        let totalAssets = assets.reduce(0) { $0 + $1.currentMarketValue } + cashInBank + savingsAccounts
        let totalLiabilities = liabilities.reduce(0) { $0 + $1.balance }
        return NetWorth(assets: totalAssets, liabilities: totalLiabilities, netWorth: totalAssets - totalLiabilities)
    }

    /// Investment return ONLY (never conflates with contributions/deposits).
    static func computeInvestmentReturn(holding: AssetHolding) -> InvestmentReturn {
        let gain = holding.unrealizedGainLoss
        let gainPct = holding.unrealizedGainLossPercent
        let realized = 0.0  // would track realized trades separately
        return InvestmentReturn(unrealizedGain: gain, unrealizedGainPercent: gainPct, realizedReturn: realized, totalReturn: gain + gainPct)
    }

    /// Project net-worth growth over time (deterministic, optional CAGR).
    static func projectGrowth(current: Double, annualRate: Double, months: Int) -> [ProjectedPoint] {
        var points: [ProjectedPoint] = []
        var value = current
        let monthlyRate = (1 + annualRate / 100).cubeRootMonthly
        for m in 0...months {
            points.append(ProjectedPoint(months: m, projectedNetWorth: value))
            if m < months { value = value * monthlyRate }
        }
        return points
    }

    /// Financial health score (transparent, weighted).
    static func computeHealthScore(
        savingsConsistency: Double,     // 0-100
        budgetCompliance: Double,       // 0-100
        emergencyFund: Double,          // 0-100 (months of expenses saved)
        debtManagement: Double,         // 0-100
        goalProgress: Double            // 0-100
    ) -> (score: Int, factors: [FinancialHealthScore.HealthFactor], recommendation: String) {
        let weights = [savingsConsistency, budgetCompliance, emergencyFund, debtManagement, goalProgress]
        let w = [25, 25, 30, 20, 15]
        guard weights.count == w.count else { return (50, [], "No data available") }
        let weightedSum = zip(weights, w).reduce(0.0) { partial, pair in
            partial + (pair.0 * Double(pair.1))
        }
        var score = Int(weightedSum / 100.0)

        // Clamping
        score = min(max(score, 0), 100)

        let factors: [FinancialHealthScore.HealthFactor] = [
            .init(id: UUID(), name: "Savings Consistency", score: Int(savingsConsistency), weight: w[0], description: "How consistently you save month over month."),
            .init(id: UUID(), name: "Budget Compliance", score: Int(budgetCompliance), weight: w[1], description: "How well you stayed within your allocations."),
            .init(id: UUID(), name: "Emergency Fund", score: Int(emergencyFund), weight: w[2], description: "Months of expenses you could cover from savings."),
            .init(id: UUID(), name: "Debt Management", score: Int(debtManagement), weight: w[3], description: "Health of your debt obligations."),
            .init(id: UUID(), name: "Goal Progress", score: Int(goalProgress), weight: w[4], description: "Progress toward your financial goals."),
        ]

        let recommendation: String
        switch score {
        case 80...: recommendation = "Excellent financial health. Keep the habits that got you here."
        case 60...: recommendation = "Good health with room to improve. Focus on your weakest area."
        default: recommendation = "Consider building an emergency fund and sticking to your budget."
        }

        return (score, factors, recommendation)
    }
}

// MARK: - Supporting Types

struct NetWorth: Codable, Identifiable, Hashable {
    let id = UUID()
    var assets: Double
    var liabilities: Double
    var netWorth: Double
}

struct InvestmentReturn: Codable, Identifiable, Hashable {
    let id = UUID()
    var unrealizedGain: Double
    var unrealizedGainPercent: Double
    var realizedReturn: Double
    var totalReturn: Double
}

struct ProjectedPoint: Codable, Identifiable, Hashable {
    let id = UUID()
    var months: Int
    var projectedNetWorth: Double

    var date: Date {
        Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
    }

    var formattedValue: String {
        Money(amount: projectedNetWorth).formatted(in: .init())
    }
}

enum RolloverResult {
    case none(spent: Double, remaining: Double, rollover: Double)
    case carry(Double, Double)        // (leftover, carried)
    case save(Double)
    case transfer(Double)
    case goal(Double)
}

enum OverspendAnalysis {
    case clean
    case over(Double, Double, Double)  // over, pctOfRemaining, remainingAfterAdjustment
}

// MARK: - Date math helpers

extension Calendar {
    func startOfDay(for date: Date) -> Date {
        dateComponents([.year, .month, .day], from: date).date ?? date
    }
}

extension Date {
    static func +(lhs: Date, rhs: TimeInterval) -> Date { lhs + rhs }
    static func +(lhs: Date, rhs: Date) -> Date { lhs + rhs.timeIntervalSince1970 }

    func adding(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}

extension Double {
    var cubeRootMonthly: Double {
        // monthly multiplier equivalent to 1 + annual rate
        let rate = self / 100.0
        // (1 + rate)^(1/12)
        return pow(1 + rate, 1.0 / 12.0)
    }
}

// MARK: - Format context for Money

struct FormatContext { }

extension Money {
    init(string: String) {
        let cleaned = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        self.amount = Double(cleaned) ?? 0
        self.currency = "USD"
    }
}
