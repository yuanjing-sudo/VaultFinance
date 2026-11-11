import Foundation
import SwiftUI

// MARK: - Navigation Model with Breadcrumbs

@MainActor
class NavigationModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var rootProfile: UserProfile?
    @Published var showOnboarding = true
    
    // Breadcrumbs trail
    @Published var breadcrumbs: [String] = []
    
    init() {
        // Load stored profile if exists
        let stored = UserDefaults.standard.data(forKey: "saved_profile")
        if let storedData = stored, let decoded = try? JSONDecoder().decode(UserProfile.self, from: storedData) {
            rootProfile = decoded
        }
    }
    
    var currentDestination: String {
        // Extract last meaningful destination from path
        if path.isEmpty { return "Home" }
        let last = path.last?.rawValue ?? "Home"
        return last
    }
    
    func navigate(to destination: String) {
        path.append(NavigationDestination(rawValue: destination))
        updateBreadcrumbs(for: destination)
    }
    
    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
        // Update breadcrumbs based on new path state
        rebuildBreadcrumbs()
    }
    
    func resetToRoot() {
        path.removeLast(path.count)
        breadcrumbs = ["Home"]
    }
    
    private func updateBreadcrumbs(for destination: String) {
        if breadcrumbs.isEmpty || breadcrumbs.last != destination {
            breadcrumbs.append(destination)
        }
    }
    
    private func rebuildBreadcrumbs() {
        // Rebuild based on current path
        breadcrumbs = []
        var temp = "Home"
        breadcrumbs.append(temp)
        for destination in path.map { $0.rawValue } {
            temp = destination
            breadcrumbs.append(temp)
        }
    }
    
    func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "saved_profile")
            rootProfile = profile
        }
    }
}

enum NavigationDestination: Hashable {
    case home
    case budget
    case profile(UserProfile)
    case calendar(Date) // specific date for calendar
    case spendingDetail(Transaction)
    case goals
    case assets
    case aiChat
    case learn
    case achievements
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .home: hasher.combine(0)
        case .budget: hasher.combine(1)
        case .profile(let p): hasher.combine(p.id)
        case .calendar(let d): hasher.combine(d)
        case .spendingDetail(let t): hasher.combine(t.id)
        case .goals: hasher.combine(2)
        case .assets: hasher.combine(3)
        case .aiChat: hasher.combine(4)
        case .learn: hasher.combine(5)
        case .achievements: hasher.combine(6)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Profile Edit View Model

@MainActor
class ProfileEditViewModel: ObservableObject {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storage: LocalStorage
    
    @Published var age: Int
    @Published var monthlyIncome: Double
    @Published var employmentStatus: UserProfile.EmploymentStatus
    @Published var country: String
    @Published var notes: String
    
    init(storage: LocalStorage) {
        self.storage = storage
        self.age = storage.profile.age ?? 25
        self.monthlyIncome = storage.profile.totalMonthlyIncome
        self.employmentStatus = storage.profile.employmentStatus
        self.country = storage.profile.country ?? "US"
        self.notes = storage.profile.notes
    }
    
    var isValid: Bool {
        age >= 0 && monthlyIncome >= 0
    }
    
    func save() {
        var profile = storage.profile
        profile.age = age > 0 ? age : nil
        profile.totalMonthlyIncome = monthlyIncome
        profile.employmentStatus = employmentStatus
        profile.country = country
        profile.notes = notes
        storage.save() // This saves everything
        dismiss()
    }
}

// MARK: - Calendar View Model

@MainActor
class SpendingCalendarViewModel: ObservableObject {
    @EnvironmentObject var storage: LocalStorage
    @Published var selectedDate: Date = Date()
    @Published var streakCount: Int = 0
    @Published var currentGoalStreak: Int = 0
    
    var calendarGrid: [[Date]] {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfDay(for: selectedDate)
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        let daysInMonth = range.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) // 1 = Sunday
        
        var grid: [[Date]] = []
        var week: [Date] = []
        
        // Add empty days from previous month (placeholders)
        for _ in 0..<firstWeekday {
            week.append(Date.distantPast)
        }
        
        // Add days of current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                week.append(date)
                if week.count == 7 {
                    grid.append(week)
                    week = []
                }
            }
        }
        
        // Pad remaining days
        while week.count < 7 {
            week.append(Date.distantFuture)
        }
        if !week.isEmpty {
            grid.append(week)
        }
        
        return grid
    }
    
    func spendingForDate(_ date: Date) -> Double {
        let calendar = Calendar.current
        let transactionsForDay = storage.transactions.filter { 
            calendar.isDate($0.date, inSameDayAs: date) 
        }
        return transactionsForDay.reduce(0) { $0 + $1.amount }
    }
    
    func hasSpentToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedStart = Calendar.current.startOfDay(for: selectedDate)
        return calendar.isDate(selectedDate, inSameDayAs: today)
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var consecutiveDays = 0
        var checkDate = today
        
        while true {
            let hasTransactions = storage.transactions.contains { transaction in
                calendar.isDate(transaction.date, inSameDayAs: checkDate)
            }
            
            if hasTransactions {
                consecutiveDays += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? today
                // Stop if we go too far back (more than a year)
                if calendar.dateComponents([.year], from: checkDate, to: today).year! > 1 {
                    break
                }
            } else if consecutiveDays > 0 {
                // We had a break in the streak
                break
            } else {
                // No transactions today, streak is 0
                break
            }
            
            // Safety limit
            if consecutiveDays > 365 {
                break
            }
        }
        
        streakCount = consecutiveDays
        currentGoalStreak = consecutiveDays >= 7 ? consecutiveDays : 0
    }
}