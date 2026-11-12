import SwiftUI

// MARK: - Tax Vault

struct TaxVaultView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingEditor = false
    @State private var editingDocument: TaxDocument?

    private var year: Int { Calendar.current.component(.year, from: Date()) }
    private var deadlines: [TaxDeadline] { WealthLabEngine.taxDeadlines(year: year) }
    private var summary: (income: Double, deductions: Double, filed: Int, total: Int) {
        WealthLabEngine.taxSummary(documents: storage.taxDocuments)
    }
    private var documents: [TaxDocument] {
        storage.taxDocuments.sorted {
            if $0.taxYear != $1.taxYear { return $0.taxYear > $1.taxYear }
            return $0.addedDate > $1.addedDate
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                summaryRow
                deadlinesCard
                documentsCard
                NavigationLink {
                    TaxEstimatorView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "function").foregroundColor(VaultTheme.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open tax estimator").font(.subheadline).bold().foregroundColor(.primary)
                            Text("Estimate federal and state tax from your profile").font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(VaultTheme.purple.opacity(0.10)))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Tax Vault")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingDocument = nil
                    showingEditor = true
                } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingEditor) {
            TaxDocumentEditor(document: editingDocument)
        }
    }

    private var hero: some View {
        LabHeroCard(
            eyebrow: "Tax Vault · \(year)",
            title: "\(summary.filed)/\(summary.total) documents filed",
            subtitle: summary.total == 0
                ? "Add W-2s, 1099s, receipts and deduction records in one place."
                : "Income forms \(WealthLabEngine.formatted(summary.income, currency: storage.profile.currency)) · deductions \(WealthLabEngine.formatted(summary.deductions, currency: storage.profile.currency)).",
            icon: "doc.text.fill",
            gradient: VaultTheme.brandGradient
        )
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            LabStat(label: "Income forms", value: WealthLabEngine.formatted(summary.income, currency: storage.profile.currency),
                    icon: "arrow.down.circle.fill", tint: VaultTheme.green)
            LabStat(label: "Deductions", value: WealthLabEngine.formatted(summary.deductions, currency: storage.profile.currency),
                    icon: "arrow.up.circle.fill", tint: VaultTheme.blue)
        }
    }

    private var deadlinesCard: some View {
        VaultCard(tint: VaultTheme.orange) {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Key dates", subtitle: "Plan ahead, file calmly")
                ForEach(deadlines.sorted { $0.date < $1.date }) { deadline in
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()),
                                                               to: Calendar.current.startOfDay(for: deadline.date)).day ?? 0
                    HStack(spacing: 10) {
                        Image(systemName: deadline.icon)
                            .foregroundColor(VaultTheme.orange)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(deadline.title).font(.caption).bold()
                            Text(deadline.detail).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(deadline.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption).bold()
                            Text(days < 0 ? "Passed" : days == 0 ? "Today" : "in \(days)d")
                                .font(.caption2)
                                .foregroundColor(days < 0 ? .secondary : days <= 14 ? VaultTheme.red : VaultTheme.green)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var documentsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Documents & records",
                                   subtitle: "\(documents.count) item(s) in the vault")
                if documents.isEmpty {
                    VaultEmptyState(icon: "doc.badge.plus", title: "Your tax vault is empty",
                                    message: "Add forms and receipts so nothing gets lost.",
                                    actionTitle: "Add document") {
                        editingDocument = nil
                        showingEditor = true
                    }
                } else {
                    ForEach(documents) { document in
                        Button {
                            editingDocument = document
                            showingEditor = true
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(VaultTheme.tint(for: document.kind.tint).opacity(0.14))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: document.kind.icon)
                                        .font(.caption).foregroundColor(VaultTheme.tint(for: document.kind.tint))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(document.title).font(.caption).bold().foregroundColor(.primary)
                                    Text("\(document.kind.rawValue) · \(String(document.taxYear))")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(WealthLabEngine.formatted(document.amount, currency: storage.profile.currency))
                                        .font(.caption).bold().foregroundColor(.primary)
                                    Label(document.isFiled ? "Filed" : "Pending",
                                          systemImage: document.isFiled ? "checkmark.circle.fill" : "clock")
                                        .font(.caption2)
                                        .foregroundColor(document.isFiled ? VaultTheme.green : VaultTheme.orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        if document.id != documents.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: - Tax document editor

struct TaxDocumentEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    private let existing: TaxDocument?
    @State private var title: String
    @State private var kind: TaxDocumentKind
    @State private var taxYear: Int
    @State private var amount: String
    @State private var dueDate: Date
    @State private var isFiled: Bool
    @State private var notes: String

    init(document: TaxDocument?) {
        existing = document
        _title = State(initialValue: document?.title ?? "")
        _kind = State(initialValue: document?.kind ?? .w2)
        _taxYear = State(initialValue: document?.taxYear ?? Calendar.current.component(.year, from: Date()) - 1)
        _amount = State(initialValue: document.map { String($0.amount) } ?? "")
        _dueDate = State(initialValue: document?.dueDate ?? Date())
        _isFiled = State(initialValue: document?.isFiled ?? false)
        _notes = State(initialValue: document?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    Picker("Kind", selection: $kind) {
                        ForEach(TaxDocumentKind.allCases) { item in
                            Label(item.rawValue, systemImage: item.icon).tag(item)
                        }
                    }
                    Picker("Tax year", selection: $taxYear) {
                        ForEach((Calendar.current.component(.year, from: Date()) - 5)...Calendar.current.component(.year, from: Date()), id: \.self) {
                            Text(String($0)).tag($0)
                        }
                    }
                    TextField("Amount", text: $amount).keyboardType(.decimalPad)
                } header: { Text("Document") }
                Section {
                    Toggle("Filed", isOn: $isFiled)
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4)
                } header: { Text("Status") }
                Section {
                    Button(existing == nil ? "Add document" : "Save changes") { save() }
                        .frame(maxWidth: .infinity)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    if existing != nil {
                        Button("Delete document", role: .destructive) { delete() }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Document" : "Edit Document")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let doc = TaxDocument(id: existing?.id ?? UUID(),
                              title: title.trimmingCharacters(in: .whitespaces),
                              kind: kind, taxYear: taxYear,
                              amount: Double(amount) ?? 0,
                              addedDate: existing?.addedDate ?? Date(),
                              dueDate: dueDate, isFiled: isFiled, notes: notes)
        if let index = storage.taxDocuments.firstIndex(where: { $0.id == doc.id }) {
            storage.taxDocuments[index] = doc
        } else {
            storage.taxDocuments.append(doc)
        }
        storage.save()
        dismiss()
    }

    private func delete() {
        guard let existing else { return }
        storage.taxDocuments.removeAll { $0.id == existing.id }
        storage.save()
        dismiss()
    }
}
