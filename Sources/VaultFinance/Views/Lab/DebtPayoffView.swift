import SwiftUI

// MARK: - Debt Payoff Planner

struct DebtPayoffView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var strategy: PayoffStrategy = .avalanche
    @State private var extraPayment: Double = 100
    @State private var showingAdd = false

    private var accounts: [DebtAccountInput] {
        storage.liabilities
            .filter { $0.balance > 0 }
            .map { DebtAccountInput(title: $0.title, balance: $0.balance,
                                    apr: $0.interestRate, minPayment: $0.monthlyPayment) }
    }

    private var totalDebt: Double { accounts.reduce(0) { $0 + $1.balance } }
    private var totalMinimums: Double { accounts.reduce(0) { $0 + $1.minPayment } }
    private var weightedAPR: Double {
        guard totalDebt > 0 else { return 0 }
        return accounts.reduce(0) { $0 + $1.apr * $1.balance } / totalDebt
    }

    private var plan: PayoffSummary {
        WealthLabEngine.payoff(accounts: accounts, extraPayment: extraPayment, strategy: strategy)
    }

    private var baseline: PayoffSummary {
        WealthLabEngine.payoff(accounts: accounts, extraPayment: 0, strategy: .minimum)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if accounts.isEmpty {
                    emptyState
                } else {
                    strategyCard
                    comparisonGrid
                    payoffCard
                    accountList
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Debt Payoff")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingAdd) { AddDebtView() }
    }

    private var hero: some View {
        LabHeroCard(
            eyebrow: "Debt Payoff",
            title: totalDebt > 0 ? WealthLabEngine.formatted(totalDebt, currency: storage.profile.currency) : "Debt free",
            subtitle: accounts.isEmpty
                ? "Add a debt to build a payoff plan."
                : "\(accounts.count) account(s) · \(WealthLabEngine.percent(weightedAPR)) average APR · \(WealthLabEngine.formatted(totalMinimums)) minimums",
            icon: "mountain.2.fill",
            gradient: totalDebt > 0 ? VaultTheme.warningGradient : VaultTheme.savingsGradient
        )
    }

    private var strategyCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Choose a strategy",
                                   subtitle: "Every extra dollar attacks one debt at a time")
                Picker("Strategy", selection: $strategy) {
                    ForEach(PayoffStrategy.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                Text(strategy.detail).font(.caption).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Extra payment").font(.caption).bold()
                        Spacer()
                        Text("\(WealthLabEngine.formatted(extraPayment, currency: storage.profile.currency))/mo")
                            .font(.caption).bold().foregroundColor(VaultTheme.blue)
                    }
                    Slider(value: $extraPayment, in: 0...500, step: 25)
                }
            }
        }
    }

    private var comparisonGrid: some View {
        let fastest = strategy == .avalanche
        let saved = max(baseline.totalInterest - plan.totalInterest, 0)
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                LabStat(label: "Debt-free in", value: plan.yearsText, icon: "calendar", tint: VaultTheme.green)
                LabStat(label: "Total interest", value: WealthLabEngine.formatted(plan.totalInterest, currency: storage.profile.currency),
                        icon: "percent", tint: VaultTheme.red)
            }
            HStack(spacing: 10) {
                LabStat(label: "Interest saved", value: WealthLabEngine.formatted(saved, currency: storage.profile.currency),
                        icon: "arrow.down.circle.fill", tint: VaultTheme.gold)
                LabStat(label: "Debt-free date",
                        value: plan.debtFreeDate.formatted(.dateTime.month(.abbreviated).year()),
                        icon: "flag.checkered", tint: VaultTheme.blue)
            }
            if !accounts.isEmpty {
                LabCallout(icon: fastest ? "snowflake" : "mountain.2.fill",
                           title: strategy == .avalanche ? "Avalanche usually costs least" : "Snowball builds momentum",
                           message: "\(strategy.rawValue) clears debt in \(plan.yearsText). Baseline minimum-only takes \(baseline.yearsText) and costs \(WealthLabEngine.formatted(baseline.totalInterest, currency: storage.profile.currency)) in interest.",
                           tint: VaultTheme.purple)
            }
        }
    }

    private var payoffCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Payoff order", subtitle: "The order your plan clears accounts")
                if plan.payoffOrder.isEmpty {
                    Text("Add accounts to see the order.").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(Array(plan.payoffOrder.enumerated()), id: \.offset) { index, title in
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption2).bold()
                                .frame(width: 22, height: 22)
                                .background(VaultTheme.blue.opacity(0.15))
                                .foregroundColor(VaultTheme.blue)
                                .clipShape(Circle())
                            Text(title).font(.caption)
                            Spacer()
                            Image(systemName: index == 0 ? "target" : "checkmark")
                                .font(.caption2).foregroundColor(index == 0 ? VaultTheme.orange : .secondary)
                        }
                    }
                }
                Text("Simulation assumes rates and payments stay constant. Use it as a planning guide, not a guarantee.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var accountList: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Accounts")
                ForEach(storage.liabilities.filter { $0.balance > 0 }) { liability in
                    HStack(spacing: 10) {
                        Image(systemName: liability.type == .creditCard ? "creditcard.fill" : "banknote.fill")
                            .foregroundColor(VaultTheme.red)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(liability.title).font(.caption).bold()
                            Text("\(WealthLabEngine.percent(liability.interestRate)) APR · \(WealthLabEngine.formatted(liability.monthlyPayment, currency: storage.profile.currency))/mo minimum")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(WealthLabEngine.formatted(liability.balance, currency: storage.profile.currency))
                            .font(.subheadline).bold()
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var emptyState: some View {
        VaultCard {
            VaultEmptyState(icon: "checkmark.seal.fill", title: "No debts tracked",
                            message: "Add a loan or credit card to compare snowball and avalanche plans.",
                            actionTitle: "Add debt") { showingAdd = true }
        }
    }
}

// MARK: - Add debt

struct AddDebtView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var title = ""
    @State private var balance = ""
    @State private var apr = ""
    @State private var minimum = ""
    @State private var type: Liability.LiabilityType = .creditCard

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(Liability.LiabilityType.allCases, id: \.self) { type in
                            Text(type.localized).tag(type)
                        }
                    }
                    TextField("Balance", text: $balance).keyboardType(.decimalPad)
                    TextField("APR %", text: $apr).keyboardType(.decimalPad)
                    TextField("Minimum payment", text: $minimum).keyboardType(.decimalPad)
                } header: { Text("Debt details") }
                Section {
                    Button("Add debt") { save() }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Debt")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let value = Double(balance) ?? 0
        guard value > 0 else { return }
        storage.liabilities.append(
            Liability(title: title.isEmpty ? "New debt" : title, type: type,
                      balance: value, interestRate: Double(apr) ?? 0,
                      monthlyPayment: Double(minimum) ?? max(value * 0.03, 25))
        )
        storage.save()
        dismiss()
    }
}
