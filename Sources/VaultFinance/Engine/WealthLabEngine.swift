import Foundation

// MARK: - Wealth Lab Engine
// Deterministic money math for the advanced planning features. These helpers
// never touch SwiftUI or networking, which keeps them testable and portable.

enum WealthLabEngine {

    // MARK: - Safe to Spend

    static func safeToSpend(profile: UserProfile, transactions: [Transaction],
                            bills: [Bill], goals: [FinancialGoal],
                            safetyBufferPercent: Double = 10,
                            now: Date = Date()) -> SafeToSpendBreakdown {
        let calendar = Calendar.current
        let income = max(profile.totalMonthlyIncome, 0)
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let monthRange = calendar.range(of: .day, in: .month, for: now) else {
            return SafeToSpendBreakdown(dailyAllowance: 0, spentToday: 0, remainingToday: 0,
                                        daysLeftInMonth: 0, monthlyDiscretionary: 0,
                                        fixedCommitments: 0, goalContributions: 0,
                                        projectedSavings: 0, safetyBuffer: 0)
        }

        let fixedCommitments = bills
            .filter { $0.status != .paid }
            .reduce(0) { $0 + monthlyEquivalent(bill: $1) }

        let goalContributions = max(income * min(max(profile.savingsTargetPercent, 0), 80) / 100, 0)
        let safetyBuffer = income * min(max(safetyBufferPercent, 0), 50) / 100
        let monthlyDiscretionary = max(income - fixedCommitments - goalContributions - safetyBuffer, 0)

        let daysInMonth = monthRange.count
        let dayOfMonth = calendar.component(.day, from: now)
        let daysLeft = max(daysInMonth - dayOfMonth + 1, 1)
        let dailyAllowance = monthlyDiscretionary / Double(max(daysLeft, 1))

        let spentToday = transactions
            .filter { calendar.isDate($0.date, inSameDayAs: now) && $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }

        let spentThisMonth = transactions
            .filter { $0.date >= monthStart && $0.date <= now && $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }

        let projectedSavings = max(income - fixedCommitments - spentThisMonth, 0)

        return SafeToSpendBreakdown(
            dailyAllowance: dailyAllowance,
            spentToday: spentToday,
            remainingToday: dailyAllowance - spentToday,
            daysLeftInMonth: daysLeft,
            monthlyDiscretionary: monthlyDiscretionary,
            fixedCommitments: fixedCommitments,
            goalContributions: goalContributions,
            projectedSavings: projectedSavings,
            safetyBuffer: safetyBuffer
        )
    }

    // MARK: - Recurrence Normalization

    static func monthlyEquivalent(bill: Bill) -> Double {
        switch bill.frequency {
        case .weekly: return bill.amount * 52 / 12
        case .biWeekly: return bill.amount * 26 / 12
        case .monthly: return bill.amount
        case .quarterly: return bill.amount / 3
        case .yearly: return bill.amount / 12
        }
    }

    static func monthlyEquivalent(subscription: Subscription) -> Double {
        switch subscription.cycle {
        case .weekly: return subscription.amount * 52 / 12
        case .monthly: return subscription.amount
        case .quarterly: return subscription.amount / 3
        case .yearly: return subscription.amount / 12
        }
    }

    // MARK: - Debt Payoff

