import SwiftUI

// MARK: - Spending Calendar + Streak Tracking

/// Calendar that tracks everyday spending and rewards streaks when daily goals are met.
struct SpendingCalendarView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter

    @State private var selectedDate = Date()
    @State private var showingAdd = false

    var days: [SpendingDay] {
        storage.spendingDays.sorted { $0.date < $1.date }
    }

    var streak: SpendingStreak { storage.spendingStreak }

    private var currentLevel: Int { 1 + (streak.currentStreak * 10 + Int(streak.dailyGoal)) / 100 }
    private var levelProgress: Double {
        let raw = Double((streak.currentStreak * 10 + Int(streak.dailyGoal)) % 100)
        return min(max(raw / 100.0, 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                questCard
                    .transition(.scale.combined(with: .opacity))

                streakCard
                    .transition(.opacity.combined(with: .move(edge: .top)))

                goalControl
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                calendarGrid
                    .transition(.scale.combined(with: .opacity))

                recentDaysList
            }
            .padding()
        }
        .navigationTitle("Spending Calendar")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddSpendingDayView()
        }
    }

    private var questCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Finance Quest")
                        .font(.headline).bold()
                    Text("Level \(currentLevel) • " + (streak.goalMetToday ? "Quest complete" : "Keep your streak alive"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                }
            }
            ProgressView(value: levelProgress)
                .tint(.orange)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: levelProgress)
            HStack(spacing: 8) {
                BadgePill(icon: "flame.fill", label: "XP +\(streak.currentStreak * 10)")
                BadgePill(icon: "checkmark.seal.fill", label: streak.goalMetToday ? "Goal met" : "Goal pending")
                BadgePill(icon: "trophy.fill", label: "Best \(streak.longestStreak)")
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.orange.opacity(0.18), Color.green.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending Streak")
                        .font(.headline).bold()
                    Text(streak.streakStatus)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(streak.currentStreak > 0 ? .green : .secondary)
                    Text("days").font(.caption2).foregroundColor(.secondary)
                }
            }
            HStack(spacing: 16) {
                StreakPill(title: "Longest", value: "\(streak.longestStreak)", icon: "flame.fill")
                StreakPill(title: "Daily Goal", value: Money(amount: streak.dailyGoal).formatted(), icon: "target")
                StreakPill(title: "Today", value: streak.goalMetToday ? "Goal Met ✅" : "Not Yet", icon: streak.goalMetToday ? "checkmark.circle" : "clock")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    private var goalControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Spending Goal").font(.subheadline).bold()
            HStack {
                TextField("Goal", value: Binding(
                    get: { streak.dailyGoal },
                    set: { storage.spendingStreak.dailyGoal = $0; storage.save() }
                ), format: .currency(code: storage.profile.currency))
                .keyboardType(.decimalPad)
                Text("per day").font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(10)
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Month").font(.headline).bold()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol).font(.caption2).fontWeight(.semibold).foregroundColor(.secondary)
                }
                ForEach(calendarDays, id: \.date) { dayEntry in
                    CalendarDayCell(date: dayEntry.date, spending: dayEntry.spending, isToday: dayEntry.isToday, goalMet: dayEntry.goalMet)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dayEntry.goalMet)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    private var weekdaySymbols: [String] {
        Calendar.current.shortStandaloneWeekdaySymbols
    }

    private var calendarDays: [(date: Date, spending: SpendingDay?, isToday: Bool, goalMet: Bool)] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return [] }

        var result: [(date: Date, spending: SpendingDay?, isToday: Bool, goalMet: Bool)] = []
        var current = monthStart
        // Pad leading days from previous month so the 1st aligns with its weekday.
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        if offset > 0 {
            for i in (0..<offset).reversed() {
                if let d = calendar.date(byAdding: .day, value: -i, to: monthStart) {
                    result.append((date: d, spending: nil, isToday: false, goalMet: false))
                }
            }
        }
        var cursor = monthStart
        while cursor <= monthEnd {
            let day = days.first(where: { calendar.isDate($0.date, inSameDayAs: cursor) })
            result.append((date: cursor, spending: day, isToday: calendar.isDateInToday(cursor), goalMet: day?.goalMet ?? false))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return result
    }

    // MARK: - Recent Days List

    private var recentDaysList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Spending Days").font(.headline).bold()
                Spacer()
            }
            if days.isEmpty {
                EmptyState(message: "No spending days recorded yet. Add your first expense.")
            } else {
                ForEach(days.prefix(12)) { day in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.dayLabel).font(.subheadline).bold()
                            Text(day.weekdayLabel).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-\(Money(amount: day.amount).formatted())")
                                .font(.subheadline).bold()
                                .foregroundColor(day.amount > streak.dailyGoal ? .red : .green)
                            Text("\(day.transactionCount) txn")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let spending: SpendingDay?
    let isToday: Bool
    let goalMet: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .bold(isToday)
                .foregroundColor(isToday ? .blue : .primary)
            if let spending = spending {
                Circle()
                    .fill(spending.goalMet ? Color.green.opacity(0.6) : Color.clear)
                    .frame(width: 8, height: 8)
                Text("-\(spending.amount, specifier: "%.0f")")
                    .font(.caption2)
                    .foregroundColor(spending.goalMet ? .green : .red)
                    .lineLimit(1)
            } else {
                Circle().fill(Color.clear).frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(isToday ? Color.blue.opacity(0.12) : (goalMet ? Color.green.opacity(0.08) : Color.clear))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isToday ? Color.blue : Color.clear, lineWidth: 1.5))
    }
}

// MARK: - Streak Pill

struct StreakPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2).foregroundColor(.green)
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption).bold()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(8)
    }
}

struct BadgePill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Add Spending Day

struct AddSpendingDayView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var title = ""
    @State private var amount: String = ""
    @State private var category: CategoryType = .needsVariable
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Expense")) {
                    TextField("Title (e.g. Groceries)", text: $title)
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        Text(storage.profile.currency).font(.caption).foregroundColor(.secondary)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName).foregroundColor(.blue)
                                Text(type.localized)
                            }
                            .tag(type)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes", text: $notes)
                }
                Section {
                    Button("Record Spending") {
                        let amt = Double(amount) ?? 0
                        guard amt > 0 else { return }
                        storage.recordSpending(date: date, amount: amt, category: category, notes: title)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Record Spending")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
