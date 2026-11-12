import SwiftUI
import UniformTypeIdentifiers

// MARK: - Statement / CSV Import

struct StatementImportView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var csv = ""
    @State private var showingImporter = false
    @State private var message = ""
    @State private var showingMessage = false

    private var parsed: [ImportedTransaction] {
        guard !csv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return WealthLabEngine.markDuplicates(
            imported: WealthLabEngine.parseStatementCSV(csv, currency: storage.profile.currency),
            existing: storage.transactions
        )
    }

    private var duplicates: Int { parsed.filter { $0.isDuplicate }.count }
    private var importable: [ImportedTransaction] { parsed.filter { !$0.isDuplicate } }
    private var total: Double { importable.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabHeroCard(
                    eyebrow: "Statement Import",
                    title: parsed.isEmpty ? "Bring your spending in" : "\(importable.count) ready to import",
                    subtitle: parsed.isEmpty
                        ? "Paste a CSV export or choose a file. Categories and duplicates are handled automatically."
                        : "\(WealthLabEngine.formatted(total, currency: storage.profile.currency)) across \(importable.count) transaction(s); \(duplicates) duplicate(s) skipped.",
                    icon: "square.and.arrow.down.fill",
                    gradient: VaultTheme.skyGradient
                )

                inputCard
                if !parsed.isEmpty { previewCard }
                LabCallout(icon: "tablecells.fill", title: "CSV columns",
                           message: "Headers named date, description (or merchant/payee), amount (or debit), and optionally category are recognized. Plain date,description,amount files also work.",
                           tint: VaultTheme.teal)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Statement Import")
        .inlineNavigationTitle()
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            handleImport(result)
        }
        .alert("Import", isPresented: $showingMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message)
        }
    }

    private var inputCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "CSV input", subtitle: "Nothing leaves this device")
                TextEditor(text: $csv)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 150)
                    .padding(6)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    )
                HStack(spacing: 8) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Choose file", systemImage: "doc.badge.plus")
                            .font(.caption2).bold()
                    }
                    .buttonStyle(.bordered)
                    Button {
                        csv = sampleCSV
                    } label: {
                        Label("Load sample", systemImage: "sparkles")
                            .font(.caption2).bold()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Clear") { csv = "" }
                        .font(.caption2).foregroundColor(.secondary)
                }
                if !importable.isEmpty {
                    VaultPrimaryButton(title: "Import \(importable.count) transaction(s)",
                                       icon: "tray.and.arrow.down.fill",
                                       gradient: VaultTheme.savingsGradient) {
                        importRows()
                    }
                }
            }
        }
    }

    private var previewCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Preview",
                                   subtitle: "Duplicates are matched by date, title and amount")
                ForEach(parsed) { item in
                    HStack(spacing: 9) {
                        Image(systemName: item.category.iconName)
                            .font(.caption2)
                            .foregroundColor(VaultTheme.tint(for: item.category.color))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title).font(.caption).bold()
                            Text("\(item.date.formatted(.dateTime.month(.abbreviated).day().year())) · \(item.category.localized)")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(WealthLabEngine.formatted(item.amount, currency: storage.profile.currency))
                                .font(.caption).bold()
                            if item.isDuplicate {
                                Text("Duplicate").font(.caption2).bold().foregroundColor(VaultTheme.orange)
                            }
                        }
                    }
                    .opacity(item.isDuplicate ? 0.5 : 1)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func importRows() {
        guard !importable.isEmpty else { return }
        for item in importable {
            storage.transactions.append(
                Transaction(title: item.title, amount: item.amount, categoryId: UUID(),
                            category: item.category, date: item.date,
                            notes: "Imported from statement")
            )
            storage.recordSpending(date: item.date, amount: item.amount,
                                   category: item.category, notes: item.title)
        }
        storage.save()
        message = "Imported \(importable.count) transaction(s) worth \(WealthLabEngine.formatted(total, currency: storage.profile.currency))."
        showingMessage = true
        csv = ""
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                if let text = String(data: data, encoding: .utf8) {
                    csv = text
                } else {
                    message = "That file could not be read as UTF-8 text."
                    showingMessage = true
                }
            } catch {
                message = "Could not read the file: \(error.localizedDescription)"
                showingMessage = true
            }
        case .failure(let error):
            message = "Import cancelled: \(error.localizedDescription)"
            showingMessage = true
        }
    }

    private var sampleCSV: String {
        """
        date,description,amount,category
        \(Date().formatted(.iso8601.year().month().day())),Coffee shop,6.50,wants
        \(Date().addingTimeInterval(-86_400).formatted(.iso8601.year().month().day())),Grocery market,84.20,groceries
        \(Date().addingTimeInterval(-172_800).formatted(.iso8601.year().month().day())),Electric bill,95.00,utilities
        \(Date().addingTimeInterval(-259_200).formatted(.iso8601.year().month().day())),Monthly train pass,62.00,transport
        """
    }
}
