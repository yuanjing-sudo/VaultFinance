import SwiftUI

// MARK: - Category Detail (deep navigation destination)

struct CategoryDetailView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter

    let category: BudgetCategory

    var transactionsForCategory: [Transaction] {
        storage.transactions.filter { $0.categoryId == category.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(category.name).font(.title2).bold()

                HStack(spacing: 16) {
                    StatCard(label: "Budgeted", value: Money(amount: category.budgetedAmount).formatted())
                    StatCard(label: "Spent", value: Money(amount: category.spentAmount).formatted())
                    StatCard(label: "Remaining", value: Money(amount: category.remaining).formatted())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Transactions").font(.headline).bold()
                    if transactionsForCategory.isEmpty {
                        EmptyState(message: "No transactions in this category yet.")
                    } else {
                        ForEach(transactionsForCategory) { tx in
                            TransactionRow(transaction: tx)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
