import SwiftUI

// MARK: - Credit Score Simulator

struct CreditSimulatorView: View {
    @EnvironmentObject var storage: LocalStorage

    @State private var utilization: Double = 35
    @State private var onTimePayments = true
    @State private var newAccounts: Double = 0
    @State private var inquiries: Double = 0

    private var baseScore: Int {
        storage.creditScores.max(by: { $0.date < $1.date })?.score ?? 700
    }

    private var projected: Int {
        WealthLabEngine.simulateCreditScore(base: baseScore, utilization: utilization,
                                            onTimePayments: onTimePayments,
                                            newAccounts: Int(newAccounts),
                                            inquiries: Int(inquiries))
    }

    private var delta: Int { projected - baseScore }

    private var scoreTint: Color {
        switch projected {
        case ..<580: return VaultTheme.red
        case 580..<670: return VaultTheme.orange
        case 670..<740: return VaultTheme.gold
        case 740..<800: return VaultTheme.green
        default: return VaultTheme.teal
        }
    }

    private var band: String {
        switch projected {
        case ..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Excellent"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreCard
                controlsCard
                scenariosCard
                impactCard
                LabCallout(icon: "info.circle.fill", title: "Educational estimate",
                           message: "This model shows direction, not a guaranteed bureau outcome. Real scoring models weigh many more factors and change over time.",
                           tint: VaultTheme.orange)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Credit Simulator")
        .inlineNavigationTitle()
    }

    private var scoreCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                VaultGauge(value: Double(projected - 300) / 550, tint: scoreTint,
                           label: "simulated", valueText: "\(projected)")
                    .frame(width: 145, height: 145)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Current \(baseScore)").font(.caption).foregroundColor(.secondary)
                    Text(band).font(.title3).bold().foregroundColor(scoreTint)
                    HStack(spacing: 4) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(delta >= 0 ? "+" : "")\(delta) points")
                    }
                    .font(.subheadline).bold()
                    .foregroundColor(delta >= 0 ? VaultTheme.green : VaultTheme.red)
                    Text("From \(storage.creditScores.count) recorded score(s)")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            VaultProgressBar(progress: Double(projected - 300) / 550, height: 8,
                             gradient: LinearGradient(colors: [scoreTint.opacity(0.6), scoreTint],
                                                      startPoint: .leading, endPoint: .trailing))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scoreTint.opacity(0.08))
        )
    }

    private var controlsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 14) {
                VaultSectionHeader(title: "Try a scenario",
                                   subtitle: "Adjust the levers that move a score fastest")
                sliderRow(title: "Credit utilization", value: "\(Int(utilization))%",
                          binding: $utilization, range: 0...100, step: 1,
                          note: "Below 10% is ideal. Above 50% is costly.")
                Toggle("All payments on time", isOn: $onTimePayments)
                    .font(.caption).bold()
                sliderRow(title: "New accounts", value: "\(Int(newAccounts))",
                          binding: $newAccounts, range: 0...5, step: 1,
                          note: "Each new account can shave a few points.")
                sliderRow(title: "Hard inquiries", value: "\(Int(inquiries))",
                          binding: $inquiries, range: 0...6, step: 1,
                          note: "Inquiries fade in impact over time.")
            }
        }
    }

    private var scenariosCard: some View {
        VaultCard(tint: VaultTheme.blue) {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Quick scenarios")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    scenarioButton("Pay cards down", icon: "arrow.down.circle.fill", tint: VaultTheme.green) {
                        utilization = 8; onTimePayments = true; newAccounts = 0; inquiries = 0
                    }
                    scenarioButton("Open a new card", icon: "plus.rectangle.fill", tint: VaultTheme.blue) {
                        newAccounts = 1; inquiries = 1
                    }
                    scenarioButton("Miss a payment", icon: "xmark.circle.fill", tint: VaultTheme.red) {
                        onTimePayments = false
                    }
                    scenarioButton("Reset", icon: "arrow.counterclockwise", tint: VaultTheme.orange) {
                        utilization = 35; onTimePayments = true; newAccounts = 0; inquiries = 0
                    }
                }
            }
        }
    }

    private var impactCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "What is helping or hurting")
                impactRow(icon: "percent", title: "Utilization", value: "\(Int(utilization))%",
                          good: utilization < 30, detail: utilization < 10 ? "Excellent range" : utilization < 30 ? "Healthy range" : "Try to pay balances down")
                impactRow(icon: "checkmark.seal.fill", title: "Payment history", value: onTimePayments ? "On time" : "Missed",
                          good: onTimePayments, detail: onTimePayments ? "Largest positive factor" : "Most damaging factor")
                impactRow(icon: "creditcard.fill", title: "New accounts", value: "\(Int(newAccounts))",
                          good: newAccounts == 0, detail: "Recent openings add risk")
                impactRow(icon: "magnifyingglass", title: "Inquiries", value: "\(Int(inquiries))",
                          good: inquiries == 0, detail: "Rate shopping clusters are safer")
            }
        }
    }

    private func sliderRow(title: String, value: String, binding: Binding<Double>,
                           range: ClosedRange<Double>, step: Double, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).bold()
                Spacer()
                Text(value).font(.caption).bold().foregroundColor(VaultTheme.blue)
            }
            Slider(value: binding, in: range, step: step)
            Text(note).font(.caption2).foregroundColor(.secondary)
        }
    }

    private func scenarioButton(_ title: String, icon: String, tint: Color,
                                action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption2)
                Text(title).font(.caption2).bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.12)))
            .foregroundColor(tint)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func impactRow(icon: String, title: String, value: String, good: Bool, detail: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundColor(good ? VaultTheme.green : VaultTheme.red)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption).bold()
                Text(detail).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(value).font(.caption2).bold()
                .foregroundColor(good ? VaultTheme.green : VaultTheme.red)
        }
        .padding(.vertical, 3)
    }
}
