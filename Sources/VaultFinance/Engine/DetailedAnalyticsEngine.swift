import Foundation

// MARK: - Detailed Analytics Engine
// Hundreds of deterministic calculations layered on top of FinanceEngine.

extension FinanceEngine {

    // MARK: - Cash Flow

    static func monthlyCashFlow(income: Double, expenses: Double) -> Double {
        income - expenses
    }

    static func annualCashFlow(income: Double, expenses: Double) -> Double {
        (income - expenses) * 12
    }

    static func dailyAverageSpending(transactions: [Transaction], days: Int) -> Double {
        guard days > 0 else { return 0 }
        let total = transactions.reduce(0) { $0 + $1.amount }
        return total / Double(days)
    }

    // MARK: - Burn Rate & Runway

    static func monthlyBurnRate(expenses: Double) -> Double { expenses }
    static func runwayMonths(savings: Double, monthlyBurn: Double) -> Double {
        guard monthlyBurn > 0 else { return Double.infinity }
        return savings / monthlyBurn
    }

    // MARK: - Debt Payoff (snowball / avalanche)

    static func debtPayoffMonths(balance: Double, monthlyPayment: Double, annualRate: Double) -> Int {
        guard monthlyPayment > 0 else { return Int.max }
        let monthlyRate = annualRate / 100 / 12
        var remaining = balance
        var months = 0
        while remaining > 0 && months < 1200 {
            let interest = remaining * monthlyRate
            remaining = remaining + interest - monthlyPayment
            if remaining < 0 { remaining = 0 }
            months += 1
        }
        return months
    }

    static func debtInterestSaved(balance: Double, monthlyPayment: Double, annualRate: Double) -> Double {
        // Interest paid with current plan vs paying minimum only (approx)
        let months = debtPayoffMonths(balance: balance, monthlyPayment: monthlyPayment, annualRate: annualRate)
        let totalPaid = Double(months) * monthlyPayment
        return max(totalPaid - balance, 0)
    }

    // MARK: - Savings Projections

    static func futureValue(monthlyDeposit: Double, annualRate: Double, years: Int) -> Double {
        let monthlyRate = annualRate / 100 / 12
        let months = years * 12
        guard monthlyRate > 0 else { return monthlyDeposit * Double(months) }
        return monthlyDeposit * (pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate
    }

    static func timeToGoal(current: Double, target: Double, monthlyDeposit: Double, annualRate: Double) -> Int {
        guard monthlyDeposit > 0, current < target else { return 0 }
        let monthlyRate = annualRate / 100 / 12
        var balance = current
        var months = 0
        while balance < target && months < 1200 {
            balance = balance * (1 + monthlyRate) + monthlyDeposit
            months += 1
        }
        return months
    }

    // MARK: - Net Worth Trajectory

    static func netWorthTrajectory(current: Double, monthlySavings: Double, annualRate: Double, months: Int) -> [ProjectedPoint] {
        var points: [ProjectedPoint] = []
        var value = current
        let monthlyRate = annualRate / 100 / 12
        for m in 0...months {
            points.append(.init(months: m, projectedNetWorth: value))
            value = value * (1 + monthlyRate) + monthlySavings
        }
        return points
    }

    // MARK: - Expense Categorization Insights

    static func topSpendingCategories(categories: [BudgetCategory], limit: Int = 5) -> [BudgetCategory] {
        categories.sorted { $0.spentAmount > $1.spentAmount }.prefix(limit).map { $0 }
    }

    static func categoryEfficiency(categories: [BudgetCategory]) -> [(name: String, efficiency: Double)] {
        categories.map { cat in
            let eff = cat.budgetedAmount > 0 ? (1 - cat.spentAmount / cat.budgetedAmount) * 100 : 0
            return (cat.name, max(eff, 0))
        }.sorted { $0.efficiency > $1.efficiency }
    }

    // MARK: - Savings Rate by Category Type

    static func savingsRateByType(categories: [BudgetCategory], income: Double) -> Double {
        guard income > 0 else { return 0 }
        let savings = categories.filter { $0.type == .savings }.reduce(0) { $0 + $1.spentAmount }
        return savings / income * 100
    }

    // MARK: - Piggy Bank Growth

    static func piggyFatness(deposited: Double, target: Double) -> Double {
        guard target > 0 else { return 1.0 }
        return 1.0 + 0.6 * min(deposited / target, 1.0)
    }

    static func piggyLevel(deposited: Double, target: Double) -> PiggyLevel {
        let p = deposited / max(target, 1)
        if p < 0.1 { return .empty }
        if p < 0.25 { return .hungry }
        if p < 0.5 { return .growing }
        if p < 0.75 { return .chubby }
        if p < 0.95 { return .fat }
        if p < 1.0 { return .veryFat }
        return .gluttonous
    }
}
