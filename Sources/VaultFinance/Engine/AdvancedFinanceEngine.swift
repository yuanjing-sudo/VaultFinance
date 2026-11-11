import Foundation

// MARK: - Advanced Finance Engine
// Deterministic, tested-style calculations. No LLM involvement in math.

extension FinanceEngine {

    // MARK: - Tax Estimation (US federal brackets, simplified)

    /// 2026-ish single-filer federal brackets (marginal). Simplified estimate only.
    static let federalBrackets: [(upper: Double, rate: Double)] = [
        (11600, 0.10),
        (47150, 0.12),
        (100525, 0.22),
        (191950, 0.24),
        (243725, 0.32),
        (609350, 0.35),
        (Double.infinity, 0.37)
    ]

    static func estimateFederalTax(taxableIncome: Double) -> Double {
        guard taxableIncome > 0 else { return 0 }
        var tax = 0.0
        var lower = 0.0
        for bracket in federalBrackets {
            if taxableIncome <= lower { break }
            let taxableInBracket = min(taxableIncome, bracket.upper) - lower
            tax += taxableInBracket * bracket.rate
            lower = bracket.upper
        }
        return max(tax, 0)
    }

    static func estimateTax(profile: TaxProfile) -> (federal: Double, state: Double, total: Double, effectiveRate: Double) {
        let taxable = max(profile.grossIncome - profile.preTaxDeductions
                          - standardDeduction(for: profile.filingStatus)
                          - Double(profile.dependents) * 2000, 0)
        let federal = estimateFederalTax(taxableIncome: taxable)
        let state = max(profile.grossIncome - profile.preTaxDeductions, 0) * profile.stateTaxRate / 100
        let total = federal + state
        let effective = profile.grossIncome > 0 ? total / profile.grossIncome * 100 : 0
        return (federal, state, total, effective)
    }

    static func standardDeduction(for status: TaxProfile.FilingStatus) -> Double {
        switch status {
        case .single: return 14600
        case .marriedJoint: return 29200
        case .marriedSeparate: return 14600
        case .headOfHousehold: return 21900
        }
    }

    static func marginalRate(taxableIncome: Double) -> Double {
        var lower = 0.0
        for bracket in federalBrackets {
            if taxableIncome <= bracket.upper { return bracket.rate }
            lower = bracket.upper
        }
        return 0.37
    }

    // MARK: - Loan Amortization

    /// Build a full amortization schedule.
    static func amortizationSchedule(principal: Double, annualRate: Double, months: Int) -> [AmortizationEntry] {
        guard principal > 0, months > 0 else { return [] }
        let monthlyRate = annualRate / 100 / 12
        let payment: Double
        if monthlyRate == 0 {
            payment = principal / Double(months)
        } else {
            payment = principal * monthlyRate / (1 - pow(1 + monthlyRate, -Double(months)))
        }
        var balance = principal
        var schedule: [AmortizationEntry] = []
        for m in 1...months {
            let interest = balance * monthlyRate
            let principalPaid = min(payment - interest, balance)
            balance = max(balance - principalPaid, 0)
            schedule.append(AmortizationEntry(
                month: m,
                payment: payment,
                principal: principalPaid,
                interest: interest,
                balance: balance
            ))
            if balance <= 0 { break }
        }
        return schedule
    }

    static func monthlyLoanPayment(principal: Double, annualRate: Double, months: Int) -> Double {
        guard principal > 0, months > 0 else { return 0 }
        let r = annualRate / 100 / 12
        if r == 0 { return principal / Double(months) }
        return principal * r / (1 - pow(1 + r, -Double(months)))
    }

    static func totalInterest(schedule: [AmortizationEntry]) -> Double {
        schedule.reduce(0) { $0 + $1.interest }
    }

    // MARK: - FIRE Calculator

    /// Financial Independence number using the 4% safe withdrawal rule.
    static func fireNumber(annualExpenses: Double, withdrawalRate: Double = 4.0) -> Double {
        guard withdrawalRate > 0 else { return 0 }
        return annualExpenses / (withdrawalRate / 100)
    }

    /// Years to FIRE with monthly contributions and expected return.
    static func yearsToFIRE(current: Double, monthlyContribution: Double, annualExpenses: Double,
                            withdrawalRate: Double = 4.0, annualReturn: Double = 7.0) -> Double {
        let target = fireNumber(annualExpenses: annualExpenses, withdrawalRate: withdrawalRate)
        guard current < target else { return 0 }
        let r = annualReturn / 100 / 12
        var balance = current
        var months = 0
        while balance < target && months < 12 * 80 {
            balance = balance * (1 + r) + monthlyContribution
            months += 1
        }
        return Double(months) / 12.0
    }

    // MARK: - Compound Interest

    static func compoundGrowth(principal: Double, monthlyContribution: Double,
                               annualRate: Double, years: Int) -> [CompoundPoint] {
        var points: [CompoundPoint] = []
        var balance = principal
        var contributed = principal
        let monthlyRate = annualRate / 100 / 12
        for year in 0...years {
            if year > 0 {
                for _ in 0..<12 {
                    balance = balance * (1 + monthlyRate) + monthlyContribution
                    contributed += monthlyContribution
                }
            }
            points.append(CompoundPoint(year: year, balance: balance, contributed: contributed))
        }
        return points
    }

    // MARK: - Budget Forecasting

