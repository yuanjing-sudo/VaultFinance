import Foundation

// MARK: - Additional Financial Indicators

// All calculations are deterministic and live in this engine layer (LLM never calculates money).
extension FinanceEngine {

    /// Debt-to-income ratio: monthly debt payments / monthly income.
    static func debtToIncome(profile: UserProfile, liabilities: [Liability]) -> Double {
        let income = profile.totalMonthlyIncome
        guard income > 0 else { return 0 }
        let monthlyDebt = liabilities.reduce(0) { $0 + $1.monthlyPayment }
        return monthlyDebt / income * 100
    }

    /// Savings rate: monthly savings / monthly income.
    static func savingsRate(profile: UserProfile, categories: [BudgetCategory]) -> Double {
        let income = profile.totalMonthlyIncome
        guard income > 0 else { return 0 }
        let savings = categories
            .filter { $0.type == .savings }
            .reduce(0) { $0 + $1.budgetedAmount }
        return savings / income * 100
    }

    /// Emergency fund coverage in months of expenses.
    static func emergencyFundMonths(profile: UserProfile, categories: [BudgetCategory]) -> Double {
        let monthlyExpenses = categories.reduce(0) { $0 + $1.budgetedAmount }
        guard monthlyExpenses > 0 else { return 0 }
        return profile.existingSavings / monthlyExpenses
    }

    /// Net cash flow: income - total budgeted.
    static func netCashFlow(profile: UserProfile, categories: [BudgetCategory]) -> Double {
        profile.totalMonthlyIncome - categories.reduce(0) { $0 + $1.budgetedAmount }
    }

    /// Utilization: total spent / total budgeted.
    static func budgetUtilization(categories: [BudgetCategory]) -> Double {
        let budgeted = categories.reduce(0) { $0 + $1.budgetedAmount }
        guard budgeted > 0 else { return 0 }
        return categories.reduce(0) { $0 + $1.spentAmount } / budgeted * 100
    }

    /// Days until a goal is reached at the current monthly contribution rate.
    static func daysToGoal(goal: FinancialGoal, monthlyContribution: Double) -> Int {
        guard monthlyContribution > 0, goal.currentAmount < goal.targetAmount else { return 0 }
        let remaining = goal.remaining
        return Int(ceil(remaining / monthlyContribution * 30))
    }
}

// MARK: - Indicator Display Model

struct FinancialIndicator: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var value: String
    var subtitle: String
    var icon: String
    var color: Color
    var isGood: Bool

    init(title: String, value: String, subtitle: String, icon: String, color: Color, isGood: Bool = true) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isGood = isGood
    }
}

import SwiftUI
