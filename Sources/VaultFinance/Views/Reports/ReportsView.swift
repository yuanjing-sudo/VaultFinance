import SwiftUI

// MARK: - Reports View

/// Comprehensive financial reports: spending by category, income vs expenses, net worth over time, savings rate.
struct ReportsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var reportPeriod: ReportPeriod = .month

    enum ReportPeriod: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        var id: String { rawValue }
    }

    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch reportPeriod {
        case .week: startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month: startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .quarter: startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        case .year: startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        return storage.transactions.filter { $0.date >= startDate }
    }

    var totalSpending: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Double {
        storage.profile.totalMonthlyIncome * Double(monthsInPeriod)
    }

    var monthsInPeriod: Double {
        switch reportPeriod {
        case .week: return 7.0 / 30.0
        case .month: return 1
        case .quarter: return 3
        case .year: return 12
        }
    }

    var spendingByCategory: [(category: CategoryType, amount: Double)] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.category }
        return grouped.map { (key: $0.key, value: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.value > $1.value }
    }

    var netSavings: Double {
        totalIncome - totalSpending
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period selector
                Picker("Period", selection: $reportPeriod) {
                    ForEach(ReportPeriod.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Summary cards
                HStack(spacing: 10) {
                    ReportCard(title: "Income", value: Money(amount: totalIncome).formatted(), color: .green, icon: "arrow.down.circle.fill")
                    ReportCard(title: "Spending", value: Money(amount: totalSpending).formatted(), color: .red, icon: "arrow.up.circle.fill")
                    ReportCard(title: "Net Savings", value: Money(amount: netSavings).formatted(), color: .blue, icon: "banknote.fill")
                    ReportCard(title: "Savings Rate", value: "\(String(format: "%.0f", netSavings / max(totalIncome, 1) * 100))%", color: netSavings >= 0 ? .green : .red, icon: "percent")
                }

                // Spending by Category chart
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Spending by Category").font(.headline).bold()
                        Spacer()
                    }
                    if spendingByCategory.isEmpty {
                        EmptyState(message: "No spending data for this period.")
                    } else {
                        ForEach(spendingByCategory, id: \.category) { item in
                            CategorySpendingRow(item: item, total: totalSpending)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)

                // Income vs Spending bar chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Income vs Spending").font(.headline).bold()
                    GeometryReader { geo in
                        HStack(spacing: 8) {
                            BarView(value: totalIncome, label: "Income", color: .green, maxValue: max(totalIncome, totalSpending, 1), height: geo.size.height)
                            BarView(value: totalSpending, label: "Spending", color: .red, maxValue: max(totalIncome, totalSpending, 1), height: geo.size.height)
                            BarView(value: max(netSavings, 0), label: "Savings", color: .blue, maxValue: max(totalIncome, totalSpending, 1), height: geo.size.height)
                        }
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)

                // Recent transactions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Transactions").font(.headline).bold()
                        Spacer()
                    }
                    ForEach(filteredTransactions.prefix(10)) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Report Card

struct ReportCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.title2).bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

// MARK: - Category Spending Row

struct CategorySpendingRow: View {
    let item: (category: CategoryType, amount: Double)
    let total: Double

    var body: some View {
        let percentage = total > 0 ? item.amount / total * 100 : 0
        HStack(spacing: 10) {
            Image(systemName: item.category.iconName)
                .foregroundColor(item.category.color == "red" ? .red : item.category.color == "orange" ? .orange : item.category.color == "purple" ? .purple : .green)
                .frame(width: 24)
            Text(item.category.localized).font(.subheadline)
            Spacer()
            Text("\(Money(amount: item.amount).formatted()) (\(String(format: "%.0f", percentage))%)")
                .font(.subheadline).bold()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bar View

struct BarView: View {
    let value: Double
    let label: String
    let color: Color
    let maxValue: Double
    let height: CGFloat

    var body: some View {
        let barHeight = maxValue > 0 ? CGFloat(value / maxValue) * height : 0
        VStack {
            Text("\(value, specifier: "%.0f")").font(.caption2).foregroundColor(.secondary)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 50, height: max(barHeight, 20))
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