    /// Simulates a debt payoff with either snowball (smallest balance first),
    /// avalanche (highest APR first), or minimum-only payments.
    static func payoff(accounts: [DebtAccountInput], extraPayment: Double,
                       strategy: PayoffStrategy, start: Date = Date()) -> PayoffSummary {
        guard !accounts.isEmpty else {
            return PayoffSummary(strategy: strategy, months: 0, totalInterest: 0,
                                 totalPaid: 0, debtFreeDate: start, payoffOrder: [])
        }

        var balances = accounts.map { max($0.balance, 0) }
        var interestPaid = 0.0
        var totalPaid = 0.0
        var months = 0
        var order: [String] = []
        let extra = strategy == .minimum ? 0 : max(extraPayment, 0)

        while balances.reduce(0, +) > 0.01 && months < 720 {
            months += 1
            for i in balances.indices where balances[i] > 0 {
                let interest = balances[i] * accounts[i].apr / 100 / 12
                balances[i] += interest
                interestPaid += interest
            }

            let minimumBudget = accounts.indices.reduce(0) { partial, i in
                balances[i] > 0 ? partial + max(accounts[i].minPayment, 0) : partial
            }
            var budget = minimumBudget + extra

            // 1. Every account receives at least its minimum where possible.
            for i in accounts.indices where balances[i] > 0 {
                let payment = min(balances[i], max(accounts[i].minPayment, 0))
                balances[i] -= payment
                totalPaid += payment
                budget -= payment
                if balances[i] <= 0.01 { balances[i] = 0 }
            }

            // 2. Extra money attacks one account at a time in strategy order.
            let targets = accounts.indices.sorted { lhs, rhs in
                switch strategy {
                case .snowball:
                    return balances[lhs] < balances[rhs]
                case .avalanche:
                    if accounts[lhs].apr == accounts[rhs].apr {
                        return balances[lhs] < balances[rhs]
                    }
                    return accounts[lhs].apr > accounts[rhs].apr
                case .minimum:
                    return lhs < rhs
                }
            }

            for i in targets where budget > 0.01 && balances[i] > 0 {
                let payment = min(balances[i], budget)
                balances[i] -= payment
                totalPaid += payment
                budget -= payment
                if balances[i] <= 0.01 { balances[i] = 0 }
            }

            for i in accounts.indices where balances[i] <= 0.01 {
                let title = accounts[i].title
                if !order.contains(title) { order.append(title) }
            }

            // If minimums no longer cover interest for every account, stop to
            // avoid an infinite simulation. The caller can raise the payment.
            if budgetsCoverInterest(accounts: accounts, balances: balances) == false && months > 600 {
                break
            }
        }

        let debtFreeDate = Calendar.current.date(byAdding: .month, value: months, to: start) ?? start
        return PayoffSummary(strategy: strategy, months: months,
                             totalInterest: interestPaid, totalPaid: totalPaid,
                             debtFreeDate: debtFreeDate, payoffOrder: order)
    }

    private static func budgetsCoverInterest(accounts: [DebtAccountInput], balances: [Double]) -> Bool {
        let monthlyInterest = accounts.indices.reduce(0.0) { $0 + balances[$1] * accounts[$1].apr / 100 / 12 }
        let minimums = accounts.reduce(0.0) { $0 + max($1.minPayment, 0) }
        return minimums >= monthlyInterest
    }

    // MARK: - Automation

    struct AutomationContext {
        var isWeeklyReview: Bool = false
        var isPayday: Bool = false
        var budgetSurplus: Double = 0
        var budgetOverspend: Double = 0
        var billPaid: Bool = false
        var safeToSpend: Double = 0
        var categorySpent: Double = 0
        var category: CategoryType? = nil
        var label: String = ""
    }

    static func evaluate(rule: AutomationRule, context: AutomationContext,
                         now: Date = Date()) -> AutomationRun? {
        guard rule.isEnabled else { return nil }
        var matched = false
        var detail = ""

        switch rule.trigger {
        case .weeklyReview:
            matched = context.isWeeklyReview
            detail = "Weekly review triggered"
        case .payday:
            matched = context.isPayday
            detail = "Payday detected"
        case .budgetSurplus:
            matched = context.budgetSurplus >= max(rule.threshold, 0.01)
            detail = "Budget surplus \(formatted(context.budgetSurplus))"
        case .budgetOverspend:
            matched = context.budgetOverspend >= max(rule.threshold, 0.01)
            detail = "Overspend \(formatted(context.budgetOverspend))"
        case .billPaid:
            matched = context.billPaid
            detail = "Bill marked paid"
        case .lowSafeToSpend:
            matched = context.safeToSpend <= max(rule.threshold, 1)
            detail = "Safe-to-spend \(formatted(context.safeToSpend))"
        case .categorySpend:
            let sameCategory = rule.category == nil || rule.category == context.category
            matched = sameCategory && context.categorySpent >= max(rule.threshold, 0.01)
            detail = "Category spend \(formatted(context.categorySpent))"
        }

        guard matched else { return nil }
        let amount = actionAmount(rule: rule, context: context)
        return AutomationRun(ruleId: rule.id, ruleName: rule.name, date: now,
                             amount: amount, detail: detail)
    }

