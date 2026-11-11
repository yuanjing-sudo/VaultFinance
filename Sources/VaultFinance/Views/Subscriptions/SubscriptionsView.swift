import SwiftUI

// MARK: - Subscriptions View

/// Tracks recurring subscriptions, billing cycles, and annualized costs.
struct SubscriptionsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAddSubscription = false

    var activeSubscriptions: [Subscription] {
        storage.subscriptions.filter { $0.isActive }
    }

    var totalMonthly: Double {
        activeSubscriptions.reduce(0) { $0 + $1.amount }
    }

    var totalAnnual: Double {
        activeSubscriptions.reduce(0) { $0 + $1.annualizedCost }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary cards
                HStack(spacing: 10) {
                    SubStatCard(title: "Active", value: "\(activeSubscriptions.count)", color: .blue)
                    SubStatCard(title: "Monthly", value: Money(amount: totalMonthly).formatted(), color: .green)
                    SubStatCard(title: "Annual", value: Money(amount: totalAnnual).formatted(), color: .orange)
                }

                // Upcoming billing
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Upcoming Billing").font(.headline).bold()
                        Spacer()
                        Button("Add Subscription") { showingAddSubscription = true }
                            .font(.caption).foregroundColor(.blue)
                    }
                    if activeSubscriptions.isEmpty {
                        EmptyState(message: "No subscriptions tracked. Add your first one.")
                    } else {
                        ForEach(activeSubscriptions.sorted { $0.nextBillingDate < $1.nextBillingDate }) { sub in
                            SubscriptionRow(sub: sub)
                        }
                    }
                }

                // Cancellation candidates (expensive subscriptions)
                if !activeSubscriptions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review & Cancel").font(.headline).bold()
                        Text("Consider cancelling unused subscriptions to save money.")
                            .font(.caption).foregroundColor(.secondary)
                        ForEach(activeSubscriptions.sorted { $0.annualizedCost > $1.annualizedCost }.prefix(3)) { sub in
                            SubscriptionRow(sub: sub, showCancel: true)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView()
        }
    }
}

// MARK: - Sub Stat Card

struct SubStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).bold()
            Spacer()
            Text(value).font(.title2).bold().foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

// MARK: - Subscription Row

struct SubscriptionRow: View {
    let sub: Subscription
    var showCancel: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "eyes")
                .foregroundColor(.purple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(sub.title).font(.subheadline).bold()
                HStack(spacing: 6) {
                    Text(sub.category).font(.caption2).foregroundColor(.secondary)
                    Text("• \(sub.cycle.localized)").font(.caption2).foregroundColor(.secondary)
                }
                Text(sub.nextBillingDate, style: .date)
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("-\(Money(amount: sub.amount).formatted())")
                    .font(.subheadline).bold()
                Text("\(Money(amount: sub.annualizedCost).formatted())/year")
                    .font(.caption2).foregroundColor(.secondary)
            }

            if showCancel {
                Button(action: {}) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Add Subscription View

struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var title = ""
    @State private var amount: String = ""
    @State private var cycle: SubscriptionBillingCycle = .monthly
    @State private var nextBillingDate = Date()
    @State private var category = "Subscriptions"
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Subscription Details")) {
                    TextField("Title (e.g. Netflix)", text: $title)
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        Text(storage.profile.currency).font(.caption).foregroundColor(.secondary)
                    }
                    Picker("Billing Cycle", selection: $cycle) {
                        ForEach(SubscriptionBillingCycle.allCases, id: \.self) { c in
                            Text(c.localized).tag(c)
                        }
                    }
                    DatePicker("Next Billing Date", selection: $nextBillingDate, displayedComponents: .date)
                    TextField("Category", text: $category)
                    TextField("Notes", text: $notes)
                }
                Section {
                    Button("Add Subscription") {
                        guard let amt = Double(amount), amt > 0, !title.isEmpty else { return }
                        let sub = Subscription(title: title, amount: amt, cycle: cycle,
                                               nextBillingDate: nextBillingDate,
                                               category: category, notes: notes)
                        storage.subscriptions.append(sub)
                        storage.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
