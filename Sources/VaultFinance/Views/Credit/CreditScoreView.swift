import SwiftUI

// MARK: - Credit Score Tracker
// Track score history across bureaus, see the band, monitor utilization,
// and log new scores. Animated gauge + timeline.

struct CreditScoreView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAdd = false
    @State private var showingTips = false

    private var records: [CreditScoreRecord] {
        storage.creditScores.sorted { $0.date < $1.date }
    }

    private var latest: CreditScoreRecord {
        records.last ?? CreditScoreRecord()
    }

    private var delta: Int {
        guard records.count >= 2 else { return 0 }
        return latest.score - records[records.count - 2].score
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                gaugeCard
                if !records.isEmpty { historyCard }
                utilizationCard
                factorsCard
                tipsCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Credit Score")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCreditScoreSheet(records: records) { record in
                storage.creditScores.append(record)
                storage.save()
            }
        }
    }

    // MARK: - Gauge

    private var gaugeCard: some View {
        VaultGradientCard(gradient: VaultTheme.skyGradient) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Credit Score").font(.caption).opacity(0.9)
                        Text(latest.band).font(.title3).bold()
                    }
                    Spacer()
                    VaultPill(text: delta >= 0 ? "+\(delta)" : "\(delta)",
                              icon: delta >= 0 ? "arrow.up.right" : "arrow.down.right",
                              color: .white.opacity(0.9), filled: false)
                }
                VaultGauge(
                    value: latest.normalized,
                    tint: .white,
                    label: "of 850",
                    valueText: "\(latest.score)"
                )
                .frame(width: 150, height: 150)
                Text("Updated \(latest.date.formatted(.dateTime.month().day().year())) · \(latest.bureau)")
                    .font(.caption2).opacity(0.9)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - History

    private var historyCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Score History", subtitle: "\(records.count) reports logged")
                VaultLineChart(
                    points: records.enumerated().map { i, r in
                        ChartPoint(x: Double(i), y: Double(r.score), label: r.band)
                    },
                    tint: VaultTheme.teal,
                    showDots: true
                )
                .frame(height: 150)
                HStack {
                    ForEach(records.suffix(4)) { r in
                        VStack(spacing: 2) {
                            Text("\(r.score)").font(.caption).bold()
                            Text(r.date.formatted(.dateTime.month(.abbreviated)))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Utilization

    private var utilizationCard: some View {
        let cardDebt = storage.liabilities
            .filter { $0.type == .creditCard }
            .reduce(0) { $0 + $1.balance }
        let limit = max(cardDebt / 0.28, 1)
        let utilization = FinanceEngine.creditUtilization(balance: cardDebt, limit: limit)
        let color = utilization < 10 ? VaultTheme.green
            : utilization < 30 ? VaultTheme.gold : VaultTheme.red
        return VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Credit Utilization",
                                   subtitle: "Aim for under 30%")
                HStack(alignment: .firstTextBaseline) {
                    Text("\(utilization, specifier: "%.0f")%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Spacer()
                    Text(Money(amount: cardDebt).formatted() + " used")
                        .font(.caption).foregroundColor(.secondary)
                }
                VaultProgressBar(
                    progress: utilization / 100,
                    height: 12,
                    gradient: LinearGradient(colors: [color.opacity(0.6), color],
                                             startPoint: .leading, endPoint: .trailing)
                )
                Text(FinanceEngine.creditScoreImpact(utilization: utilization))
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Factors

    private var factorsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "What Moves Your Score", subtitle: "Typical weighting")
                ForEach(creditFactors, id: \.name) { factor in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(VaultTheme.tint(for: factor.color).opacity(0.15))
                                .frame(width: 38, height: 38)
                            Image(systemName: factor.icon)
                                .font(.caption).foregroundColor(VaultTheme.tint(for: factor.color))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(factor.name).font(.subheadline).bold()
                                Spacer()
                                Text("\(factor.weight)%").font(.caption2).foregroundColor(.secondary)
                            }
                            Text(factor.detail).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private struct CreditFactor {
        var name: String
        var detail: String
        var weight: Int
        var icon: String
        var color: String
    }

    private var creditFactors: [CreditFactor] {
        [
            .init(name: "Payment history", detail: "Pay every bill on time", weight: 35, icon: "checkmark.seal.fill", color: "green"),
            .init(name: "Utilization", detail: "Keep balances low", weight: 30, icon: "percent", color: "blue"),
            .init(name: "Credit age", detail: "Keep old accounts open", weight: 15, icon: "clock.fill", color: "purple"),
            .init(name: "New credit", detail: "Limit hard inquiries", weight: 10, icon: "sparkle.magnifyingglass", color: "orange"),
            .init(name: "Credit mix", detail: "Diversify account types", weight: 10, icon: "square.stack.3d.up.fill", color: "teal")
        ]
    }

    // MARK: - Tips

    private var tipsCard: some View {
        VaultCard(tint: VaultTheme.blue) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill").foregroundColor(VaultTheme.gold)
                    Text("Boost Your Score").font(.headline).bold()
                    Spacer()
                    Button(showingTips ? "Hide" : "Show") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingTips.toggle()
                        }
                    }
                    .font(.caption)
                }
                if showingTips {
                    ForEach(creditTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.caption).foregroundColor(VaultTheme.green)
                            Text(tip).font(.caption)
                        }
                    }
                } else {
                    Text("Tap show for \(creditTips.count) practical ways to raise your score.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private var creditTips: [String] {
        [
            "Set up autopay for at least the minimum on every card.",
            "Ask for a credit limit increase to lower utilization.",
            "Keep older accounts open to preserve account age.",
            "Space out applications for new credit by several months.",
            "Dispute any errors you find on your report.",
            "Use less than 10% of your total available credit.",
            "Never close your oldest credit card."
        ]
    }
}

// MARK: - Add Score Sheet

struct AddCreditScoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    let records: [CreditScoreRecord]
    var onSave: (CreditScoreRecord) -> Void

    @State private var score: Double = 700
    @State private var bureau = "Equifax"
    @State private var date = Date()
    @State private var factorText = ""

    private let bureaus = ["Equifax", "Experian", "TransUnion"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Score") {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text("\(Int(score))").bold().foregroundColor(.blue)
                    }
                    Slider(value: $score, in: 300...850, step: 1)
                }
                Section("Details") {
                    Picker("Bureau", selection: $bureau) {
                        ForEach(bureaus, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $factorText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Text("Band: \(band(for: Int(score)))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Score")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let factors = factorText.isEmpty ? [] : [factorText]
                        onSave(CreditScoreRecord(date: date, score: Int(score),
                                                 bureau: bureau, factors: factors))
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    private func band(for score: Int) -> String {
        switch score {
        case ..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Excellent"
        }
    }
}
