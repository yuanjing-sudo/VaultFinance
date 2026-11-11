import SwiftUI

// MARK: - Financial Indicators

/// Surface extra indicators beyond the core dashboard: debt-to-income, savings rate,
/// emergency-fund coverage, net cash flow, budget utilization, and goal projections.
struct FinancialIndicatorsView: View {
    @EnvironmentObject var storage: LocalStorage

    var indicators: [FinancialIndicator] {
        let profile = storage.profile
        let categories = storage.categories
        let liabilities = storage.liabilities
        let goals = storage.goals

        var items: [FinancialIndicator] = []

        // Debt-to-income
        let dti = FinanceEngine.debtToIncome(profile: profile, liabilities: liabilities)
        items.append(FinancialIndicator(
            title: "Debt-to-Income",
            value: String(format: "%.1f%%", dti),
            subtitle: "Monthly debt payments ÷ income",
            icon: "creditcard.fill",
            color: dti > 36 ? .red : (dti > 20 ? .orange : .green),
            isGood: dti <= 36
        ))

        // Savings rate
        let savingsRate = FinanceEngine.savingsRate(profile: profile, categories: categories)
        items.append(FinancialIndicator(
            title: "Savings Rate",
            value: String(format: "%.1f%%", savingsRate),
            subtitle: "Target: \(String(format: "%.0f%%", profile.savingsTargetPercent)) of income",
            icon: "banknote.fill",
            color: .green,
            isGood: savingsRate >= profile.savingsTargetPercent
        ))

        // Emergency fund months
        let months = FinanceEngine.emergencyFundMonths(profile: profile, categories: categories)
        items.append(FinancialIndicator(
            title: "Emergency Fund",
            value: String(format: "%.1f mo", months),
            subtitle: "Months of expenses covered",
            icon: "umbrella.fill",
            color: months >= 6 ? .green : (months >= 3 ? .orange : .red),
            isGood: months >= 6
        ))

        // Net cash flow
        let cashFlow = FinanceEngine.netCashFlow(profile: profile, categories: categories)
        items.append(FinancialIndicator(
            title: "Net Cash Flow",
            value: Money(amount: cashFlow).formatted(),
            subtitle: "Income − budgeted per month",
            icon: "arrow.left.arrow.right.circle.fill",
            color: cashFlow >= 0 ? .green : .red,
            isGood: cashFlow >= 0
        ))

        // Budget utilization
        let util = FinanceEngine.budgetUtilization(categories: categories)
        items.append(FinancialIndicator(
            title: "Budget Utilization",
            value: String(format: "%.0f%%", util),
            subtitle: "Spent ÷ budgeted",
            icon: "gauge",
            color: util > 90 ? .red : (util > 70 ? .orange : .green),
            isGood: util <= 70
        ))

        // Goal progress (aggregate)
        let avgProgress = goals.isEmpty ? 0 : goals.reduce(0) { $0 + $1.percentComplete } / Double(goals.count)
        items.append(FinancialIndicator(
            title: "Goal Progress",
            value: String(format: "%.0f%%", avgProgress),
            subtitle: "Average across \(goals.count) active goals",
            icon: "target",
            color: avgProgress >= 75 ? .green : (avgProgress >= 40 ? .orange : .red),
            isGood: avgProgress >= 75
        ))

        return items
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Financial Indicators")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 14) {
                    ForEach(indicators) { indicator in
                        IndicatorCard(indicator: indicator)
                    }
                }

                // Goal countdowns
                if !storage.goals.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Goal Countdowns").font(.headline).bold()
                        ForEach(storage.goals) { goal in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(goal.title).font(.subheadline).bold()
                                    Spacer()
                                    Text("\(goal.percentComplete, specifier: "%.0f")%")
                                        .font(.caption).bold().foregroundColor(.blue)
                                }
                                if let monthly = storage.profile.totalMonthlyIncome > 0 ? storage.profile.totalMonthlyIncome * 0.2 : 0, monthly > 0 {
                                    let days = FinanceEngine.daysToGoal(goal: goal, monthlyContribution: monthly)
                                    Text("Est. \(days) days to reach at \(Money(amount: monthly).formatted())/month")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Rectangle().fill(Color(.systemGray4)).frame(height: 6).cornerRadius(3)
                                        Rectangle().fill(goal.percentComplete >= 100 ? Color.green : Color.blue)
                                            .frame(width: min(geo.size.width * (goal.percentComplete / 100), geo.size.width), height: 6)
                                            .cornerRadius(3)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .navigationTitle("Indicators")
    }
}

// MARK: - Indicator Card

struct IndicatorCard: View {
    let indicator: FinancialIndicator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: indicator.icon)
                    .font(.title3)
                    .foregroundColor(indicator.color)
                Spacer()
                Image(systemName: indicator.isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(indicator.isGood ? .green : .red)
            }
            Text(indicator.value).font(.title2).bold()
            Text(indicator.title).font(.subheadline).bold()
            Text(indicator.subtitle).font(.caption2).foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(indicator.color.opacity(0.25), lineWidth: 1)
        )
    }
}
