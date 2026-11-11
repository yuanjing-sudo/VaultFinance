import SwiftUI

// MARK: - Goals Hub
// Detailed savings goals with progress rings, required monthly pace, and
// on-track status. Contribute directly from each card.

struct GoalsHubView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAdd = false
    @State private var contributingTo: FinancialGoal?

    private var active: [FinancialGoal] { storage.goals.filter { !$0.isComplete } }
    private var done: [FinancialGoal] { storage.goals.filter { $0.isComplete } }

    private var totalTarget: Double { storage.goals.reduce(0) { $0 + $1.targetAmount } }
    private var totalSaved: Double { storage.goals.reduce(0) { $0 + $1.currentAmount } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if active.isEmpty && done.isEmpty {
                    VaultEmptyState(icon: "target", title: "No goals yet",
                                    message: "Set a target and watch your progress compound.",
                                    actionTitle: "Create Goal") { showingAdd = true }
                }
                if !active.isEmpty {
                    ForEach(active) { goal in
                        GoalDetailCard(goal: goal,
                                       monthsRemaining: FinanceEngine.goalMonthsRemaining(
                                        goal: goal, monthlyContribution: monthlyPace(goal))) {
                            contributingTo = goal
                        }
                    }
                }
                if !done.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Achieved 🎯").font(.headline).bold()
                        ForEach(done) { goal in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(VaultTheme.green)
                                Text(goal.title).font(.subheadline)
                                Spacer()
                                Text(Money(amount: goal.targetAmount).formatted())
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(VaultTheme.green.opacity(0.08)))
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Goals")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddGoalSheet(existing: storage.goals) { goal in
                storage.goals.append(goal)
                storage.save()
            }
        }
        .sheet(item: $contributingTo) { goal in
            ContributeGoalSheet(goal: goal) { amount in
                guard let index = storage.goals.firstIndex(where: { $0.id == goal.id }) else { return }
                storage.goals[index].currentAmount += amount
                storage.save()
            }
        }
    }

    private var headerCard: some View {
        VaultGradientCard(gradient: VaultTheme.brandGradient) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goals progress").font(.caption).opacity(0.9)
                    Text(Money(amount: totalSaved, currency: storage.profile.currency).formatted())
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("of \(Money(amount: totalTarget).formatted()) across \(storage.goals.count) goals")
                        .font(.caption2).opacity(0.85)
                }
                Spacer()
                VaultProgressRing(progress: totalTarget > 0 ? totalSaved / totalTarget : 0,
                                  lineWidth: 10, tint: .white, track: .white.opacity(0.25))
                    .frame(width: 64, height: 64)
            }
        }
    }

    private func monthlyPace(_ goal: FinancialGoal) -> Double {
        guard let date = goal.targetDate else { return max(goal.remaining / 12, 1) }
        let months = max(Calendar.current.dateComponents([.month], from: Date(), to: date).month ?? 1, 1)
        return max(goal.remaining / Double(months), 1)
    }
}

// MARK: - Goal Card

struct GoalDetailCard: View {
    let goal: FinancialGoal
    let monthsRemaining: Int
    var onContribute: () -> Void

    private var onTrack: Bool { FinanceEngine.goalOnTrack(goal: goal) }

    var body: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VaultProgressRing(progress: goal.percentComplete / 100,
                                      lineWidth: 7, tint: VaultTheme.green)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text("\(goal.percentComplete, specifier: "%.0f")%")
                                .font(.caption2).bold()
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(goal.title).font(.subheadline).bold()
                        Text("\(Money(amount: goal.currentAmount).formatted()) of \(Money(amount: goal.targetAmount).formatted())")
                            .font(.caption2).foregroundColor(.secondary)
                        VaultPill(text: onTrack ? "On track" : "Needs focus",
                                  icon: onTrack ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                                  color: onTrack ? VaultTheme.green : VaultTheme.orange)
                    }
                    Spacer()
                }
                VaultProgressBar(progress: goal.percentComplete / 100,
                                 gradient: VaultTheme.savingsGradient)
                HStack {
                    stat("Remaining", Money(amount: goal.remaining).formatted())
                    Spacer()
                    stat("Pace", monthsRemaining > 0 ? "\(monthsRemaining) mo" : "—")
                    Spacer()
                    if let date = goal.targetDate {
                        stat("Target", date.formatted(.dateTime.month(.abbreviated).year()))
                    } else {
                        stat("Horizon", goal.horizon.localized)
                    }
                }
                Button {
                    onContribute()
                } label: {
                    Label("Contribute", systemImage: "plus")
                        .font(.caption).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(VaultTheme.green.opacity(0.14)))
                        .foregroundColor(VaultTheme.green)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption).bold()
        }
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existing: [FinancialGoal]
    var onSave: (FinancialGoal) -> Void

    @State private var title = ""
    @State private var target = ""
    @State private var current = ""
    @State private var horizon: GoalTimeHorizon = .yearly
    @State private var hasDate = true
    @State private var targetDate = Date().addingTimeInterval(86400 * 180)

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $title)
                    TextField("Target amount", text: $target)
                        .keyboardType(.decimalPad)
                    TextField("Already saved", text: $current)
                        .keyboardType(.decimalPad)
                }
                Section("Timeline") {
                    Picker("Horizon", selection: $horizon) {
                        ForEach(GoalTimeHorizon.allCases, id: \.self) {
                            Text($0.localized).tag($0)
                        }
                    }
                    Toggle("Set a target date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Target date", selection: $targetDate,
                                   displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(FinancialGoal(
                            title: title.isEmpty ? "New Goal" : title,
                            targetAmount: Double(target) ?? 1000,
                            currentAmount: Double(current) ?? 0,
                            horizon: horizon,
                            targetDate: hasDate ? targetDate : nil
                        ))
                        dismiss()
                    }
                    .bold()
                    .disabled(target.isEmpty)
                }
            }
        }
    }
}

// MARK: - Contribute Sheet

struct ContributeGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let goal: FinancialGoal
    var onSave: (Double) -> Void

    @State private var amount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(goal.title).font(.headline)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Text("Remaining: \(Money(amount: goal.remaining).formatted())")
                        .font(.caption).foregroundColor(.secondary)
                }
                Section {
                    ForEach([25.0, 50.0, 100.0, 250.0], id: \.self) { quick in
                        Button("Add \(Money(amount: quick).formatted())") {
                            amount = "\(quick)"
                        }
                    }
                }
            }
            .navigationTitle("Contribute")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(Double(amount) ?? 0)
                        dismiss()
                    }
                    .bold()
                    .disabled(Double(amount) == nil)
                }
            }
        }
    }
}
