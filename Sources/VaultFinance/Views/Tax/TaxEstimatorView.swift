import Foundation
import SwiftUI

// MARK: - Tax Estimator
// Estimate federal + state tax, effective and marginal rates, and take-home pay.
// All math is deterministic in FinanceEngine.

struct TaxEstimatorView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var profile: TaxProfile

    init() {
        _profile = State(initialValue: LocalStorage.shared.taxProfile)
    }

    private var result: (federal: Double, state: Double, total: Double, effectiveRate: Double) {
        FinanceEngine.estimateTax(profile: profile)
    }

    private var taxableIncome: Double {
        max(profile.grossIncome - profile.preTaxDeductions
            - FinanceEngine.standardDeduction(for: profile.filingStatus)
            - Double(profile.dependents) * 2000, 0)
    }

    private var marginal: Double { FinanceEngine.marginalRate(taxableIncome: taxableIncome) }

    private var netIncome: Double { max(profile.grossIncome - result.total, 0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                breakdownCard
                bracketCard
                inputsCard
                notesCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Tax Estimator")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    storage.taxProfile = profile
                    storage.save()
                }
                .font(.caption).bold()
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VaultGradientCard(gradient: VaultTheme.goldGradient) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Estimated Take-Home")
                    .font(.caption).opacity(0.9)
                Text(Money(amount: netIncome, currency: storage.profile.currency).formatted())
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                HStack(spacing: 16) {
                    metric("Effective", String(format: "%.1f%%", result.effectiveRate))
                    metric("Marginal", String(format: "%.0f%%", marginal * 100))
                    metric("Per month", Money(amount: netIncome / 12).formatted())
                }
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).opacity(0.85)
            Text(value).font(.subheadline).bold()
        }
    }

    // MARK: - Breakdown

    private var breakdownCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 14) {
                VaultSectionHeader(title: "Where Your Money Goes",
                                   subtitle: "Tax year \(profile.taxYear)")
                HStack(spacing: 18) {
                    VaultDonutChart(
                        slices: [
                            DonutSlice(label: "Take-home", value: netIncome, color: VaultTheme.green),
                            DonutSlice(label: "Federal", value: result.federal, color: VaultTheme.blue),
                            DonutSlice(label: "State", value: result.state, color: VaultTheme.purple)
                        ],
                        lineWidth: 18,
                        centerTitle: String(format: "%.0f%%", result.effectiveRate),
                        centerSubtitle: "tax rate"
                    )
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 8) {
                        legend("Take-home", netIncome, VaultTheme.green)
                        legend("Federal tax", result.federal, VaultTheme.blue)
                        legend("State tax", result.state, VaultTheme.purple)
                        Divider()
                        HStack {
                            Text("Total tax").font(.caption).bold()
                            Spacer()
                            Text(Money(amount: result.total).formatted())
                                .font(.caption).bold()
                        }
                    }
                }
            }
        }
    }

    private func legend(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(.secondary)
            Spacer()
            Text(Money(amount: value).formatted()).font(.caption2).bold()
        }
    }

    // MARK: - Brackets

    private var bracketCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Marginal Brackets",
                                   subtitle: "How each slice is taxed")
                ForEach(FinanceEngine.federalBrackets.indices, id: \.self) { index in
                    let bracket = FinanceEngine.federalBrackets[index]
                    let lower = index == 0 ? 0 : FinanceEngine.federalBrackets[index - 1].upper
                    let filled = taxableIncome > lower
                    HStack(spacing: 10) {
                        Text("\(bracket.rate * 100, specifier: "%.0f")%")
                            .font(.caption2).bold()
                            .frame(width: 34, alignment: .leading)
                            .foregroundColor(filled ? VaultTheme.blue : .secondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.12))
                                Capsule()
                                    .fill(filled ? VaultTheme.blue : Color.clear)
                                    .frame(width: filled ? geo.size.width : 0)
                            }
                        }
                        .frame(height: 7)
                        Text(bracket.upper.isFinite
                             ? Money(amount: bracket.upper).formatted()
                             : "∞")
                            .font(.caption2).foregroundColor(.secondary)
                            .frame(width: 82, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Inputs

    private var inputsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 14) {
                VaultSectionHeader(title: "Your Details")
                Picker("Filing status", selection: $profile.filingStatus) {
                    ForEach(TaxProfile.FilingStatus.allCases, id: \.self) { status in
                        Text(status.localized).tag(status)
                    }
                }
                .pickerStyle(.menu)

                incomeRow("Gross income", value: $profile.grossIncome, range: 0...500_000)
                incomeRow("Pre-tax deductions", value: $profile.preTaxDeductions, range: 0...100_000)

                HStack {
                    Text("State tax rate").font(.subheadline)
                    Spacer()
                    Text("\(profile.stateTaxRate, specifier: "%.1f")%")
                        .font(.subheadline).bold()
                }
                Slider(value: $profile.stateTaxRate, in: 0...15, step: 0.1)

                Stepper("Dependents: \(profile.dependents)",
                        value: $profile.dependents, in: 0...10)

                Picker("Tax year", selection: $profile.taxYear) {
                    ForEach([2024, 2025, 2026], id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func incomeRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(Money(amount: value.wrappedValue).formatted())
                    .font(.subheadline).bold()
            }
            Slider(value: value, in: range, step: 500)
        }
    }

    private var notesCard: some View {
        VaultCard(tint: VaultTheme.orange) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill").foregroundColor(VaultTheme.orange)
                Text("This is a simplified estimate for planning only. It ignores credits, local taxes, and special deductions. Consult a tax professional before filing.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}
