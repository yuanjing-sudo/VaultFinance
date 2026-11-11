import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Data Export
// Build a portable CSV of your vault and share or copy it.

struct ExportView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var includeTransactions = true
    @State private var includeGoals = true
    @State private var includeBills = true
    @State private var includeSubscriptions = true
    @State private var copied = false

    private var csv: String {
        var lines = ["type,title,category,date,amount,notes"]
        if includeTransactions {
            for tx in storage.transactions {
                lines.append(csvLine(type: "transaction",
                                     title: tx.title,
                                     category: tx.category.localized,
                                     date: tx.date,
                                     amount: tx.amount,
                                     notes: tx.notes))
            }
        }
        if includeGoals {
            for goal in storage.goals {
                lines.append(csvLine(type: "goal",
                                     title: goal.title,
                                     category: goal.horizon.localized,
                                     date: goal.targetDate ?? Date(),
                                     amount: goal.targetAmount,
                                     notes: goal.notes))
            }
        }
        if includeBills {
            for bill in storage.bills {
                lines.append(csvLine(type: "bill",
                                     title: bill.title,
                                     category: bill.category,
                                     date: bill.nextDueDate,
                                     amount: bill.amount,
                                     notes: bill.notes))
            }
        }
        if includeSubscriptions {
            for sub in storage.subscriptions {
                lines.append(csvLine(type: "subscription",
                                     title: sub.title,
                                     category: sub.category,
                                     date: sub.nextBillingDate,
                                     amount: sub.amount,
                                     notes: sub.notes))
            }
        }
        return lines.joined(separator: "\n")
    }

    private func csvLine(type: String, title: String, category: String,
                         date: Date, amount: Double, notes: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let safeTitle = title.replacingOccurrences(of: ",", with: " ")
        let safeNotes = notes.replacingOccurrences(of: ",", with: " ")
        return "\(type),\(safeTitle),\(category),\(df.string(from: date)),\(amount),\(safeNotes)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.brandGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export your data").font(.caption).opacity(0.9)
                        Text("\(csv.split(separator: "\n").count) rows")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                        Text("CSV · opens in Numbers, Excel, Sheets").font(.caption2).opacity(0.9)
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: "Include")
                        Toggle("Transactions", isOn: $includeTransactions)
                        Toggle("Goals", isOn: $includeGoals)
                        Toggle("Bills", isOn: $includeBills)
                        Toggle("Subscriptions", isOn: $includeSubscriptions)
                    }
                }

                ShareLink(item: csv) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(VaultTheme.blue.opacity(0.14)))
                        .foregroundColor(VaultTheme.blue)
                }

                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = csv
                    #else
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(csv, forType: .string)
                    #endif
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Label(copied ? "Copied!" : "Copy to Clipboard",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.12)))
                        .foregroundColor(.primary)
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 8) {
                        VaultSectionHeader(title: "Preview")
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(csv)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(10)
                        }
                        .frame(height: 180)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.08)))
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Export")
        .inlineNavigationTitle()
    }
}
