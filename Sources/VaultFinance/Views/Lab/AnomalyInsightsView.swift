import SwiftUI

// MARK: - Spending Anomalies

struct AnomalyInsightsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var dismissed: Set<UUID> = []

    private var anomalies: [SpendingAnomaly] {
        WealthLabEngine.detectAnomalies(transactions: storage.transactions)
            .filter { !dismissed.contains($0.id) }
    }

    private var totalFlagged: Double { anomalies.reduce(0) { $0 + $1.amount } }
    private var averageDeviation: Double {
        guard !anomalies.isEmpty else { return 0 }
        return anomalies.reduce(0) { $0 + $1.deviationPercent } / Double(anomalies.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabHeroCard(
                    eyebrow: "Anomaly Insights",
                    title: anomalies.isEmpty ? "Nothing unusual" : "\(anomalies.count) charge(s) stand out",
                    subtitle: anomalies.isEmpty
                        ? "Your recent spending looks consistent with your normal patterns."
                        : "\(WealthLabEngine.formatted(totalFlagged, currency: storage.profile.currency)) flagged · \(WealthLabEngine.percent(averageDeviation)) average above normal.",
                    icon: "exclamationmark.magnifyingglass",
                    gradient: anomalies.isEmpty ? VaultTheme.savingsGradient : VaultTheme.warningGradient
                )

                if anomalies.isEmpty {
                    VaultCard {
                        VaultEmptyState(icon: "checkmark.shield.fill", title: "No anomalies detected",
                                        message: "The detector compares each charge with your usual amount in the same category over the last three months.")
                    }
                } else {
                    HStack(spacing: 10) {
                        LabStat(label: "Flagged spend", value: WealthLabEngine.formatted(totalFlagged, currency: storage.profile.currency),
                                icon: "banknote", tint: VaultTheme.orange)
                        LabStat(label: "Avg deviation", value: WealthLabEngine.percent(averageDeviation),
                                icon: "arrow.up.right", tint: VaultTheme.red)
                    }
                    anomalyList
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 8) {
                        VaultSectionHeader(title: "What counts as an anomaly?")
                        Text("A charge must be at least 40% above your category average and outside normal variation. Small categories need at least four charges before they are compared.")
                            .font(.caption2).foregroundColor(.secondary)
                        NavigationLink {
                            SpendingHeatmapView()
                        } label: {
                            Label("Open spending heatmap", systemImage: "square.grid.3x3.fill")
                                .font(.caption).bold()
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Anomalies")
        .inlineNavigationTitle()
    }

    private var anomalyList: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Flagged charges", subtitle: "Tap dismiss if it was expected")
                ForEach(anomalies) { anomaly in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 9) {
                            Image(systemName: anomaly.category.iconName)
                                .foregroundColor(VaultTheme.tint(for: anomaly.category.color))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(anomaly.title).font(.caption).bold()
                                Text(anomaly.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(WealthLabEngine.formatted(anomaly.amount, currency: storage.profile.currency))
                                .font(.subheadline).bold()
                        }
                        Text(anomaly.message)
                            .font(.caption2).foregroundColor(.secondary)
                        HStack {
                            Text("Usual: \(WealthLabEngine.formatted(anomaly.average, currency: storage.profile.currency))")
                                .font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Button("Dismiss") { dismissed.insert(anomaly.id) }
                                .font(.caption2).bold()
                                .foregroundColor(VaultTheme.blue)
                        }
                    }
                    .padding(.vertical, 4)
                    if anomaly.id != anomalies.last?.id { Divider() }
                }
            }
        }
    }
}
