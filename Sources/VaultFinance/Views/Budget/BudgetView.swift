import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var searchText = ""
    @State private var showAddCategory = false
    @State private var showProfile = false

    var filteredCategories: [BudgetCategory] {
        guard !searchText.isEmpty else { return storage.categories }
        return storage.categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var totalBudgeted: Double {
        storage.categories.reduce(0) { $0 + $1.budgetedAmount }
    }

    var totalSpent: Double {
        storage.categories.reduce(0) { $0 + $1.spentAmount }
    }

    var totalRemaining: Double {
        storage.categories.reduce(0) { $0 + $1.remaining }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                allocationSummary
                searchBar
                categoryList
            }
        }
        .navigationTitle("Budget")
        .toolbar { toolbarContent }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Monthly Budget")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showProfile = true }) {
                    Text(storage.profile.totalMonthlyIncome > 0
                         ? Money(amount: storage.profile.totalMonthlyIncome).formatted()
                         : "Add income").font(.subheadline).bold()
                }
            }
            if let score = storage.healthScores.last {
                HStack {
                    Text("Financial Health: \(score.score)/100 — \(score.recommendation)").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private var allocationSummary: some View {
        HStack(spacing: 8) {
            SummaryColumn(title: "Budgeted", value: Money(amount: totalBudgeted).formatted())
            SummaryColumn(title: "Spent", value: Money(amount: totalSpent).formatted())
            SummaryColumn(title: "Remaining", value: Money(amount: totalRemaining).formatted())
        }
    }

    private var searchBar: some View {
        TextField("Search categories", text: $searchText)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
    }

    private var categoryList: some View {
        List(filteredCategories) { category in
            CategoryRow(category: category)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation {
                            storage.categories.removeAll { $0.id == category.id }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .listStyle(.plain)
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showAddCategory.toggle() }) {
                Image(systemName: "plus")
            }
        }
    }
}

struct SummaryColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.subheadline).bold()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct CategoryRow: View {
    let category: BudgetCategory

    var body: some View {
        HStack {
            Image(systemName: category.type.iconName)
                .foregroundColor(category.type.color == "red" ? .red : category.type.color == "orange" ? .orange : category.type.color == "purple" ? .purple : .green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name).font(.subheadline).bold()
                if category.isOverBudget {
                    Text("Over by \(Money(amount: category.overBudget).formatted())").font(.caption).foregroundColor(.red)
                } else if category.spentAmount > 0 {
                    Text("\(category.percentUsed, specifier: "%.0f")% used").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Money(amount: category.spentAmount).formatted())").font(.subheadline).bold()
                Text("of \(Money(amount: category.effectiveBudget).formatted())").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
