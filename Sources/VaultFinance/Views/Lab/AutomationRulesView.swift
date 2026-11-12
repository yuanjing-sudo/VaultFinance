import SwiftUI

// MARK: - Automation Rules

struct AutomationRulesView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingEditor = false
    @State private var editingRule: AutomationRule?
    @State private var lastRunCount: Int?

    private var enabledCount: Int {
        storage.automationRules.filter { $0.isEnabled }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                runCard
                rulesCard
                runHistoryCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Automation")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingRule = nil
                    showingEditor = true
                } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingEditor) {
            AutomationRuleEditor(rule: editingRule)
        }
    }

    private var hero: some View {
        LabHeroCard(
            eyebrow: "Automation",
            title: "\(enabledCount) rule\(enabledCount == 1 ? "" : "s") working for you",
            subtitle: "Turn budget signals into savings actions, reminders and piggy deposits.",
            icon: "gearshape.2.fill",
            gradient: VaultTheme.savingsGradient
        )
    }

    private var runCard: some View {
        VaultCard(tint: VaultTheme.green) {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Run the rules",
                                   subtitle: "Actions are applied to your vault immediately")
                Text("Rules only fire when their trigger condition is true right now. Running repeatedly can stack actions, so review them first.")
                    .font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                VaultPrimaryButton(title: "Run now", icon: "play.fill",
                                   gradient: VaultTheme.savingsGradient) {
                    lastRunCount = storage.runAutomationRules()
                }
                if let lastRunCount {
                    Text(lastRunCount == 0
                         ? "No rules matched right now."
                         : "\(lastRunCount) rule(s) fired and updated your vault.")
                        .font(.caption).bold()
                        .foregroundColor(lastRunCount == 0 ? VaultTheme.orange : VaultTheme.green)
                }
            }
        }
    }

    private var rulesCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Your rules",
                                   subtitle: storage.automationRules.isEmpty ? "Start with a simple surplus-to-piggy rule" : "Tap a rule to edit")
                if storage.automationRules.isEmpty {
                    VaultEmptyState(icon: "gearshape.2.fill", title: "No automation yet",
                                    message: "Create a rule that moves surplus into savings.",
                                    actionTitle: "Create rule") {
                        editingRule = nil
                        showingEditor = true
                    }
                } else {
                    ForEach(storage.automationRules) { rule in
                        ruleRow(rule)
                        if rule.id != storage.automationRules.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func ruleRow(_ rule: AutomationRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: rule.trigger.icon)
                    .foregroundColor(VaultTheme.blue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(rule.name).font(.subheadline).bold()
                    Text("\(rule.trigger.rawValue) → \(rule.action.rawValue)")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: enabledBinding(for: rule))
                    .labelsHidden()
                    .tint(VaultTheme.green)
            }
            HStack(spacing: 7) {
                if rule.amount > 0 {
                    VaultPill(text: WealthLabEngine.formatted(rule.amount, currency: storage.profile.currency),
                              icon: "banknote", color: VaultTheme.green)
                }
                if rule.threshold > 0 {
                    VaultPill(text: "≥ \(WealthLabEngine.formatted(rule.threshold, currency: storage.profile.currency))",
                              icon: "greaterthan", color: VaultTheme.orange)
                }
                if let category = rule.category {
                    VaultPill(text: category.localized, icon: category.iconName, color: VaultTheme.purple)
                }
                Spacer()
            }
            if !rule.notes.isEmpty {
                Text(rule.notes).font(.caption2).foregroundColor(.secondary)
            }
            HStack {
                Text(rule.lastRun.map { "Last run \($0.formatted(.relative(presentation: .named)))" } ?? "Never run")
                    .font(.caption2).foregroundColor(.secondary)
                Spacer()
                Button("Edit") {
                    editingRule = rule
                    showingEditor = true
                }
                .font(.caption2).bold()
                Button("Delete") { delete(rule) }
                    .font(.caption2).bold()
                    .foregroundColor(VaultTheme.red)
            }
        }
        .padding(.vertical, 4)
    }

    private var runHistoryCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Recent runs",
                                   subtitle: "\(storage.automationRuns.count) event(s) logged")
                if storage.automationRuns.isEmpty {
                    Text("Run a rule to see its history here.")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(storage.automationRuns.prefix(12)) { run in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2).foregroundColor(VaultTheme.gold)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(run.ruleName).font(.caption).bold()
                                Text(run.detail).font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                if run.amount > 0 {
                                    Text(WealthLabEngine.formatted(run.amount, currency: storage.profile.currency))
                                        .font(.caption2).bold().foregroundColor(VaultTheme.green)
                                }
                                Text(run.date.formatted(.relative(presentation: .named)))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    private func enabledBinding(for rule: AutomationRule) -> Binding<Bool> {
        Binding(
            get: { storage.automationRules.first(where: { $0.id == rule.id })?.isEnabled ?? false },
            set: { newValue in
                if let index = storage.automationRules.firstIndex(where: { $0.id == rule.id }) {
                    storage.automationRules[index].isEnabled = newValue
                    storage.save()
                }
            }
        )
    }

    private func delete(_ rule: AutomationRule) {
        storage.automationRules.removeAll { $0.id == rule.id }
        storage.save()
    }
}

