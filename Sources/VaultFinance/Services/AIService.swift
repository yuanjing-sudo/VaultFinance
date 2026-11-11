import Foundation
import CoreML  // For Apple Foundation Models integration

// MARK: - AI Financial Assistant Service
// Deterministic math stays in FinanceEngine. This layer interprets and explains results.

actor AIService: @unchecked Sendable {
    private let engine = FinanceEngine()
    private(set) var isAvailable: Bool

    init() {
        self.isAvailable = Self.checkAvailability()
    }

    // MARK: - Capability detection

    static func checkAvailability() -> Bool {
        // Prefer Apple's on-device Foundation Models (MLX + Small Language Model via coremltools)
        // Fallback: mock responses when model unavailable.
        #if os(iOS)
        return UIDevice.current.systemVersion.hasPrefix("18.")  // Foundation Models in iOS 18
        #else
        return false
        #endif
    }

    // MARK: - Public API

    /// Analyze spending patterns
    func analyzeSpending(patterns: [Transaction]) -> String {
        let total = patterns.reduce(0) { $0 + $1.amount }
        let byCategory = Dictionary(grouping: patterns) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        var reply = "This month you've spent about \(Money(amount: total).formatted()).\n\n"
        reply += "Your spending by category:\n"
        for (cat, amt) in byCategory.sorted(by: { $0.1 > $1.1 }) {
            reply.append("- \(cat.localized): \(Money(amount: amt).formatted())\n")
        }
        return reply
    }

    /// Budget recommendation based on profile + fixed needs
    func recommendBudget(profile: UserProfile, fixedNeeds: Double) -> String {
        let (needs, wants, savings) = FinanceEngine.computeAllocation(profile: profile, fixedNeedsMonthly: fixedNeeds)
        let income = profile.totalMonthlyIncome
        var reply = "Based on your monthly income of \(Money(amount: income).formatted()) and fixed needs of about \(Money(amount: fixedNeeds).formatted()),\n\n"
        reply.append("Here's a suggested allocation:\n")
        reply.append("- Needs (fixed + variable): ~\(needs)% (~\(Money(amount: income * needs / 100).formatted()))\n")
        reply.append("- Wants: ~\(wants)% (~\(Money(amount: income * wants / 100).formatted()))\n")
        reply.append("- Savings: ~\(savings)% (~\(Money(amount: income * savings / 100).formatted()))\n\n")
        reply.append("This is more conservative than the standard 50/30/20 rule because your fixed needs represent a large share of your income.")
        return reply
    }

    /// Savings goal progress
    func evaluateGoal(goal: FinancialGoal, monthlyContribution: Double) -> String {
        let remaining = goal.remaining
        guard goal.targetAmount > goal.currentAmount else {
            return "Congratulations! You've reached your goal: \(goal.title). \(Money(amount: goal.targetAmount).formatted())"
        }
        let months = remaining > 0 ? Int(remaining / monthlyContribution) : 0
        return "You're working toward \(goal.title). \(Money(amount: remaining).formatted()) remaining. At \(Money(amount: monthlyContribution).formatted()) per month, that's about \(months) months."
    }

    /// Wealth explanation
    func explainWealthChange(oldNetWorth: Double, newNetWorth: Double, contribution: Double, returns: Double) -> String {
        var reply = "Your net worth moved from \(Money(amount: oldNetWorth).formatted()) to \(Money(amount: newNetWorth).formatted()).\n\n"
        if contribution > 0 {
            reply.append("\(Money(amount: contribution).formatted()) of that increase came from new contributions (savings/deposits). ")
        }
        if returns > 0 {
            reply.append("\(Money(amount: returns).formatted()) came from investment returns.")
        }
        if contribution <= 0 && returns <= 0 {
            reply.append("The change reflects market movements and account updates.")
        }
        reply.append("\nThis separation matters: it shows your returns are independent of how much you add.")
        return reply
    }

    /// Financial education explanation
    func explainConcept(concept: String) -> String {
        switch concept.lowercased() {
        case "etf":
            return "An ETF (Exchange-Traded Fund) is a basket of securities that trades like a stock. " +
                   "It lets you buy many stocks or bonds in one share, giving instant diversification. " +
                   "ETFs typically have lower fees than actively managed funds."
        case "stock":
            return "A stock represents ownership in a single company. When you buy a stock, you own a piece of that business. " +
                   "Returns come from price appreciation and, for some companies, dividends."
        case "compound":
            return "Compound interest means you earn returns on both your original investment and on previously earned returns. " +
                   "Over time, compounding creates exponential growth — which is why starting early is so powerful."
        default:
            return "Here's what I know about \(concept): start by understanding the basic concept, then learn how it applies to your own financial situation. " +
                   "Would you like me to explain a specific related term?"
        }
    }

    /// Lifestyle recommendation (local, budget-aware)
    func recommendActivities(budgetRemaining: Double) -> String {
        let suggestions: [(String, String, Double)] = [
            ("Local Park Walk", "Enjoy a scenic hike or lakeside walk.", 0),
            ("Free Museum Day", "Many museums offer free admission days.", 0),
            ("Home-Cooked Meal", "Cook a new recipe instead of dining out.", 15),
            ("Public Library", "Borrow books, movies, and attend free events.", 0),
            ("Community Event", "Check local event listings for free activities.", 0),
        ]
        let affordable = suggestions.filter { $0.2 <= budgetRemaining }.sorted { $0.1 < $1.1 }
        var reply = "Within your remaining budget of \(Money(amount: budgetRemaining).formatted()), try:\n\n"
        for (name, desc, cost) in affordable.prefix(4) {
            reply.append("- \(name) \(cost > 0 ? "- about \(Money(amount: cost).formatted())" : "- free")\n  \(desc)\n")
        }
        if affordable.isEmpty { reply = "No low-cost activities fit right now — but saving up for small treats can still be rewarding." }
        return reply
    }

    /// What-if scenario calculator (interpretation layer, math via engine)
    func calculateScenario(
        currentSavings: Double,
        additionalMonthly: Double,
        annualRate: Double,
        years: Int
    ) -> String {
        let points = FinanceEngine.projectGrowth(current: currentSavings, annualRate: annualRate, months: years * 12)
        let final = points.last?.projectedNetWorth ?? currentSavings
        let contributions = Double(additionalMonthly) * 12.0 * Double(years)
        let gain = final - currentSavings - contributions
        return "If you invest \(Money(amount: currentSavings).formatted()) plus \(Money(amount: additionalMonthly).formatted()) per month at \(annualRate)% annually:\n\n" +
               "- After \(years) year(s): \(Money(amount: final).formatted())\n" +
               "- Your own contributions: \(Money(amount: contributions).formatted())\n" +
               "- Growth from compounding: \(Money(amount: gain).formatted())"
    }
}

extension AIService {
    // Convenience for UI binding
    var statusMessage: String {
        isAvailable ? "AI assistant ready (on-device)" : "AI assistant offline — core features still work"
    }
}
