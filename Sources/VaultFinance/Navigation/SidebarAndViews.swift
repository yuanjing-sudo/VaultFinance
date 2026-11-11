import SwiftUI

// MARK: - Sidebar View

struct Sidebar: View {
    @EnvironmentObject var navigation: NavigationModel
    @EnvironmentObject var storage: LocalStorage
    @State private var selectedTab = 0
    
    // Sidebar width and state
    @State private var isMenuExpanded = true
    @Namespace private var animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Vault")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding()
                
                // User profile summary in sidebar
                if let profile = storage.profile as? UserProfile {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(profile.age.map(String.init) ?? "-")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.country ?? "US")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(profile.totalMonthlyIncome))/month")
                                .font(.subheadline)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                Divider()
            }
            
            // Navigation items
            VStack(alignment: .leading, spacing: 8) {
                ForEach(navigation.breadcrumbs.dropFirst(), id: \ .self) { destination in
                    NavigationLink(destination: destinationLabel(for: destination), 
                                   tag: destination,
                                   selection: $navigation.path.isEmpty ? nil : nil) { label in
                        label
                            .font(.system(size: 16, weight: selectedTab == breadcrumbsIndex(for: destination) ? .medium : .regular))
                            .foregroundColor(selectedTab == breadcrumbsIndex(for: destination) ? .blue : .primary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedTab == breadcrumbsIndex(for: destination) ? Color.blue.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Logout or onboarding button
                Button(action: { navigation.resetToRoot() }) {
                    HStack {
                        Image(systemName: "door.left.hand.closed")
                        Text("Reset")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 220)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
            , alignment: .leading
        )
    }
    
    // Map destination string to view builder
    @ViewBuilder
    func destinationLabel(for destination: String) -> some View {
        switch destination {
        case "Home": HomeView()
        case "Budget": BudgetView()
        case "Profile": ProfileEditView()
        case "Calendar": CalendarSpendingView()
        case "Goals": GoalsView()
        case "Assets": AssetListView()
        case "AI": AIView()
        case "Learn": LearnView()
        case "Achievements": AchievementsView()
        default: HomeView()
        }
    }
    
    // Index of destination in breadcrumbs for highlighting
    func breadcrumbsIndex(for destination: String) -> Int {
        navigation.breadcrumbs.firstIndex(of: destination) ?? 0
    }
}

// MARK: - Home View with Sidebar Integration

struct ContentView: View {
    @EnvironmentObject var navigation: NavigationModel
    @EnvironmentObject var storage: LocalStorage
    @State private var showingProfileEditor = false
    
    var body: some View {
        if navigation.showOnboarding {
            OnboardingView()
                .environmentObject(storage)
                .environmentObject(navigation)
        } else {
            VStack(alignment: .leading) {
                // Top bar with navigation
                HStack {
                    Button(action: { navigation.navigateBack() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text(navigation.currentDestination)
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: { showingProfileEditor = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                // Breadcrumbs trail
                if navigation.breadcrumbs.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(navigation.breadcrumbs.dropFirst(), id: \ .self) { crumb in
                            Text(crumb)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            + Text(" > ")
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.bottom, 4)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Dashboard cards
                        HStack(spacing: 16) {
                            StatCard(label: "Income", value: Money(amount: storage.profile.totalMonthlyIncome).formatted(), trend: "+2.1%", positive: true)
                            StatCard(label: "Saved", value: Money(amount: storage.assets.reduce(0) { $0 + $1.currentMarketValue }).formatted(), trend: "+5.4%", positive: true)
                        }
                        
                        // Quick stats grid
                        HStack(spacing: 16) {
                            StatCard(label: "Budget", value: "\(storage.categories.count) categories", trend: "", positive: false)
                            StatCard(label: "Goals", value: "\(storage.goals.filter(\\.isComplete).count) complete", trend: "", positive: false)
                            StatCard(label: "Streak", value: "\(navigation.breadcrumbs.last == "Calendar" ? "7 days" : "0 days")", trend: "", positive: false)
                        }
                        
                        // Quick links grid
                        VStack(spacing: 16) {
                            NavigationLink(destination: BudgetView().environmentObject(storage).environmentObject(navigation)) {
                                HStack {
                                    Image(systemName: "square.grid.2x2")
                                    Text("Budget")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            NavigationLink(destination: CalendarSpendingView().environmentObject(storage).environmentObject(navigation)) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Spending Calendar")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            NavigationLink(destination: ProfileEditView().environmentObject(storage).environmentObject(navigation)) {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                    Text("Profile")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            NavigationLink(destination: GoalsView().environmentObject(storage).environmentObject(navigation)) {
                                HStack {
                                    Image(systemName: "target")
                                    Text("Goals")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingProfileEditor) {
                ProfileEditView()
                    .environmentObject(storage)
                    .environmentObject(navigation)
            }
        }
    }
}

// MARK: - Subviews

struct StatCard: View {
    let label: String
    let value: String
    let trend: String
    let positive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.subheadline).bold()
            Text(trend).font(.caption).foregroundColor(positive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// Profile Edit View
struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var navigation: NavigationModel
    @State private var age: Int
    @State private var monthlyIncome: Double
    @State private var employmentStatus: UserProfile.EmploymentStatus
    @State private var country: String
    @State private var notes: String
    
    init() {
        let profile = storage.profile
        _age = State(initialValue: profile.age ?? 25)
        _monthlyIncome = State(initialValue: profile.totalMonthlyIncome)
        _employmentStatus = State(initialValue: profile.employmentStatus)
        _country = State(initialValue: profile.country ?? "US")
        _notes = State(initialValue: profile.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Info")) {
                    Stepper("Age: \(age)", value: $age.inRange(0...120))
                    Picker("Employment", selection: $employmentStatus) {
                        ForEach(UserProfile.EmploymentStatus.allCases) { status in
                            Text(status.localized).tag(status)
                        }
                    }
                    TextField("Country", text: $country)
                    TextField("Notes", text: $notes)
                }
                
                Section(header: Text("Income")) {
                    TextField("Monthly Income", value: $monthlyIncome, format: .currency)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("Save Profile") {
                        var profile = storage.profile
                        profile.age = age > 0 ? age : nil
                        profile.totalMonthlyIncome = monthlyIncome
                        profile.employmentStatus = employmentStatus
                        profile.country = country
                        profile.notes = notes
                        storage.save()
                        navigation.saveProfile(profile)
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// Range extension for Stepper
extension Binding where Value == Int {
    func inRange(_ range: ClosedRange<Int>) -> some View {
        BoundRange(value: self, range: range)
    }
}

struct BoundRange: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack {
            Stepper("", value: $value, in: range, step: 1)
            Text("\(value)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Calendar Spending View
struct CalendarSpendingView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var navigation: NavigationModel
    @StateObject var viewModel = SpendingCalendarViewModel()
    @State private var showingAddTransaction = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Calendar selector and streak info
                HStack {
                    Text("\(Calendar.current.component(.month, from: viewModel.selectedDate))/\(Calendar.current.component(.year, from: viewModel.selectedDate))")
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    // Streak info
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.streakCount) day\(viewModel.streakCount != 1 ? "s" : "") streak")
                            .font(.subheadline)
                            .foregroundColor(viewModel.streakCount >= 7 ? .green : .primary)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.calendarGrid, id: \ .self) { week in
                            HStack(spacing: 12) {
                                ForEach(week, id: \ .self) { date in
                                    CalendarDayView(date: date, 
                                                    spending: viewModel.spendingForDate(date),
                                                    isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                                                    onSelect: { viewModel.selectedDate = date })
                                        .frameWidth(40)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Add transaction button
                Button(action { showingAddTransaction = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Spending for \(viewModel.hasSpentToday ? "Today" : "\(Calendar.current.component(.day, from: viewModel.selectedDate))th")")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Spending Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .environmentObject(storage)
            }
            .onAppear { viewModel.updateStreak() }
        }
    }
}

// Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let spending: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    var day: String {
        Calendar.current.component(.day, from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected || isToday ? .blue : .primary)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .onTapGesture(perform: onSelect)
            
            if spending != 0 {
                Text(Money(amount: spending).formatted())
                    .font(.caption2)
                    .foregroundColor(spending > 0 ? .red : .green)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// Add Transaction View
struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var navigation: NavigationModel
    @State private var title = ""
    @State private var amount: Double = 0
    @State private var category: CategoryType = .wants
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Title", text: $title)
                    Stepper("Amount: \(String(format: "%.2f", amount))", value: $amount)
                    Picker("Category", selection: $category) {
                        ForEach(CategoryType.allCases) { type in
                            Text(type.localized).tag(type)
                        }
                    }
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section {
                    Button("Add Transaction") {
                        let transaction = Transaction(
                            title: title.isEmpty ? "New Transaction" : title,
                            amount: amount,
                            categoryId: UUID(),
                            category: category,
                            date: Date(),
                            notes: notes
                        )
                        storage.transactions.append(transaction)
                        storage.save()
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// Achievements View
struct AchievementsView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var navigation: NavigationModel
    @StateObject var calendarViewModel = SpendingCalendarViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(storage.achievements) { achievement in
                    AchievementCard(achievement: achievement)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                calendarViewModel.updateStreak()
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocalStorage.shared)
            .environmentObject(NavigationModel())
    }
}