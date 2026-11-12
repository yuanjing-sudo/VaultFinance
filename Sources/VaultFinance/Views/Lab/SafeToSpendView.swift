import SwiftUI

// MARK: - Safe To Spend

struct SafeToSpendView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var safetyBuffer: Double = 10
    @State private var showingSpend = false

    private var safe: SafeToSpendBreakdown {
        WealthLabEngine.safeToSpend(profile: storage.profile, transactions: storage.transactions,
                                    bills: storage.bills, goals: storage.goals,
                                    safetyBufferPercent: safetyBuffer)
    }

    private var monthSpent: Double {
        let calendar = Calendar.current
        return storage.transactions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) && $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                breakdownCard
                bufferCard
                projectionCard
                actionCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Safe to Spend")
        .inlineNavigationTitle()
        .sheet(isPresented: $showingSpend) {
            AddLabSpendView()
        }
    }

    private var hero: some View {
        let remaining = safe.remainingToday
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SAFE TO SPEND TODAY").font(.caption2).bold().opacity(0.85)
                Spacer()
                Image(systemName: remaining >= 0 ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.title3)
            }
            Text(WealthLabEngine.formatted(abs(remaining), currency: storage.profile.currency))
                .font(.system(size: 42, weight: .heavy, design: .rounded))
            if remaining >= 0 {
                Text("You can still spend this and stay on plan.")
                    .font(.caption).opacity(0.9)
            } else {
                Text("Over today's allowance by this amount.")
                    .font(.caption).bold().opacity(0.95)
            }
            VaultProgressBar(progress: safe.progress, height: 8,
                             gradient: LinearGradient(colors: [.white.opacity(0.9), .white],
                                                      startPoint: .leading, endPoint: .trailing),
                             track: Color.white.opacity(0.25))
            HStack {
                Text("\(WealthLabEngine.formatted(safe.spentToday, currency: storage.profile.currency)) spent today")
                Spacer()
                Text("\(WealthLabEngine.formatted(safe.dailyAllowance, currency: storage.profile.currency)) allowance")
            }
            .font(.caption2).opacity(0.85)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(remaining >= 0 ? VaultTheme.savingsGradient : VaultTheme.warningGradient)
        )
        .foregroundColor(.white)
    }

    private var breakdownCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "How the number is built",
                                   subtitle: "Income minus commitments, goals and buffer")
                row("Monthly income", storage.profile.totalMonthlyIncome, VaultTheme.green)
                row("Fixed bills", -safe.fixedCommitments, VaultTheme.red)
                row("Savings target", -safe.goalContributions, VaultTheme.blue)
                row("Safety buffer (\(Int(safetyBuffer))%)", -safe.safetyBuffer, VaultTheme.orange)
                Divider()
                HStack {
                    Text("Discretionary this month").font(.subheadline).bold()
                    Spacer()
                    Text(WealthLabEngine.formatted(safe.monthlyDiscretionary, currency: storage.profile.currency))
                        .font(.subheadline).bold()
                }
                HStack {
                    Text("Days left in month").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("\(safe.daysLeftInMonth) days").font(.caption).bold()
                }
                HStack {
                    Text("Spent so far this month").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(WealthLabEngine.formatted(monthSpent, currency: storage.profile.currency))
                        .font(.caption).bold()
                }
            }
        }
    }

    private var bufferCard: some View {
        VaultCard(tint: VaultTheme.orange) {
            VStack(alignment: .leading, spacing: 8) {
                VaultSectionHeader(title: "Safety buffer",
                                   subtitle: "Protect against surprises before deciding what is spendable")
                HStack {
                    Text("\(Int(safetyBuffer))% of income").font(.caption).bold()
                    Spacer()
                    Text(WealthLabEngine.formatted(safe.safetyBuffer, currency: storage.profile.currency))
                        .font(.caption).foregroundColor(.secondary)
                }
                Slider(value: $safetyBuffer, in: 0...30, step: 1)
                Text("A bigger buffer lowers the daily allowance but makes the plan more resilient.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var projectionCard: some View {
        let projected = safe.projectedSavings
        return VaultCard(tint: VaultTheme.green) {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "If the month ended today",
                                   subtitle: "Projected savings from this month's income")
                Text(WealthLabEngine.formatted(projected, currency: storage.profile.currency))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(VaultTheme.green)
                Text("Income minus fixed bills minus spending so far. Savings transfers and goal contributions still apply separately.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var actionCard: some View {
        VStack(spacing: 10) {
            VaultPrimaryButton(title: "Log a spend now", icon: "plus.circle.fill") {
                showingSpend = true
            }
            LabCallout(icon: "lightbulb.fill", title: "Make it automatic",
                       message: "Add an automation rule that flags you when safe-to-spend drops below your comfort level.",
                       tint: VaultTheme.purple)
        }
    }

    private func row(_ label: String, _ amount: Double, _ tint: Color) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 7, height: 7)
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text((amount >= 0 ? "+" : "−") + WealthLabEngine.formatted(abs(amount), currency: storage.profile.currency))
                .font(.caption).bold()
                .foregroundColor(amount >= 0 ? VaultTheme.green : VaultTheme.red)
        }
    }
}

// MARK: - Quick spend sheet

struct AddLabSpendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var title = ""
    @State private var amount = ""
    @State private var category: CategoryType = .wants

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What was it?", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Label(type.localized, systemImage: type.iconName).tag(type)
                        }
                    }
                } header: {
                    Text("Log spending")
                } footer: {
                    Text("This instantly updates today's safe-to-spend number.")
                }
                Section {
                    Button("Save spend") { save() }
                        .frame(maxWidth: .infinity)
                        .disabled(Double(amount) == nil)
                }
            }
            .navigationTitle("New Spend")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard let value = Double(amount), value > 0 else { return }
        storage.transactions.append(
            Transaction(title: title.isEmpty ? "Quick spend" : title,
                        amount: value, categoryId: UUID(), category: category,
                        date: Date(), notes: "Logged from safe-to-spend")
        )
        storage.recordSpending(date: Date(), amount: value, category: category,
                               notes: title.isEmpty ? "Quick spend" : title)
        storage.save()
        dismiss()
    }
}