// MARK: - Rule editor

struct AutomationRuleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    private let existing: AutomationRule?

    @State private var name: String
    @State private var trigger: AutomationTrigger
    @State private var action: AutomationAction
    @State private var amount: String
    @State private var threshold: String
    @State private var includeCategory: Bool
    @State private var category: CategoryType
    @State private var notes: String

    init(rule: AutomationRule?) {
        existing = rule
        _name = State(initialValue: rule?.name ?? "")
        _trigger = State(initialValue: rule?.trigger ?? .budgetSurplus)
        _action = State(initialValue: rule?.action ?? .feedPiggy)
        _amount = State(initialValue: rule.map { String($0.amount) } ?? "25")
        _threshold = State(initialValue: rule.map { String($0.threshold) } ?? "50")
        _includeCategory = State(initialValue: rule?.category != nil)
        _category = State(initialValue: rule?.category ?? .wants)
        _notes = State(initialValue: rule?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Rule name", text: $name)
                    Picker("When", selection: $trigger) {
                        ForEach(AutomationTrigger.allCases) { item in
                            Label(item.rawValue, systemImage: item.icon).tag(item)
                        }
                    }
                    Picker("Then", selection: $action) {
                        ForEach(AutomationAction.allCases) { item in
                            Label(item.rawValue, systemImage: item.icon).tag(item)
                        }
                    }
                } header: { Text("Rule") }

                Section {
                    TextField("Amount", text: $amount).keyboardType(.decimalPad)
                    TextField("Threshold", text: $threshold).keyboardType(.decimalPad)
                    Text("Threshold applies to surplus, overspend, category spend, or safe-to-spend depending on the trigger.")
                        .font(.caption2).foregroundColor(.secondary)
                } header: { Text("Money") }

                Section {
                    Toggle("Only one category", isOn: $includeCategory)
                    if includeCategory {
                        Picker("Category", selection: $category) {
                            ForEach(CategoryType.allCases, id: \.self) { type in
                                Text(type.localized).tag(type)
                            }
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: { Text("Scope") }

                Section {
                    Button(existing == nil ? "Create rule" : "Save changes") { save() }
                        .frame(maxWidth: .infinity)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle(existing == nil ? "New Rule" : "Edit Rule")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let rule = AutomationRule(
            id: existing?.id ?? UUID(),
            name: trimmed,
            trigger: trigger,
            action: action,
            amount: Double(amount) ?? 0,
            threshold: Double(threshold) ?? 0,
            category: includeCategory ? category : nil,
            isEnabled: existing?.isEnabled ?? true,
            lastRun: existing?.lastRun,
            runCount: existing?.runCount ?? 0,
            notes: notes
        )
        if let index = storage.automationRules.firstIndex(where: { $0.id == rule.id }) {
            storage.automationRules[index] = rule
        } else {
            storage.automationRules.append(rule)
        }
        storage.save()
        dismiss()
    }
}
