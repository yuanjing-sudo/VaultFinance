import Foundation
import SwiftUI

// MARK: - FIRE Calculator
// Financial Independence, Retire Early: your FI number, years to go, and
// a projected wealth path based on contributions and expected return.

struct FIREView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var annualExpenses: Double
    @State private var withdrawalRate: Double = 4.0
    @State private var annualReturn: Double = 7.0
    @State private var current: Double
    @State private var monthlyContribution: Double = 500

    init() {
        _current = State(initialValue: LocalStorage.shared.profile.existingSavings)
        _annualExpenses = State(initialValue: max(LocalStorage.shared.profile.totalMonthlyIncome * 12 * 0.6, 24000))
    }

    private var fiNumber: Double {
        FinanceEngine.fireNumber(annualExpenses: annualExpenses, withdrawalRate: withdrawalRate)
    }

    private var years: Double {
        FinanceEngine.yearsToFIRE(current: current,
                                  monthlyContribution: monthlyContribution,
                                  annualExpenses: annualExpenses,
                                  withdrawalRate: withdrawalRate,
                                  annualReturn: annualReturn)
    }

    private var progress: Double {
        fiNumber > 0 ? min(current / fiNumber, 1) : 0
    }

    private var path: [CompoundPoint] {
        FinanceEngine.compoundGrowth(principal: current,
                                     monthlyContribution: monthlyContribution,
                                     annualRate: annualReturn,
                                     years: min(Int(years.rounded(.up)) + 1, 60))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                projectionCard
                inputsCard
                explainer
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("FIRE Calculator")
        .inlineNavigationTitle()
    }

    private var heroCard: some View {
        VaultGradientCard(gradient: VaultTheme.savingsGradient) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your FI Number").font(.caption).opacity(0.9)
                Text(Money(amount: fiNumber, currency: storage.profile.currency).formatted())
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                VaultProgressBar(progress: progress, height: 10,
                                 gradient: LinearGradient(colors: [.white, .white.opacity(0.75)],
                                                          startPoint: .leading, endPoint: .trailing),
                                 track: Color.white.opacity(0.25))
                HStack {
                    Text("\(progress * 100, specifier: "%.1f")% funded")
                        .font(.caption2).opacity(0.9)
                    Spacer()
                    if years < 60 {
                        Text("~\(years, specifier: "%.1f") years to go")
                            .font(.caption2).bold()
                    } else {
                        Text("Beyond 60 years")
                            .font(.caption2).bold()
                    }
                }
            }
        }
    }

    private var projectionCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Wealth Path", subtitle: "Balance vs contributions")
                VaultLineChart(points: path.map { ChartPoint(x: Double($0.year), y: $0.balance) },
                               tint: VaultTheme.green)
                    .frame(height: 150)
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("FIRE age").font(.caption2).foregroundColor(.secondary)
                        Text("\(fireAge)").font(.headline).bold()
                    }
                    VStack(alignment: .leading) {
                        Text("Freedom number").font(.caption2).foregroundColor(.secondary)
                        Text(Money(amount: fiNumber).formatted()).font(.headline).bold()
                    }
                    Spacer()
                }
            }
        }
    }

    private var fireAge: String {
        guard let age = storage.profile.age else { return "—" }
        let projected = Double(age) + years
        return projected < 100 ? "\(Int(projected))" : "—"
    }

    private var inputsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 14) {
                VaultSectionHeader(title: "Assumptions")
                slider("Annual expenses", value: $annualExpenses, range: 6_000...200_000, step: 1_000, money: true)
                slider("Current savings", value: $current, range: 0...2_000_000, step: 1_000, money: true)
                slider("Monthly contribution", value: $monthlyContribution, range: 0...10_000, step: 50, money: true)
                slider("Withdrawal rate", value: $withdrawalRate, range: 2...8, step: 0.1, money: false, suffix: "%")
                slider("Expected annual return", value: $annualReturn, range: 1...12, step: 0.5, money: false, suffix: "%")
            }
        }
    }

    private func slider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>,
                        step: Double, money: Bool, suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(money
                     ? Money(amount: value.wrappedValue).formatted()
                     : String(format: "%.1f", value.wrappedValue) + suffix)
                    .font(.subheadline).bold()
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private var explainer: some View {
        VaultCard(tint: VaultTheme.green) {
            VStack(alignment: .leading, spacing: 6) {
                Text("The 4% rule").font(.subheadline).bold()
                Text("Withdrawing about 4% of your portfolio each year is designed to sustain spending for 30+ years. Your FI number is annual expenses divided by the withdrawal rate.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Compound Interest Visualizer

struct CompoundInterestView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var principal: Double = 1000
    @State private var monthly: Double = 200
    @State private var rate: Double = 7
    @State private var years: Double = 20

    private var points: [CompoundPoint] {
        FinanceEngine.compoundGrowth(principal: principal,
                                     monthlyContribution: monthly,
                                     annualRate: rate,
                                     years: Int(years))
    }

    private var final: CompoundPoint { points.last ?? CompoundPoint(year: 0, balance: 0, contributed: 0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.brandGradient) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Future Value").font(.caption).opacity(0.9)
                        Text(Money(amount: final.balance, currency: storage.profile.currency).formatted())
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        HStack(spacing: 20) {
                            stat("Contributed", final.contributed)
                            stat("Growth", final.growth)
                        }
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: "Growth Curve", subtitle: "In \(Int(years)) years")
                        VaultLineChart(points: points.map { ChartPoint(x: Double($0.year), y: $0.balance) },
                                       tint: VaultTheme.blue)
                            .frame(height: 160)
                        VaultStackedBar(segments: [
                            DonutSlice(label: "Contributed", value: final.contributed, color: VaultTheme.blue),
                            DonutSlice(label: "Growth", value: max(final.growth, 0), color: VaultTheme.green)
                        ], height: 12)
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 14) {
                        VaultSectionHeader(title: "Adjust")
                        slider("Starting amount", $principal, 0...100_000, 500, true)
                        slider("Monthly contribution", $monthly, 0...5_000, 25, true)
                        slider("Annual return", $rate, 1...12, 0.5, false, "%")
                        slider("Years", $years, 1...40, 1, false, "")
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Compound Interest")
        .inlineNavigationTitle()
    }

    private func stat(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).opacity(0.9)
            Text(Money(amount: value).formatted()).font(.caption).bold()
        }
    }

    private func slider(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>,
                        _ step: Double, _ money: Bool, _ suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(money ? Money(amount: value.wrappedValue).formatted()
                     : String(format: "%.1f", value.wrappedValue) + suffix)
                    .font(.subheadline).bold()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}

// MARK: - Loan Amortization

struct AmortizationView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var principal: Double = 25_000
    @State private var rate: Double = 6.5
    @State private var months: Double = 60

    private var schedule: [AmortizationEntry] {
        FinanceEngine.amortizationSchedule(principal: principal, annualRate: rate, months: Int(months))
    }

    private var payment: Double {
        FinanceEngine.monthlyLoanPayment(principal: principal, annualRate: rate, months: Int(months))
    }

    private var totalInterest: Double { FinanceEngine.totalInterest(schedule: schedule) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.warningGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Payment").font(.caption).opacity(0.9)
                        Text(Money(amount: payment, currency: storage.profile.currency).formatted())
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                        HStack(spacing: 20) {
                            stat("Total interest", totalInterest)
                            stat("Total paid", principal + totalInterest)
                        }
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: "Balance Over Time")
                        VaultLineChart(points: schedule.map {
                            ChartPoint(x: Double($0.month), y: $0.balance)
                        }, tint: VaultTheme.orange)
                            .frame(height: 140)
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 12) {
                        VaultSectionHeader(title: "Loan Terms")
                        slider("Principal", $principal, 1_000...500_000, 1_000, true)
                        slider("Interest rate", $rate, 0...20, 0.1, false, "%")
                        slider("Term (months)", $months, 6...360, 6, false, " mo")
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 8) {
                        VaultSectionHeader(title: "Schedule", subtitle: "First 12 payments")
                        ForEach(schedule.prefix(12)) { entry in
                            HStack {
                                Text("Month \(entry.month)").font(.caption2).frame(width: 70, alignment: .leading)
                                Text(Money(amount: entry.principal).formatted())
                                    .font(.caption2).foregroundColor(.secondary)
                                Spacer()
                                Text(Money(amount: entry.interest).formatted())
                                    .font(.caption2).foregroundColor(VaultTheme.orange)
                                Text(Money(amount: entry.balance).formatted())
                                    .font(.caption2).bold().frame(width: 78, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Amortization")
        .inlineNavigationTitle()
    }

    private func stat(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).opacity(0.9)
            Text(Money(amount: value).formatted()).font(.caption).bold()
        }
    }

    private func slider(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>,
                        _ step: Double, _ money: Bool, _ suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(money ? Money(amount: value.wrappedValue).formatted()
                     : String(format: "%.0f", value.wrappedValue) + suffix)
                    .font(.subheadline).bold()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