    /// Forecast next N months of spending using average + trend.
    static func forecastSpending(historical: [Double], months: Int) -> [Double] {
        guard !historical.isEmpty else { return Array(repeating: 0, count: months) }
        let avg = historical.reduce(0, +) / Double(historical.count)
        let recent = Array(historical.suffix(min(3, historical.count)))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let trend = recentAvg - avg
        return (1...months).map { i in max(0, avg + trend * Double(i)) }
    }

    // MARK: - 52-Week Challenge

    /// Classic 52-week challenge: week 1 = $1, week 2 = $2, ... week 52 = $52.
    static func fiftyTwoWeekProgress(weeksCompleted: Int) -> (saved: Double, total: Double) {
        let clamped = max(0, min(weeksCompleted, 52))
        let saved = Double(clamped * (clamped + 1)) / 2.0
        let total = 52.0 * 53.0 / 2.0
        return (saved, total)
    }

    // MARK: - Inflation Adjustment

    static func inflationAdjusted(value: Double, annualInflation: Double, years: Double) -> Double {
        value / pow(1 + annualInflation / 100, years)
    }

    static func purchasingPowerLoss(value: Double, annualInflation: Double, years: Double) -> Double {
        value - inflationAdjusted(value: value, annualInflation: annualInflation, years: years)
    }

    // MARK: - Savings Rate & Rule of 72

    static func savingsRate(income: Double, savings: Double) -> Double {
        guard income > 0 else { return 0 }
        return savings / income * 100
    }

    static func ruleOf72(annualRate: Double) -> Double {
        guard annualRate > 0 else { return 0 }
        return 72.0 / annualRate
    }

    // MARK: - Credit Utilization

    static func creditUtilization(balance: Double, limit: Double) -> Double {
        guard limit > 0 else { return 0 }
        return min(balance / limit * 100, 100)
    }

    static func creditScoreImpact(utilization: Double) -> String {
        switch utilization {
        case ..<10: return "Excellent — keep it under 10%."
        case 10..<30: return "Good — under 30% is healthy."
        case 30..<50: return "Fair — try to reduce balances."
        default: return "High — utilization is hurting your score."
        }
    }

    // MARK: - Subscription Audit

    static func subscriptionAnnualTotal(_ subs: [Subscription]) -> Double {
        subs.filter { $0.isActive }.reduce(0) { $0 + $1.annualizedCost }
    }

    static func subscriptionMonthlyTotal(_ subs: [Subscription]) -> Double {
        subs.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }

    static func subscriptionWasteEstimate(_ subs: [Subscription], unusedMonths: Int = 3) -> Double {
        subscriptionMonthlyTotal(subs) * Double(unusedMonths)
    }

    // MARK: - Days of Buffer

    static func daysOfBuffer(savings: Double, dailySpend: Double) -> Int {
        guard dailySpend > 0 else { return 0 }
        return Int(savings / dailySpend)
    }

    // MARK: - Round-Up Savings

    static func roundUpAmount(transaction: Double, roundTo: Double) -> Double {
        guard roundTo > 0, transaction > 0 else { return 0 }
        let remainder = transaction.truncatingRemainder(dividingBy: roundTo)
        return remainder == 0 ? 0 : roundTo - remainder
    }

    // MARK: - Risk Score

    static func riskScore(profile: UserProfile, liabilities: [Liability]) -> Int {
        var score = 50
        switch profile.riskTolerance {
        case "conservative": score -= 10
        case "aggressive": score += 15
        default: break
        }
        switch profile.investmentExperience {
        case "beginner": score -= 5
        case "advanced": score += 10
        default: break
        }
        let dti = debtToIncomeRatio(profile: profile, liabilities: liabilities)
        if dti > 40 { score -= 15 } else if dti < 20 { score += 10 }
        if profile.existingSavings > profile.totalMonthlyIncome * 6 { score += 10 }
        return max(0, min(100, score))
    }

    static func debtToIncomeRatio(profile: UserProfile, liabilities: [Liability]) -> Double {
        let income = profile.totalMonthlyIncome
        guard income > 0 else { return 0 }
        let debt = liabilities.reduce(0) { $0 + $1.monthlyPayment }
        return debt / income * 100
    }

    // MARK: - Goal Insights

    static func goalMonthsRemaining(goal: FinancialGoal, monthlyContribution: Double) -> Int {
        guard monthlyContribution > 0, goal.remaining > 0 else { return 0 }
        return Int(ceil(goal.remaining / monthlyContribution))
    }

    static func goalOnTrack(goal: FinancialGoal) -> Bool {
        guard let targetDate = goal.targetDate else { return goal.percentComplete >= 50 }
        let monthsLeft = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        let neededPerMonth = monthsLeft > 0 ? goal.remaining / Double(monthsLeft) : goal.remaining
        return neededPerMonth <= goal.remaining / 12
    }

    // MARK: - Cash Flow Forecast

    static func projectedCashFlow(income: Double, expenses: Double, months: Int) -> [Double] {
        let net = income - expenses
        return (1...months).map { Double($0) * net }
    }
}

// MARK: - Supporting Types

struct AmortizationEntry: Identifiable, Hashable {
    let id = UUID()
    var month: Int
    var payment: Double
    var principal: Double
    var interest: Double
    var balance: Double
}

struct CompoundPoint: Identifiable, Hashable {
    let id = UUID()
    var year: Int
    var balance: Double
    var contributed: Double

    var growth: Double { balance - contributed }
}
