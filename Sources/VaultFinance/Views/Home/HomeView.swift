import SwiftUI

struct HomeView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var aiService: AIService
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                netWorthCard
                budgetOverview
                savingsGoals
                recentTransactions
                dailyLearning
                aiInsights
            }
            .padding()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, let's build wealth.").bold().font(.headline)
                Text("Your financial companion").foregroundColor(.secondary)
            }
            Spacer()
            Circle()
                .fill(Color.blue)
                .frame(width: 48, height: 48)
                .overlay(
                    Text("V").foregroundColor(.white).bold()
                )
        }
    }

    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Net Worth")
                    .bold()
                    .font(.headline)
                Spacer()
                if let score = storage.healthScores.last {
                    VStack(alignment: .trailing) {
                        Text("\(score.score)/100")
                            .bold()
                        Text("Financial Health")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Text(storage.liabilities.isEmpty
                 ? Money(amount: storage.assets.reduce(0) { $0 + $1.currentMarketValue }).formatted()
                 : Money(amount: FinanceEngine.computeNetWorth(assets: storage.assets, liabilities: storage.liabilities, cashInBank: storage.profile.existingSavings, savingsAccounts: 0).netWorth).formatted()
            )
            .font(.title)
            .bold()
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
            HStack {
                StatCard(label: "Income", value: Money(amount: storage.profile.totalMonthlyIncome).formatted(), trend: "+2.1%", positive: true)
                StatCard(label: "Saved", value: Money(amount: storage.assets.reduce(0) { $0 + $1.currentMarketValue }).formatted(), trend: "+5.4%", positive: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var budgetOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget Overview").bold().font(.headline)
                Spacer()
                Text("This month").foregroundColor(.secondary)
            }
            ForEach(storage.categories.prefix(4)) { category in
                BudgetBar(category: category)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var savingsGoals: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Savings Goals").bold().font(.headline)
                Button("View All") { }
            }
            ForEach(storage.goals) { goal in
                GoalCard(goal: goal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Transactions").bold().font(.headline)
                Button("View All") { }
            }
            ForEach(storage.transactions.prefix(5)) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var dailyLearning: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Daily Learning").bold().font(.headline)
                Spacer()
                Text("Streak: 3 days 🔥").foregroundColor(.orange)
            }
            ForEach(storage.lessons.prefix(2)) { lesson in
                if !lesson.locked {
                    LessonCard(lesson: lesson)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var aiInsights: some View {
        VStack(spacing: 8) {
            HStack {
                Text("AI Insights").bold().font(.headline)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
            }
            Text("Your food spending is 8% above your monthly average. Consider tracking receipts more closely.")
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Subcomponents

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

struct BudgetBar: View {
    let category: BudgetCategory

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(category.name).font(.subheadline)
                Spacer()
                Text("\(Money(amount: category.spentAmount).formatted()) / \(Money(amount: category.budgetedAmount).formatted())")
                    .font(.caption)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                        .cornerRadius(4)
                    Rectangle()
                        .fill(category.color == "red" ? Color.red : category.color == "orange" ? Color.orange : category.color == "purple" ? Color.purple : Color.green)
                        .frame(width: min(geo.size.width * (category.percentUsed / 100), geo.size.width))
                        .frame(height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}

struct GoalCard: View {
    let goal: FinancialGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.title).font(.subheadline).bold()
                Spacer()
                Text("\(goal.percentComplete, specifier: "%.0f")%")
                    .font(.caption)
                    .bold()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                        .cornerRadius(4)
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: min(geo.size.width * (goal.percentComplete / 100), geo.size.width))
                        .frame(height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
            HStack {
                Text("Saved: \(Money(amount: goal.currentAmount).formatted())").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("Target: \(Money(amount: goal.targetAmount).formatted())").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title).font(.subheadline)
                Text(transaction.date, style: .date).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(transaction.amount < 0 ? "+\(transaction.amount.formattedAmount)" : "-\(transaction.amount.formattedAmount)")
                .font(.subheadline)
                .bold()
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct LessonCard: View {
    let lesson: Lesson

    var body: some View {
        HStack {
            Image(systemName: lesson.difficulty == .beginner ? "star.fill" : lesson.difficulty == .intermediate ? "star.fill" : "star.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title).font(.subheadline).bold()
                Text(lesson.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(lesson.xp) XP").font(.caption).bold().foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct EmptyState: View {
    let message: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message).foregroundColor(.secondary)
        }
    }
}
