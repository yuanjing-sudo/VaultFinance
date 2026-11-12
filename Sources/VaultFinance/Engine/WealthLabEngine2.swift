import Foundation

// MARK: - Wealth Lab Engine, Part 2
// Portfolio, imports, quests, plans, tax, negotiations and seasonal skins.

extension WealthLabEngine {

    // MARK: - Portfolio

    static func allocation(holdings: [PortfolioHolding]) -> [AllocationSlice] {
        var totals: [String: Double] = [:]
        for holding in holdings where holding.marketValue > 0 {
            totals[holding.assetClass, default: 0] += holding.marketValue
        }
        return totals.map { key, value in
            AllocationSlice(label: key, value: value, colorKey: allocationColor(for: key))
        }
        .sorted { $0.value > $1.value }
    }

    static func allocationColor(for assetClass: String) -> String {
        switch assetClass.lowercased() {
        case "stock", "stocks": return "blue"
        case "etf": return "green"
        case "crypto": return "orange"
        case "bond", "bonds": return "purple"
        case "cash": return "teal"
        case "real estate": return "gold"
        default: return "pink"
        }
    }

    static func rebalance(holdings: [PortfolioHolding]) -> [RebalanceAction] {
        let total = holdings.reduce(0) { $0 + $1.marketValue }
        guard total > 0 else { return [] }
        let targetSum = holdings.reduce(0) { $0 + max($1.targetWeight, 0) }
        let equalWeight = 100 / Double(max(holdings.count, 1))

        return holdings.map { holding in
            let current = holding.marketValue / total * 100
            let target = targetSum > 0 ? holding.targetWeight : equalWeight
            let drift = current - target
            let dollar = (target - current) / 100 * total
            let recommendation: String
            if abs(drift) < 1 {
                recommendation = "On target"
            } else if drift > 0 {
                recommendation = "Trim \(formatted(abs(dollar)))"
            } else {
                recommendation = "Add \(formatted(abs(dollar)))"
            }
            return RebalanceAction(symbol: holding.symbol, currentPercent: current,
                                   targetPercent: target, drift: drift,
                                   dollarAction: dollar, recommendation: recommendation)
        }
        .sorted { abs($0.drift) > abs($1.drift) }
    }

    static func portfolioValue(_ holdings: [PortfolioHolding]) -> Double {
        holdings.reduce(0) { $0 + $1.marketValue }
    }

    static func portfolioCost(_ holdings: [PortfolioHolding]) -> Double {
        holdings.reduce(0) { $0 + $1.costBasis }
    }

    // MARK: - Statement Import

    static func parseStatementCSV(_ text: String, currency: String = "USD") -> [ImportedTransaction] {
        let rawLines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard rawLines.count >= 1 else { return [] }

        let firstFields = splitCSVLine(rawLines[0]).map { $0.lowercased() }
        let hasHeader = firstFields.contains(where: { $0.contains("date") })
            || firstFields.contains(where: { $0.contains("amount") || $0.contains("description") })

        let header = hasHeader ? firstFields : []
        let dateIndex = header.firstIndex(where: { $0.contains("date") }) ?? 0
        let titleIndex = header.firstIndex(where: {
            $0.contains("description") || $0.contains("merchant") || $0.contains("payee") || $0.contains("name")
        }) ?? 1
        let amountIndex = header.firstIndex(where: { $0.contains("amount") || $0.contains("value") }) ?? 2
        let debitIndex = header.firstIndex(where: { $0.contains("debit") || $0.contains("withdrawal") })
        let categoryIndex = header.firstIndex(where: { $0.contains("category") })

        let dataLines = hasHeader ? Array(rawLines.dropFirst()) : rawLines
        return dataLines.compactMap { line -> ImportedTransaction? in
            let fields = splitCSVLine(line)
            guard fields.count > max(dateIndex, titleIndex) else { return nil }
            guard let date = parseImportDate(fields[safe: dateIndex] ?? "") else { return nil }

            let title = fields[safe: titleIndex]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else { return nil }

            var amount = 0.0
            if let debitIndex, let debit = fields[safe: debitIndex], !debit.isEmpty {
                amount = parseImportAmount(debit)
            } else if let raw = fields[safe: amountIndex] {
                amount = parseImportAmount(raw)
            }
            guard amount != 0 else { return nil }

            // Bank exports often use negative numbers for spending. Normalize
            // to positive spending values for the Vault transaction model.
            if amount < 0 { amount = abs(amount) }

            let guessed: CategoryType
            if let categoryIndex, let raw = fields[safe: categoryIndex] {
                guessed = category(for: raw)
            } else {
                guessed = category(for: title)
            }

            return ImportedTransaction(date: date, title: title, amount: amount,
                                       category: guessed, isDuplicate: false)
        }
    }

