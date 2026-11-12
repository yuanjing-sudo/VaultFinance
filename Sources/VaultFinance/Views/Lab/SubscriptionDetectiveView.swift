import SwiftUI

// MARK: - Subscription Detective

struct SubscriptionDetectiveView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var ignored: Set<String> = []

    private var detected: [DetectedSubscription] {
        WealthLabEngine.detectSubscriptions(transactions: storage.transactions)
            .filter { !ignored.contains($0.title) }
    }

    private var monthlyTotal: Double { detected.reduce(0) { $0 + $1.estimatedMonthly } }
    private var alreadyTracked: Set<String> {
        Set(storage.subscriptions.map { $0.title.lowercased() })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabHeroCard(
                    eyebrow: "Subscription Detective",
                    title: detected.isEmpty ? "No patterns yet" : "\(detected.count) recurring charge(s)",
                    subtitle: detected.isEmpty
                        ? "Log a few months of transactions and repeat charges will surface here."
                        : "About \(WealthLabEngine.formatted(monthlyTotal, currency: storage.profile.currency)) a month hides in your transaction history.",
                    icon: "eyes",
                    gradient: VaultTheme.sunsetGradient
                )

                if !detected.isEmpty {
                    summaryCard
                    detectionList
                } else {
                    VaultCard {
                        VaultEmptyState(icon: "magnifyingglass", title: "Still learning your patterns",
                                        message: "The detective looks for at least two charges from the same merchant, 5–100 days apart, across at least two months.")
                    }
                }

                LabCallout(icon: "lock.shield.fill", title: "Private by design",
                           message: "Detection runs entirely on-device against your local transactions. Nothing is uploaded.",
                           tint: VaultTheme.green)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Subscription Detective")
        .inlineNavigationTitle()
    }

    private var summaryCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                LabStat(label: "Monthly", value: WealthLabEngine.formatted(monthlyTotal, currency: storage.profile.currency),
                        icon: "calendar", tint: VaultTheme.purple)
                LabStat(label: "Annualized", value: WealthLabEngine.formatted(monthlyTotal * 12, currency: storage.profile.currency),
                        icon: "calendar.badge.clock", tint: VaultTheme.orange)
            }
            HStack(spacing: 10) {
                LabStat(label: "Detected", value: "\(detected.count)", icon: "magnifyingglass", tint: VaultTheme.blue)
                LabStat(label: "Price hikes", value: "\(detected.filter { $0.priceHikePercent > 5 }.count)",
                        icon: "arrow.up.right", tint: VaultTheme.red)
            }
        }
    }

    private var detectionList: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Likely subscriptions",
                                   subtitle: "Track one in the subscription list or ignore it")
                ForEach(detected) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 9) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(VaultTheme.purple.opacity(0.13))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.candidateCategory.iconName)
                                    .font(.caption).foregroundColor(VaultTheme.purple)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.caption).bold()
                                Text("\(item.occurrences) charges · last \(item.lastCharge.formatted(.dateTime.month(.abbreviated).day()))")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(WealthLabEngine.formatted(item.estimatedMonthly, currency: storage.profile.currency))
                                .font(.subheadline).bold()
                        }
                        HStack(spacing: 6) {
                            if item.priceHikePercent > 5 {
                                VaultPill(text: "↑ \(WealthLabEngine.percent(item.priceHikePercent))",
                                          icon: "exclamationmark.triangle.fill", color: VaultTheme.red)
                            }
                            if alreadyTracked.contains(item.title.lowercased()) {
                                VaultPill(text: "Tracked", icon: "checkmark", color: VaultTheme.green, filled: true)
                            }
                            Spacer()
                            Button("Ignore") {
                                ignored.insert(item.title)
                            }
                            .font(.caption2).foregroundColor(.secondary)
                            Button("Track") { track(item) }
                                .font(.caption2).bold()
                                .disabled(alreadyTracked.contains(item.title.lowercased()))
                        }
                    }
                    .padding(.vertical, 5)
                    if item.id != detected.last?.id { Divider() }
                }
            }
        }
    }

    private func track(_ item: DetectedSubscription) {
        guard !alreadyTracked.contains(item.title.lowercased()) else { return }
        storage.subscriptions.append(
            Subscription(title: item.title, amount: item.estimatedMonthly, cycle: .monthly,
                         nextBillingDate: Calendar.current.date(byAdding: .day, value: 30, to: item.lastCharge) ?? Date(),
                         category: item.candidateCategory.localized,
                         notes: "Detected from \(item.occurrences) local charges.")
        )
        storage.save()
    }
}