    private static func actionAmount(rule: AutomationRule, context: AutomationContext) -> Double {
        switch rule.action {
        case .feedPiggy, .fundGoal, .topUpBudget:
            if rule.amount > 0 { return rule.amount }
            return min(max(context.budgetSurplus, 0), 100)
        case .createReminder, .flagOverspend, .logNote:
            return 0
        }
    }

    // MARK: - Subscription Detective

    static func detectSubscriptions(transactions: [Transaction],
                                    now: Date = Date()) -> [DetectedSubscription] {
        let cutoff = Calendar.current.date(byAdding: .month, value: -8, to: now) ?? now
        let relevant = transactions.filter { $0.amount > 0 && $0.date >= cutoff }
        var groups: [String: [Transaction]] = [:]

        for transaction in relevant {
            let key = normalizedMerchant(transaction.title)
            guard key.count > 2 else { continue }
            groups[key, default: []].append(transaction)
        }

        return groups.compactMap { key, items -> DetectedSubscription? in
            let sorted = items.sorted { $0.date < $1.date }
            guard sorted.count >= 2, let first = sorted.first, let last = sorted.last else { return nil }
            let intervals = zip(sorted.dropFirst(), sorted).map {
                $0.0.date.timeIntervalSince($0.1.date) / 86_400
            }
            guard !intervals.isEmpty else { return nil }
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            // Recurring charges tend to land 5–100 days apart.
            guard averageInterval >= 5, averageInterval <= 100 else { return nil }
            let uniqueMonths = Set(sorted.map {
                Calendar.current.dateComponents([.year, .month], from: $0.date).month ?? 0
            })
            guard uniqueMonths.count >= 2 else { return nil }

            let amounts = sorted.map { $0.amount }
            let average = amounts.reduce(0, +) / Double(amounts.count)
            let priceHike: Double
            if let firstAmount = amounts.first, firstAmount > 0 {
                priceHike = (amounts.last! - firstAmount) / firstAmount * 100
            } else {
                priceHike = 0
            }
            let display = sorted.last?.title ?? key.capitalized
            return DetectedSubscription(
                title: display,
                averageAmount: average,
                occurrences: sorted.count,
                lastCharge: last.date,
                estimatedMonthly: average,
                priceHikePercent: priceHike,
                candidateCategory: last.category
            )
        }
        .sorted { $0.estimatedMonthly > $1.estimatedMonthly }
    }

    private static func normalizedMerchant(_ title: String) -> String {
        let lower = title.lowercased()
        let allowed = lower.filter { $0.isLetter || $0.isNumber || $0 == " " }
        return allowed.split(separator: " ").prefix(3).joined(separator: " ")
    }

    // MARK: - Anomaly Detection

    static func detectAnomalies(transactions: [Transaction],
                                now: Date = Date()) -> [SpendingAnomaly] {
        let cutoff = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        let recent = transactions.filter { $0.amount > 0 && $0.date >= cutoff }
        var byCategory: [CategoryType: [Transaction]] = [:]
        for transaction in recent { byCategory[transaction.category, default: []].append(transaction) }

        var anomalies: [SpendingAnomaly] = []
        for (category, items) in byCategory {
            guard items.count >= 4 else { continue }
            let amounts = items.map { $0.amount }
            let mean = amounts.reduce(0, +) / Double(amounts.count)
            guard mean > 0 else { continue }
            let variance = amounts.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(amounts.count)
            let std = sqrt(variance)

            for item in items where item.amount > mean + max(std * 1.5, mean * 0.4) && item.amount > 20 {
                let deviation = (item.amount - mean) / mean * 100
                anomalies.append(SpendingAnomaly(
                    title: item.title, amount: item.amount, average: mean,
                    deviationPercent: deviation, date: item.date, category: category,
                    message: "This is \(Int(deviation.rounded()))% above your usual \(category.localized.lowercased()) spend."
                ))
            }
        }

        return Array(anomalies.sorted { $0.date > $1.date }.prefix(12))
    }

