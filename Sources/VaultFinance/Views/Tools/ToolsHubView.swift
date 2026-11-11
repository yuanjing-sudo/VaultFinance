import Foundation
import SwiftUI

// MARK: - Tools Hub
// A single place for every planning calculator, each opening a deep screen.

struct ToolsHubView: View {
    @EnvironmentObject var storage: LocalStorage

    private var savingsRate: Double {
        let income = storage.profile.totalMonthlyIncome
        let saved = max(income - storage.transactions
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }, 0)
        return FinanceEngine.savingsRate(income: income, savings: saved)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.skyGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Planning Tools").font(.caption).opacity(0.9)
                        Text("Run the numbers").font(.title2).bold()
                        Text("Savings rate: \(savingsRate, specifier: "%.0f")% · Rule of 72: \(FinanceEngine.ruleOf72(annualRate: 7), specifier: "%.1f") yrs to double")
                            .font(.caption2).opacity(0.9)
                    }
                }

                toolLink(title: "FIRE Calculator",
                         subtitle: "Find your financial independence number",
                         icon: "flame.fill", color: "green") {
                    FIREView()
                }
                toolLink(title: "Compound Interest",
                         subtitle: "Watch contributions snowball",
                         icon: "chart.line.uptrend.xyaxis", color: "blue") {
                    CompoundInterestView()
                }
                toolLink(title: "Loan Amortization",
                         subtitle: "See where each payment goes",
                         icon: "house.fill", color: "orange") {
                    AmortizationView()
                }
                toolLink(title: "Tax Estimator",
                         subtitle: "Estimate take-home pay",
                         icon: "doc.text.fill", color: "purple") {
                    TaxEstimatorView()
                }
                toolLink(title: "Net Worth Timeline",
                         subtitle: "Your wealth over time",
                         icon: "chart.xyaxis.line", color: "teal") {
                    NetWorthTimelineView()
                }
                toolLink(title: "Recurring Transactions",
                         subtitle: "Automate repeat income and bills",
                         icon: "arrow.clockwise.circle.fill", color: "pink") {
                    RecurringTransactionsView()
                }

                inflationCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Tools")
        .inlineNavigationTitle()
    }

    private func toolLink<Destination: View>(title: String, subtitle: String,
                                             icon: String, color: String,
                                             @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(VaultTheme.tint(for: color).opacity(0.14))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .foregroundColor(VaultTheme.tint(for: color))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline).bold().foregroundColor(.primary)
                    Text(subtitle).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.08))
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Inflation mini tool

    @State private var inflationYears: Double = 10
    @State private var inflationRate: Double = 3

    private var inflationImpact: Double {
        FinanceEngine.purchasingPowerLoss(value: storage.profile.existingSavings,
                                          annualInflation: inflationRate,
                                          years: inflationYears)
    }

    private var inflationCard: some View {
        VaultCard(tint: VaultTheme.orange) {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Inflation Impact",
                                   subtitle: "What your savings really buy")
                Text("In \(Int(inflationYears)) years at \(inflationRate, specifier: "%.1f")% inflation, your current savings lose about \(Money(amount: inflationImpact).formatted()) of purchasing power.")
                    .font(.caption)
                Slider(value: $inflationYears, in: 1...40, step: 1)
                HStack {
                    Text("Years: \(Int(inflationYears))").font(.caption2)
                    Spacer()
                }
                Slider(value: $inflationRate, in: 0...12, step: 0.5)
                HStack {
                    Text("Inflation: \(inflationRate, specifier: "%.1f")%").font(.caption2)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Net Worth Timeline

struct NetWorthTimelineView: View {
    @EnvironmentObject var storage: LocalStorage

    private var snapshots: [NetWorthSnapshot] {
        storage.netWorthSnapshots.sorted { $0.date < $1.date }
    }

    private var current: Double {
        let assets = storage.assets.reduce(0) { $0 + $1.currentMarketValue } + storage.profile.existingSavings
        let liabilities = storage.liabilities.reduce(0) { $0 + $1.balance }
        return assets - liabilities
    }

    private var change: Double {
        guard let first = snapshots.first else { return 0 }
        return current - first.netWorth
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.savingsGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Net Worth").font(.caption).opacity(0.9)
                        Text(Money(amount: current, currency: storage.profile.currency).formatted())
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                        Text("\(change >= 0 ? "▲" : "▼") \(Money(amount: abs(change)).formatted()) since first snapshot")
                            .font(.caption2).opacity(0.9)
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: "Timeline", subtitle: "\(snapshots.count) snapshots")
                        if snapshots.isEmpty {
                            VaultEmptyState(icon: "chart.xyaxis.line", title: "No snapshots yet")
                        } else {
                            VaultLineChart(points: snapshots.enumerated().map {
                                ChartPoint(x: Double($0.offset), y: $0.element.netWorth)
                            }, tint: VaultTheme.green, showDots: true)
                                .frame(height: 160)
                        }
                    }
                }
                VaultCard {
                    VStack(alignment: .leading, spacing: 8) {
                        VaultSectionHeader(title: "Snapshots")
                        ForEach(snapshots.reversed()) { snap in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snap.date.formatted(.dateTime.month().day().year()))
                                        .font(.caption).bold()
                                    Text("Assets \(Money(amount: snap.assets).formatted())")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(Money(amount: snap.netWorth).formatted())
                                        .font(.subheadline).bold()
                                    Text("Debt \(Money(amount: snap.liabilities).formatted())")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                Button {
                    storage.netWorthSnapshots.append(
                        NetWorthSnapshot(date: Date(),
                                         assets: storage.assets.reduce(0) { $0 + $1.currentMarketValue } + storage.profile.existingSavings,
                                         liabilities: storage.liabilities.reduce(0) { $0 + $1.balance })
                    )
                    storage.save()
                } label: {
                    Label("Capture Snapshot", systemImage: "camera.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Net Worth")
        .inlineNavigationTitle()
    }
}
