import SwiftUI

// MARK: - Financial Health Timeline

struct HealthTimelineView: View {
    @EnvironmentObject var storage: LocalStorage

    private var scores: [FinancialHealthScore] {
        storage.healthScores.sorted { $0.date < $1.date }
    }

    private var latest: FinancialHealthScore? { scores.last }

    private var change: Int {
        guard let first = scores.first?.score, let last = scores.last?.score else { return 0 }
        return last - first
    }

    private var tint: Color {
        guard let score = latest?.score else { return VaultTheme.blue }
        switch score {
        case ..<40: return VaultTheme.red
        case 40..<60: return VaultTheme.orange
        case 60..<75: return VaultTheme.gold
        default: return VaultTheme.green
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if scores.isEmpty {
                    VaultCard {
                        VaultEmptyState(icon: "heart.text.square", title: "No health snapshots",
                                        message: "Complete your profile and budget to generate a financial health score.")
                    }
                } else {
                    trendCard
                    factorsCard
                    timelineCard
                }
                LabCallout(icon: "lightbulb.fill", title: "Small improvements compound",
                           message: "Focus on the lowest-scoring factor with the highest weight. A 10-point gain there usually moves the overall score most.",
                           tint: VaultTheme.green)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Health Timeline")
        .inlineNavigationTitle()
    }

    private var hero: some View {
        HStack(spacing: 18) {
            VaultGauge(value: Double(latest?.score ?? 0) / 100, tint: tint,
                       label: "health score", valueText: "\(latest?.score ?? 0)")
                .frame(width: 140, height: 140)
            VStack(alignment: .leading, spacing: 7) {
                Text("Financial health").font(.headline)
                Text(latest?.recommendation ?? "No recommendation yet")
                    .font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(change >= 0 ? "+" : "")\(change) since first snapshot")
                }
                .font(.caption).bold()
                .foregroundColor(change >= 0 ? VaultTheme.green : VaultTheme.red)
                Text("\(scores.count) snapshot(s)")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }

    private var trendCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Score timeline",
                                   subtitle: scores.first.map { "Since \($0.date.formatted(.dateTime.month(.abbreviated).year()))" } ?? "")
                VaultLineChart(points: scores.enumerated().map {
                    ChartPoint(x: Double($0.offset), y: Double($0.element.score))
                }, tint: tint, showArea: true, showDots: true)
                    .frame(height: 170)
                HStack {
                    Text(scores.first?.date.formatted(.dateTime.month(.abbreviated).day()) ?? "")
                    Spacer()
                    Text(scores.last?.date.formatted(.dateTime.month(.abbreviated).day()) ?? "")
                }
                .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var factorsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Factor breakdown",
                                   subtitle: "What is driving the latest score")
                if let factors = latest?.factors.sorted(by: { $0.weight > $1.weight }) {
                    ForEach(factors) { factor in
                        LabProgressRow(title: factor.name,
                                       detail: "Weight \(factor.weight)% · \(factor.description)",
                                       progress: Double(factor.score) / 100,
                                       tint: factor.score >= 60 ? VaultTheme.green : VaultTheme.orange,
                                       trailing: "\(factor.score)")
                    }
                } else {
                    Text("No factors recorded.").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private var timelineCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Snapshots")
                ForEach(scores.reversed()) { score in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(score.score >= 60 ? VaultTheme.green : VaultTheme.orange)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(score.date.formatted(.dateTime.month(.wide).day().year()))
                                .font(.caption).bold()
                            Text(score.recommendation)
                                .font(.caption2).foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(score.score)").font(.headline).bold()
                            .foregroundColor(score.score >= 60 ? VaultTheme.green : VaultTheme.orange)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