    // MARK: - Currency

    static let currencies: [CurrencyRate] = [
        .init(code: "USD", name: "US Dollar", perUSD: 1.0, symbol: "$"),
        .init(code: "EUR", name: "Euro", perUSD: 0.92, symbol: "€"),
        .init(code: "GBP", name: "British Pound", perUSD: 0.79, symbol: "£"),
        .init(code: "JPY", name: "Japanese Yen", perUSD: 149.5, symbol: "¥"),
        .init(code: "CAD", name: "Canadian Dollar", perUSD: 1.36, symbol: "C$"),
        .init(code: "AUD", name: "Australian Dollar", perUSD: 1.52, symbol: "A$"),
        .init(code: "INR", name: "Indian Rupee", perUSD: 83.2, symbol: "₹"),
        .init(code: "CNY", name: "Chinese Yuan", perUSD: 7.24, symbol: "¥"),
        .init(code: "CHF", name: "Swiss Franc", perUSD: 0.88, symbol: "Fr"),
        .init(code: "BRL", name: "Brazilian Real", perUSD: 4.98, symbol: "R$"),
        .init(code: "MXN", name: "Mexican Peso", perUSD: 17.1, symbol: "MX$"),
        .init(code: "SGD", name: "Singapore Dollar", perUSD: 1.34, symbol: "S$"),
    ]

    static func convert(amount: Double, from: String, to: String) -> Double {
        guard let source = currencies.first(where: { $0.code == from }),
              let target = currencies.first(where: { $0.code == to }) else { return amount }
        let usd = amount / source.perUSD
        return usd * target.perUSD
    }

    // MARK: - Credit Simulator

    static func simulateCreditScore(base: Int, utilization: Double,
                                    onTimePayments: Bool, newAccounts: Int,
                                    inquiries: Int) -> Int {
        var score = Double(base)
        switch utilization {
        case ..<10: score += 12
        case ..<30: score += 6
        case ..<50: score -= 8
        case ..<75: score -= 28
        default: score -= 55
        }
        score += onTimePayments ? 10 : -55
        score -= Double(max(newAccounts, 0)) * 3
        score -= Double(max(inquiries, 0)) * 5
        return Int(max(300, min(score, 850)))
    }

    // MARK: - Goal Autopilot

    static func requiredMonthly(goal: FinancialGoal, months: Int,
                                annualReturn: Double = 0) -> Double {
        let remaining = max(goal.remaining, 0)
        guard remaining > 0, months > 0 else { return 0 }
        let monthlyRate = annualReturn / 100 / 12
        if monthlyRate == 0 { return remaining / Double(months) }
        let factor = pow(1 + monthlyRate, Double(months)) - 1
        guard factor > 0 else { return remaining / Double(months) }
        return remaining * monthlyRate / factor
    }

    static func projectedCompletion(goal: FinancialGoal, monthly: Double,
                                     annualReturn: Double = 0,
                                     from: Date = Date()) -> Date? {
        guard goal.remaining > 0, monthly > 0 else { return nil }
        var balance = goal.currentAmount
        let rate = annualReturn / 100 / 12
        var months = 0
        while balance < goal.targetAmount && months < 600 {
            balance += monthly
            balance += balance * rate
            months += 1
        }
        return Calendar.current.date(byAdding: .month, value: months, to: from)
    }

    static func suggestedGoalTopUps(goals: [FinancialGoal], surplus: Double) -> [(UUID, Double)] {
        let active = goals.filter { !$0.isComplete }.sorted { $0.percentComplete < $1.percentComplete }
        guard !active.isEmpty, surplus > 0 else { return [] }
        let share = surplus / Double(active.count)
        return active.map { ($0.id, share) }
    }

    // MARK: - Formatting

    static func formatted(_ value: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(value)"
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
}
