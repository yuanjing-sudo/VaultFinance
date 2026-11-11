import Foundation

// MARK: - Daily Spending Calendar & Streaks

/// A single day's spending roll-up.
struct SpendingDay: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date            // start of day
    var amount: Double        // total spent that day (positive = spent)
    var transactionCount: Int
    var goalMet: Bool         // did spending stay within the daily goal?
    var notes: String

    init(id: UUID = UUID(), date: Date = Date(), amount: Double = 0,
         transactionCount: Int = 0, goalMet: Bool = false, notes: String = "") {
        self.id = id
        self.date = date
        self.amount = amount
        self.transactionCount = transactionCount
        self.goalMet = goalMet
        self.notes = notes
    }

    var dayLabel: String {
        date.formatted(.dateTime.month().day())
    }
    var weekdayLabel: String {
        date.formatted(.dateTime.weekday(.short))
    }
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// Tracks a daily-spending streak: consecutive days where spending met the goal.
struct SpendingStreak: Codable, Identifiable, Hashable {
    let id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?   // most recent day a transaction was recorded
    var dailyGoal: Double       // spending limit per day to keep the streak alive
    var goalMetToday: Bool

    init(id: UUID = UUID(), currentStreak: Int = 0, longestStreak: Int = 0,
         lastActiveDate: Date? = nil, dailyGoal: Double = 50.0, goalMetToday: Bool = false) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.dailyGoal = dailyGoal
        self.goalMetToday = goalMetToday
    }

    var streakStatus: String {
        currentStreak == 0 ? "No streak yet"
            : currentStreak == 1 ? "1-day streak"
            : "\(currentStreak)-day streak 🔥"
    }
}

// MARK: - Streak calculation helper

extension SpendingStreak {
    /// Recalculate the streak from the full list of spending days.
    static func compute(from days: [SpendingDay], dailyGoal: Double) -> SpendingStreak {
        let sorted = days.sorted { $0.date < $1.date }
        let today = Calendar.current.startOfDay(for: Date())

        var current = 0
        var longest = 0
        var temp = 0
        var lastActive: Date? = sorted.last?.date
        var goalMetToday = false

        for day in sorted {
            if day.amount <= dailyGoal {
                temp += 1
                if temp > longest { longest = temp }
                if Calendar.current.isDate(day.date, inSameDayAs: today) {
                    current = temp
                    goalMetToday = true
                }
            } else {
                if Calendar.current.isDate(day.date, inSameDayAs: today) {
                    current = 0
                    goalMetToday = false
                }
                temp = 0
            }
        }

        // If today has no record yet, current streak is the trailing run ending at the last day.
        if !sorted.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            current = temp
        }

        return SpendingStreak(
            currentStreak: current,
            longestStreak: longest,
            lastActiveDate: lastActive,
            dailyGoal: dailyGoal,
            goalMetToday: goalMetToday
        )
    }
}
