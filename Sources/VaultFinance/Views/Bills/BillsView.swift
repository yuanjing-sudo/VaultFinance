import SwiftUI

// MARK: - Bills View

/// Tracks upcoming bills, due dates, and overdue status.
struct BillsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAddBill = false

    var upcomingBills: [Bill] {
        storage.bills.filter { $0.status != .paid }
    }

    var paidBills: [Bill] {
        storage.bills.filter { $0.status == .paid }
    }

    var overdueBills: [Bill] {
        storage.bills.filter { $0.status == .overdue }
    }

    var totalUpcoming: Double {
        upcomingBills.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary cards
                HStack(spacing: 10) {
                    BillStatCard(title: "Upcoming", value: "\(upcomingBills.count)", amount: totalUpcoming, color: .blue)
                    BillStatCard(title: "Overdue", value: "\(overdueBills.count)", amount: overdueBills.reduce(0) { $0 + $1.amount }, color: .red)
                    BillStatCard(title: "Paid This Month", value: "\(paidBills.count)", amount: paidBills.reduce(0) { $0 + $1.paidAmount }, color: .green)
                }

                // Overdue section
                if !overdueBills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("⚠️ Overdue Bills").font(.headline).bold()
                            Spacer()
                        }
                        ForEach(overdueBills) { bill in
                            BillRow(bill: bill, onPay: { markPaid(bill) })
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 1))
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(14)
                }

                // Upcoming bills list
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Upcoming Bills").font(.headline).bold()
                        Spacer()
                        Button("Add Bill") { showingAddBill = true }
                            .font(.caption).foregroundColor(.blue)
                    }
                    if upcomingBills.isEmpty {
                        EmptyState(message: "No upcoming bills. Add your first bill.")
                    } else {
                        ForEach(upcomingBills.sorted { $0.nextDueDate < $1.nextDueDate }) { bill in
                            BillRow(bill: bill, onPay: { markPaid(bill) })
                        }
                    }
                }

                // Paid bills
                if !paidBills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recently Paid").font(.headline).bold()
                            Spacer()
                        }
                        ForEach(paidBills.suffix(5).reversed()) { bill in
                            BillRow(bill: bill, onPay: {})
                                .opacity(0.6)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Bills")
        .inlineNavigationTitle()
        .sheet(isPresented: $showingAddBill) {
            AddBillView()
        }
    }

    private func markPaid(_ bill: Bill) {
        if let index = storage.bills.firstIndex(where: { $0.id == bill.id }) {
            storage.bills[index].status = .paid
            storage.bills[index].paidAmount = storage.bills[index].amount
            storage.bills[index].lastPaidDate = Date()
            // Record as spending
            storage.recordSpending(date: Date(), amount: bill.amount, category: .needsFixed, notes: "Bill: \(bill.title)")
            storage.save()
        }
    }
}

// MARK: - Bill Stat Card

struct BillStatCard: View {
    let title: String
    let value: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline).bold()
                Spacer()
                Text(value).font(.subheadline).bold().foregroundColor(color)
            }
            Text(Money(amount: amount).formatted()).font(.title2).bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(14)
    }
}

// MARK: - Bill Row

struct BillRow: View {
    let bill: Bill
    let onPay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bill.isDueSoon ? "exclamationmark.circle.fill" : "doc.fill")
                .foregroundColor(bill.status == .overdue ? .red : (bill.isDueSoon ? .orange : .blue))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(bill.title).font(.subheadline).bold()
                HStack(spacing: 6) {
                    Text(bill.category).font(.caption2).foregroundColor(.secondary)
                    Text("• \(bill.frequency.localized)").font(.caption2).foregroundColor(.secondary)
                    if bill.autoPay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2).foregroundColor(.green)
                    }
                }
                Text(bill.nextDueDate, style: .date)
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("-\(Money(amount: bill.amount).formatted())")
                    .font(.subheadline).bold()
                if bill.isOverdue {
                    Text("OVERDUE").font(.caption2).bold().foregroundColor(.red)
                } else if bill.isDueSoon {
                    Text("Due in \(bill.daysUntilDue) days").font(.caption2).foregroundColor(.orange)
                } else {
                    Text("Upcoming").font(.caption2).foregroundColor(.secondary)
                }
            }

            if bill.status != .paid {
                Button(action: onPay) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Add Bill View

struct AddBillView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var title = ""
    @State private var amount: String = ""
    @State private var frequency: BillFrequency = .monthly
    @State private var dueDate = Date()
    @State private var category = "Bills"
    @State private var notes = ""
    @State private var autoPay = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bill Details")) {
                    TextField("Title (e.g. Electricity)", text: $title)
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        Text(storage.profile.currency).font(.caption).foregroundColor(.secondary)
                    }
                    Picker("Frequency", selection: $frequency) {
                        ForEach(BillFrequency.allCases, id: \.self) { f in
                            Text(f.localized).tag(f)
                        }
                    }
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    TextField("Category", text: $category)
                    TextField("Notes", text: $notes)
                    Toggle("Auto Pay", isOn: $autoPay)
                }
                Section {
                    Button("Add Bill") {
                        guard let amt = Double(amount), amt > 0, !title.isEmpty else { return }
                        let bill = Bill(title: title, amount: amt, frequency: frequency,
                                        nextDueDate: dueDate, status: .upcoming,
                                        category: category, notes: notes, autoPay: autoPay)
                        storage.bills.append(bill)
                        storage.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Add Bill")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