    static func markDuplicates(imported: [ImportedTransaction],
                               existing: [Transaction]) -> [ImportedTransaction] {
        imported.map { item in
            var copy = item
            copy.isDuplicate = existing.contains { transaction in
                Calendar.current.isDate(transaction.date, inSameDayAs: item.date)
                    && abs(transaction.amount - item.amount) < 0.01
                    && transaction.title.lowercased() == item.title.lowercased()
            }
            return copy
        }
    }

    static func category(for text: String) -> CategoryType {
        let t = text.lowercased()
        if ["rent", "mortgage", "utility", "utilities", "insurance", "phone", "internet", "tax"].contains(where: { t.contains($0) }) {
            return .needsFixed
        }
        if ["grocery", "groceries", "food", "gas", "fuel", "transport", "supermarket", "pharmacy", "health"].contains(where: { t.contains($0) }) {
            return .needsVariable
        }
        if ["saving", "investment", "broker", "transfer", "deposit"].contains(where: { t.contains($0) }) {
            return .savings
        }
        return .wants
    }

    private static func splitCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let characters = Array(line)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if inQuotes && index + 1 < characters.count && characters[index + 1] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if character == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(character)
            }
            index += 1
        }
        fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return fields
    }

    private static func parseImportDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = ["yyyy-MM-dd", "MM/dd/yyyy", "M/d/yy", "MM/dd/yy",
                       "dd/MM/yyyy", "yyyy/MM/dd", "MMM d, yyyy", "MMMM d, yyyy"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) { return date }
        }
        let iso = ISO8601DateFormatter()
        return iso.date(from: trimmed)
    }

    private static func parseImportAmount(_ value: String) -> Double {
        var text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        text = text.replacingOccurrences(of: "$", with: "")
        text = text.replacingOccurrences(of: "€", with: "")
        text = text.replacingOccurrences(of: "£", with: "")
        text = text.replacingOccurrences(of: ",", with: "")
        var negative = false
        if text.hasPrefix("(") && text.hasSuffix(")") {
            negative = true
            text = String(text.dropFirst().dropLast())
        }
        if text.hasPrefix("-") {
            negative = true
            text = String(text.dropFirst())
        }
        let parsed = Double(text) ?? 0
        return negative ? -parsed : parsed
    }

    // MARK: - Weekly Quests

    static func currentWeekStart(from date: Date = Date()) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    static func generateQuests(spendingDays: [SpendingDay],
                               transactions: [Transaction],
                               deposits: [PiggyDeposit],
                               categories: [BudgetCategory],
                               dailyGoal: Double,
                               now: Date = Date()) -> [WeeklyQuest] {
        let weekStart = currentWeekStart(from: now)
        let weekDays = spendingDays.filter { $0.date >= weekStart }
        let weekTransactions = transactions.filter { $0.date >= weekStart }
        let weekDeposits = deposits.filter { $0.date >= weekStart }

        let noSpendDays = weekDays.filter { $0.amount <= 0 && $0.transactionCount == 0 }.count
        let loggedDays = weekDays.filter { $0.transactionCount > 0 }.count
        let saved = weekDeposits.reduce(0) { $0 + $1.amount }
        let spendsUnderGoal = weekDays.filter { $0.amount > 0 && $0.amount <= dailyGoal }.count
        let reviewedBudget = categories.isEmpty ? 0 : 1
        _ = weekTransactions

        var quests = [
            WeeklyQuest(title: "No-spend ×3", detail: "Keep three days completely spend-free.",
                        icon: "hand.raised.fill", target: 3, progress: Double(noSpendDays),
                        xp: 60, weekStart: weekStart, kind: .noSpend),
            WeeklyQuest(title: "Log 5 money days", detail: "Log spending on five days this week.",
                        icon: "square.and.pencil", target: 5, progress: Double(loggedDays),
                        xp: 50, weekStart: weekStart, kind: .logSpending),
            WeeklyQuest(title: "Feed the piggy", detail: "Make two deposits this week.",
                        icon: "pawprint.fill", target: 2, progress: Double(weekDeposits.count),
                        xp: 70, weekStart: weekStart, kind: .feedPiggy),
            WeeklyQuest(title: "Stay under goal", detail: "Meet your daily spending goal four times.",
                        icon: "target", target: 4, progress: Double(spendsUnderGoal),
                        xp: 80, weekStart: weekStart, kind: .save),
            WeeklyQuest(title: "Review the plan", detail: "Open your budget and review one category.",
                        icon: "list.bullet.rectangle", target: 1, progress: Double(reviewedBudget),
                        xp: 40, weekStart: weekStart, kind: .reviewBudget),
        ]

        if saved >= 100 {
            for index in quests.indices where quests[index].kind == .save {
                quests[index].progress = max(quests[index].progress, quests[index].target)
            }
        }
        for index in quests.indices {
            quests[index].isComplete = quests[index].progress >= quests[index].target
        }
        return quests.sorted { $0.xp > $1.xp }
    }

    static func availableShields(_ shields: [StreakShield]) -> Int {
        shields.filter { !$0.isUsed }.count
    }

    // MARK: - Personalized Plan

    static func buildPlan(profile: UserProfile, categories: [BudgetCategory],
                          liabilities: [Liability]) -> PersonalizedPlan {
        let income = max(profile.totalMonthlyIncome, 1)
        let essential = categories
            .filter { $0.type == .needsFixed || $0.type == .needsVariable }
            .reduce(0) { $0 + $1.budgetedAmount }
        let essentialSpend = essential > 0 ? essential : income * 0.55
        let emergencyMonths: Double = profile.dependents > 0 ? 6 : 3
        let emergencyFund = essentialSpend * emergencyMonths

        let savingsRate = min(max(profile.savingsTargetPercent > 0 ? profile.savingsTargetPercent : 20, 5), 60)
        let investing: Double
        switch profile.riskTolerance.lowercased() {
        case "aggressive": investing = 15
        case "conservative": investing = 5
        default: investing = 10
        }

        var needsPercent = min(max(essentialSpend / income * 100, 40), 65)
        var wantsPercent = max(100 - needsPercent - savingsRate - investing, 5)
        if needsPercent + wantsPercent + savingsRate + investing > 100 {
            wantsPercent = max(100 - needsPercent - savingsRate - investing, 0)
        }
        if needsPercent + wantsPercent + savingsRate + investing < 100 {
            needsPercent += 100 - (needsPercent + wantsPercent + savingsRate + investing)
        }

        let budget = [
            PlanCategory(name: "Essentials", type: .needsFixed, percent: needsPercent, amount: income * needsPercent / 100),
            PlanCategory(name: "Lifestyle", type: .wants, percent: wantsPercent, amount: income * wantsPercent / 100),
            PlanCategory(name: "Savings", type: .savings, percent: savingsRate, amount: income * savingsRate / 100),
            PlanCategory(name: "Investing", type: .savings, percent: investing, amount: income * investing / 100),
        ]

        var steps = [
            "Build a \(formatted(emergencyFund)) emergency fund (\(Int(emergencyMonths)) months of essentials).",
            "Automate at least \(formatted(income * savingsRate / 100)) into savings every payday.",
            "Keep housing and fixed bills below \(Int(needsPercent))% of take-home pay.",
        ]
        if liabilities.contains(where: { $0.interestRate >= 12 }) {
            steps.append("Attack high-interest debt first — every extra payment cuts future interest.")
        } else {
            steps.append("Invest \(formatted(income * investing / 100)) monthly in a diversified index fund.")
        }
        if profile.dependents > 0 {
            steps.append("Review term life and disability cover for your \(profile.dependents) dependent(s).")
        }
        steps.append("Run a 10-minute money review every Sunday to keep the plan on track.")

        let riskProfile: String
        switch profile.riskTolerance.lowercased() {
        case "aggressive": riskProfile = "Growth"
        case "conservative": riskProfile = "Steady"
        default: riskProfile = "Balanced"
        }

        return PersonalizedPlan(recommendedEmergencyFund: emergencyFund,
                                recommendedSavingsRate: savingsRate,
                                recommendedInvestingPercent: investing,
                                suggestedBudget: budget,
                                riskProfile: riskProfile,
                                steps: steps)
    }

    // MARK: - Tax Vault

    static func taxDeadlines(year: Int) -> [TaxDeadline] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        func date(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        }
        return [
            TaxDeadline(title: "W-2 / 1099 forms arrive", date: date(1, 31),
                        detail: "Employers and brokers should send income forms.", icon: "envelope.fill"),
            TaxDeadline(title: "Last day to contribute to IRA", date: date(4, 15),
                        detail: "Contribute to prior-year retirement accounts.", icon: "banknote.fill"),
            TaxDeadline(title: "Tax filing deadline", date: date(4, 15),
                        detail: "File your return or request an extension.", icon: "doc.text.fill"),
            TaxDeadline(title: "Extension deadline", date: date(10, 15),
                        detail: "Final deadline if you filed for an extension.", icon: "calendar.badge.exclamationmark"),
        ]
    }

    static func taxSummary(documents: [TaxDocument]) -> (income: Double, deductions: Double, filed: Int, total: Int) {
        let income = documents
            .filter { $0.kind == .w2 || $0.kind == .form1099 }
            .reduce(0) { $0 + $1.amount }
        let deductions = documents
            .filter { $0.kind == .deduction || $0.kind == .form1098 }
            .reduce(0) { $0 + $1.amount }
        return (income, deductions, documents.filter { $0.isFiled }.count, documents.count)
    }

    // MARK: - Bill Negotiation

    static func negotiationOpportunities(bills: [Bill]) -> [NegotiationOpportunity] {
        bills
            .filter { $0.status != .paid && monthlyEquivalent(bill: $0) >= 20 }
            .map { bill -> NegotiationOpportunity in
                let current = monthlyEquivalent(bill: bill)
                let target = current * 0.82
                let savings = (current - target) * 12
                let script = "Hi \(bill.title) team, I've been a loyal customer and I'm reviewing my monthly bills. "
                    + "I'd like to stay, but I need to bring this down to about \(formatted(target)) per month. "
                    + "Are there any retention offers, loyalty discounts, or current promotions you can apply?"
                return NegotiationOpportunity(billId: bill.id, title: bill.title,
                                              currentMonthly: current, targetMonthly: target,
                                              estimatedAnnualSavings: savings, script: script,
                                              priority: Int(savings.rounded()))
            }
            .sorted { $0.estimatedAnnualSavings > $1.estimatedAnnualSavings }
    }

    // MARK: - Subscription Reviews

    static func review(for subscription: Subscription, reviews: [SubscriptionReview]) -> SubscriptionReview? {
        reviews.first { $0.subscriptionTitle == subscription.title }
    }

    static func potentialSavings(reviews: [SubscriptionReview]) -> Double {
        reviews.filter { $0.verdict == .cancel }.reduce(0) { $0 + $1.annualCost }
    }

    static func reviewsDueCount(reviews: [SubscriptionReview], now: Date = Date()) -> Int {
        reviews.filter {
            $0.verdict == .review
                && Calendar.current.dateComponents([.day], from: $0.lastReviewed, to: now).day ?? 999 > 30
        }.count
    }

    // MARK: - Health Timeline

    static func healthTimeline(_ scores: [FinancialHealthScore]) -> [HealthTimelinePoint] {
        scores.sorted { $0.date < $1.date }.map { score in
            HealthTimelinePoint(date: score.date, score: score.score,
                                label: score.date.formatted(.dateTime.month(.abbreviated).day()))
        }
    }

    // MARK: - Piggy Skins

    static let piggySkins: [PiggySkin] = [
        .init(name: "Classic Coral", hex: "#F5A623", personality: .classic,
              unlockHint: "Available now", requiredDeposits: 0),
        .init(name: "Glitter Pop", hex: "#EC4899", personality: .glitter,
              unlockHint: "Make 3 deposits", requiredDeposits: 3),
        .init(name: "Stealth Mode", hex: "#111827", personality: .stealth,
              unlockHint: "Make 6 deposits", requiredDeposits: 6),
        .init(name: "Rainbow Vault", hex: "#8B5CF6", personality: .rainbow,
              unlockHint: "Make 10 deposits", requiredDeposits: 10),
        .init(name: "Gold Reserve", hex: "#FBBF24", personality: .gold,
              unlockHint: "Make 20 deposits", requiredDeposits: 20),
    ]

    static func availableSkins(depositCount: Int) -> [PiggySkin] {
        piggySkins.filter { depositCount >= $0.requiredDeposits }
    }

    // MARK: - Challenge Templates

    static let challengeTemplates: [LabChallengeTemplate] = [
        .init(title: "No-Spend Weekend", detail: "Spend $0 on wants from Friday to Sunday.",
              icon: "hand.raised.fill", target: 1, days: 3, rewardXP: 120, tint: "green"),
        .init(title: "52-Week Savings", detail: "Save $1 more each week for a year.",
              icon: "calendar.badge.clock", target: 1378, days: 365, rewardXP: 500, tint: "blue"),
        .init(title: "Pantry Challenge", detail: "Cook from what you already own for seven days.",
              icon: "fork.knife", target: 7, days: 7, rewardXP: 150, tint: "orange"),
        .init(title: "Round-Up Sprint", detail: "Round up every purchase for two weeks.",
              icon: "arrow.up.circle.fill", target: 50, days: 14, rewardXP: 180, tint: "teal"),
        .init(title: "Subscription Sweep", detail: "Review and cancel one unused subscription.",
              icon: "eyes", target: 1, days: 7, rewardXP: 100, tint: "purple"),
        .init(title: "Emergency Fund Boost", detail: "Add an extra 10% to your emergency fund.",
              icon: "shield.lefthalf.filled", target: 100, days: 30, rewardXP: 250, tint: "pink"),
    ]
}

// MARK: - Safe collection access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
