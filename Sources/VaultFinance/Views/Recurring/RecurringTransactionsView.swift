import SwiftUI

// MARK: - Recurring Transactions
// Automate repeat income and bills. Toggle activity, project monthly totals,
// and see the next occurrence at a glance.

struct RecurringTransactionsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAdd = false

    private var items: [RecurringTransaction] {
        storage.recurringTransactions.sorted { $0.nextDate < $1.nextDate }
    }

    private var monthlyOutflow: Double {
        items.filter { $0.isActive }.reduce(0) { $0 + monthlyEquivalent($1) }
    }

    private var activeCount: Int { items.filter { $0.isActive }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if items.isEmpty {
                    VaultEmptyState(icon: "arrow.clockwise.circle",
                                    title: "No recurring items",
                                    message: "Add rent, salary, or subscriptions to automate them.",
                                    actionTitle: "Add Recurring") { showingAdd = true }
                } else {
                    ForEach(items) { item in
                        RecurringRow(item: item) {
                            toggle(item)
                        } onDelete: {
                            storage.recurringTransactions.removeAll { $0.id == item.id }
                            storage.save()
                        }
                    }
                    timelineCard
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Recurring")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddRecurringSheet { item in
                storage.recurringTransactions.append(item)
                storage.save()
            }
        }
    }

    private var headerCard: some View {
        VaultGradientCard(gradient: VaultTheme.brandGradient) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly recurring").font(.caption).opacity(0.9)
                    Text(Money(amount: monthlyOutflow, currency: storage.profile.currency).formatted())
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("\(activeCount) active of \(items.count)").font(.caption2).opacity(0.85)
                }
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 34)).foregroundColor(.white.opacity(0.85))
            }
        }
    }

    private var timelineCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Upcoming", subtitle: "Next 30 days")
                ForEach(items.filter { $0.isActive && $0.nextDate < Date().addingTimeInterval(86400 * 30) }) { item in
                    HStack(spacing: 10) {
                        Circle().fill(VaultTheme.blue).frame(width: 6, height: 6)
                        Text(item.title).font(.caption)
                        Spacer()
                        Text(item.nextDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2).foregroundColor(.secondary)
                        Text(Money(amount: item.amount).formatted())
                            .font(.caption2).bold()
                    }
                }
            }
        }
    }

    private func toggle(_ item: RecurringTransaction) {
        guard let index = storage.recurringTransactions.firstIndex(where: { $0.id == item.id }) else { return }
        storage.recurringTransactions[index].isActive.toggle()
        storage.save()
    }

    private func monthlyEquivalent(_ item: RecurringTransaction) -> Double {
        switch item.frequency {
        case .weekly: return item.amount * 52 / 12
        case .biWeekly: return item.amount * 26 / 12
        case .monthly: return item.amount
        case .quarterly: return item.amount / 3
        case .yearly: return item.amount / 12
        }
    }
}

// MARK: - Row

struct RecurringRow: View {
    let item: RecurringTransaction
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VaultCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(VaultTheme.tint(for: item.category.color).opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.category.iconName)
                        .font(.caption)
                        .foregroundColor(VaultTheme.tint(for: item.category.color))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.subheadline).bold()
                    Text("\(item.frequency.localized) · next \(item.nextDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption2).foregroundColor(.secondary)
                    if item.autoRecord {
                        Text("Auto-record on").font(.caption2).foregroundColor(VaultTheme.green)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(Money(amount: item.amount).formatted())
                        .font(.subheadline).bold()
                    Toggle("", isOn: Binding(get: { item.isActive }, set: { _ in onToggle() }))
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
            .opacity(item.isActive ? 1 : 0.5)
            .contextMenu {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Add Sheet

struct AddRecurringSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (RecurringTransaction) -> Void

    @State private var title = ""
    @State private var amount = ""
    @State private var category: CategoryType = .needsVariable
    @State private var frequency: BillFrequency = .monthly
    @State private var nextDate = Date()
    @State private var autoRecord = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(CategoryType.allCases, id: \.self) {
                            Text($0.localized).tag($0)
                        }
                    }
                }
                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(BillFrequency.allCases, id: \.self) {
                            Text($0.localized).tag($0)
                        }
                    }
                    DatePicker("Next date", selection: $nextDate,
                               displayedComponents: .date)
                    Toggle("Auto-record transactions", isOn: $autoRecord)
                }
            }
            .navigationTitle("New Recurring")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(RecurringTransaction(
                            title: title.isEmpty ? "Recurring item" : title,
                            amount: Double(amount) ?? 0,
                            category: category,
                            frequency: frequency,
                            nextDate: nextDate,
                            autoRecord: autoRecord
                        ))
                        dismiss()
                    }
                    .bold()
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
}
