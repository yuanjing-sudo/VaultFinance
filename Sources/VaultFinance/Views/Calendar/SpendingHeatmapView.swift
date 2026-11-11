import SwiftUI

// MARK: - Spending Heatmap
// A GitHub-style calendar heatmap of daily spending, paired with streak
// statistics and best/worst day insights.

struct SpendingHeatmapView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var selectedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthDays: [SpendingDay] {
        storage.spendingDays
            .filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
            .sorted { $0.date < $1.date }
    }

    private var goal: Double { storage.spendingStreak.dailyGoal }

    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var maxSpend: Double { max(monthDays.map { $0.amount }.max() ?? 1, 1) }

    private var cells: [HeatmapCell] {
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let first = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: first) - 1
        var result: [HeatmapCell] = []
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: first) else { continue }
            let spend = monthDays.first { calendar.isDate($0.date, inSameDayAs: date) }?.amount ?? 0
            let index = firstWeekday + day - 1
            result.append(HeatmapCell(
                row: index / 7,
                col: index % 7,
                intensity: spend > 0 ? min(spend / maxSpend, 1) : 0,
                label: "\(day)",
                detail: Money(amount: spend).formatted()
            ))
        }
        return result
    }

    private var monthTotal: Double { monthDays.reduce(0) { $0 + $1.amount } }
    private var daysMet: Int { monthDays.filter { $0.amount <= goal }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                streakCard
                heatmapCard
                legend
                bestWorstCard
                dayListCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Spending Heatmap")
        .inlineNavigationTitle()
    }

    private var headerCard: some View {
        VaultGradientCard(gradient: VaultTheme.sunsetGradient) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button { shift(-1) } label: {
                        Image(systemName: "chevron.left").foregroundColor(.white)
                    }
                    Spacer()
                    Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline).bold()
                    Spacer()
                    Button { shift(1) } label: {
                        Image(systemName: "chevron.right").foregroundColor(.white)
                    }
                }
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent").font(.caption2).opacity(0.9)
                        Text(Money(amount: monthTotal).formatted()).font(.subheadline).bold()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Days on goal").font(.caption2).opacity(0.9)
                        Text("\(daysMet)/\(monthDays.count)").font(.subheadline).bold()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily goal").font(.caption2).opacity(0.9)
                        Text(Money(amount: goal).formatted()).font(.subheadline).bold()
                    }
                }
            }
        }
    }

    private var streakCard: some View {
        VaultCard {
            HStack(spacing: 16) {
                AnimatedStreakFlame(streak: storage.spendingStreak.currentStreak)
                    .frame(width: 70, height: 70)
                VStack(alignment: .leading, spacing: 4) {
                    Text(storage.spendingStreak.streakStatus)
                        .font(.headline).bold()
                    Text("Longest: \(storage.spendingStreak.longestStreak) days")
                        .font(.caption).foregroundColor(.secondary)
                    Text(storage.spendingStreak.goalMetToday
                         ? "Today's goal met ✓"
                         : "Under \(Money(amount: goal).formatted()) today to keep it alive")
                        .font(.caption2)
                        .foregroundColor(storage.spendingStreak.goalMetToday ? VaultTheme.green : VaultTheme.orange)
                }
                Spacer()
            }
        }
    }

    private var heatmapCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Daily Spending", subtitle: "Darker = more spent")
                HStack(spacing: 4) {
                    ForEach(weekdayLabels.indices, id: \.self) { i in
                        Text(weekdayLabels[i]).font(.caption2).foregroundColor(.secondary)
                            .frame(width: 18)
                    }
                }
                VaultHeatmap(cells: cells,
                             rows: max((cells.map { $0.row }.max() ?? 0) + 1, 1),
                             columns: 7,
                             tint: VaultTheme.orange,
                             cellSize: 34)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less").font(.caption2).foregroundColor(.secondary)
            ForEach([0.08, 0.3, 0.5, 0.7, 1.0], id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(VaultTheme.orange.opacity(level))
                    .frame(width: 14, height: 14)
            }
            Text("More").font(.caption2).foregroundColor(.secondary)
            Spacer()
        }
    }

    private var bestWorstCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Highlights")
                if let best = monthDays.min(by: { $0.amount < $1.amount }),
                   let worst = monthDays.max(by: { $0.amount < $1.amount }) {
                    HStack(spacing: 12) {
                        highlight("Lowest day", best.amount,
                                  best.date.formatted(.dateTime.month(.abbreviated).day()),
                                  VaultTheme.green, "arrow.down.circle.fill")
                        highlight("Highest day", worst.amount,
                                  worst.date.formatted(.dateTime.month(.abbreviated).day()),
                                  VaultTheme.red, "arrow.up.circle.fill")
                    }
                } else {
                    Text("No spending recorded this month.").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private func highlight(_ title: String, _ amount: Double, _ date: String,
                           _ color: Color, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption).foregroundColor(color)
                Text(title).font(.caption2).foregroundColor(.secondary)
            }
            Text(Money(amount: amount).formatted()).font(.subheadline).bold()
            Text(date).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
    }

    private var dayListCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 8) {
                VaultSectionHeader(title: "Day by Day")
                ForEach(monthDays.reversed()) { day in
                    HStack(spacing: 10) {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated).day()))
                            .font(.caption2).frame(width: 64, alignment: .leading)
                        VaultProgressBar(progress: min(day.amount / maxSpend, 1),
                                         height: 6,
                                         gradient: day.amount <= goal
                                            ? VaultTheme.savingsGradient : VaultTheme.warningGradient)
                        Text(Money(amount: day.amount).formatted())
                            .font(.caption2).frame(width: 66, alignment: .trailing)
                        Image(systemName: day.amount <= goal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(day.amount <= goal ? VaultTheme.green : VaultTheme.orange)
                    }
                }
            }
        }
    }

    private func shift(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: selectedMonth) {
            withAnimation { selectedMonth = d }
        }
    }
}
