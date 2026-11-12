import SwiftUI

// MARK: - Goal Autopilot

struct GoalAutopilotView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var applied = false

    private var activeGoals: [FinancialGoal] {
        storage.goals.filter { !$0.isComplete }.sorted { $0.percentComplete < $1.percentComplete }
    }

    private var totalRemaining: Double {
        activeGoals.reduce(0) { $0 + $1.remaining }
    }

    private var safe: SafeToSpendBreakdown {
        WealthLabEngine.safeToSpend(profile: storage.profile, transactions: storage.transactions,
                                    bills: storage.bills, goals: storage.goals)
    }

    private var suggestedSurplus: Double {
        max(safe.monthlyDiscretionary * 0.20, 0)
    }

    private var suggestions: [(UUID, Double)] {
        WealthLabEngine.suggestedGoalTopUps(goals: activeGoals, surplus: suggestedSurplus)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if activeGoals.isEmpty {
                    VaultCard {
                        VaultEmptyState(icon: "target", title: "No active goals",
                                        message: "Create a goal in the Goals hub and autopilot will build the monthly math.")
                    }
                } else {
                    autopilotCard
                    goalList
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Goal Autopilot")
        .inlineNavigationTitle()
    }

    private var hero: some View {
        LabHeroCard(
            eyebrow: "Goal Autopilot",
            title: WealthLabEngine.formatted(totalRemaining, currency: storage.profile.currency) + " to go",
            subtitle: "\(activeGoals.count) active goal(s). See the monthly amount, projected date, and one-tap top-ups.",
            icon: "target",
            gradient: VaultTheme.skyGradient
        )
    }

    private var autopilotCard: some View {
        VaultCard(tint: VaultTheme.blue) {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Suggested autopilot",
                                   subtitle: "Move 20% of today's discretionary room toward goals")
                HStack {
                    Text("Monthly surplus to deploy").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(WealthLabEngine.formatted(suggestedSurplus, currency: storage.profile.currency))
                        .font(.subheadline).bold().foregroundColor(VaultTheme.blue)
                }
                if suggestions.isEmpty {
                    Text("No surplus available right now. Protect the essentials first.")
                        .font(.caption2).foregroundColor(.secondary)
                } else {
                    ForEach(activeGoals) { goal in
                        if let share = suggestions.first(where: { $0.0 == goal.id })?.1 {
                            HStack {
                                Text(goal.title).font(.caption2)
                                Spacer()
                                Text(WealthLabEngine.formatted(share, currency: storage.profile.currency))
                                    .font(.caption2).bold().foregroundColor(VaultTheme.green)
                            }
                        }
                    }
                }
                VaultPrimaryButton(title: applied ? "Top-ups applied ✓" : "Apply suggested top-ups",
                                   icon: applied ? "checkmark.circle.fill" : "bolt.fill",
                                   gradient: VaultTheme.savingsGradient) {
                    applySuggestions()
                }
                .disabled(suggestions.isEmpty || applied)
            }
        }
    }

    private var goalList: some View {
        VStack(spacing: 10) {
            ForEach(activeGoals) { goal in
                goalCard(goal)
            }
        }
    }

    private func goalCard(_ goal: FinancialGoal) -> some View {
        let required = requiredMonthly(goal)
        let projected = WealthLabEngine.projectedCompletion(goal: goal, monthly: required)
        return VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title).font(.subheadline).bold()
                        Text("\(WealthLabEngine.formatted(goal.currentAmount, currency: storage.profile.currency)) of \(WealthLabEngine.formatted(goal.targetAmount, currency: storage.profile.currency))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(WealthLabEngine.percent(goal.percentComplete))
                        .font(.subheadline).bold().foregroundColor(VaultTheme.blue)
                }
                VaultProgressBar(progress: goal.percentComplete / 100, height: 8,
                                 gradient: VaultTheme.savingsGradient)
                HStack(spacing: 10) {
                    LabStat(label: "Required / mo",
                            value: WealthLabEngine.formatted(required, currency: storage.profile.currency),
                            icon: "calendar", tint: VaultTheme.orange)
                    LabStat(label: "At this pace",
                            value: projected?.formatted(.dateTime.month(.abbreviated).year()) ?? "—",
                            icon: "flag.checkered", tint: VaultTheme.green)
                }
                HStack(spacing: 8) {
                    topUpButton(goal, amount: 25)
                    topUpButton(goal, amount: 50)
                    topUpButton(goal, amount: 100)
                }
                Text(goal.targetDate.map { "Target date: \($0.formatted(.dateTime.month(.abbreviated).day().year()))" }
                     ?? "No target date set — assuming a 12-month horizon.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private func topUpButton(_ goal: FinancialGoal, amount: Double) -> some View {
        Button("+\(WealthLabEngine.formatted(amount, currency: storage.profile.currency))") {
            fund(goal, amount: amount)
        }
        .font(.caption2).bold()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(VaultTheme.green.opacity(0.12)))
        .foregroundColor(VaultTheme.green)
        .buttonStyle(PressableButtonStyle())
    }

    private func requiredMonthly(_ goal: FinancialGoal) -> Double {
        let months: Int
        if let date = goal.targetDate,
           let count = Calendar.current.dateComponents([.month], from: Date(), to: date).month,
           count > 0 {
            months = count
        } else {
            months = 12
        }
        return WealthLabEngine.requiredMonthly(goal: goal, months: months)
    }

    private func fund(_ goal: FinancialGoal, amount: Double) {
        guard let index = storage.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        storage.goals[index].currentAmount = min(storage.goals[index].currentAmount + amount,
                                                storage.goals[index].targetAmount)
        storage.save()
    }

    private func applySuggestions() {
        for (id, amount) in suggestions {
            if let index = storage.goals.firstIndex(where: { $0.id == id }) {
                storage.goals[index].currentAmount = min(storage.goals[index].currentAmount + amount,
                                                        storage.goals[index].targetAmount)
            }
        }
        storage.save()
        applied = true
    }
}
