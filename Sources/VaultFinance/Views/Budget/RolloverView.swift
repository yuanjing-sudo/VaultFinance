import SwiftUI

struct RolloverView: View {
    @EnvironmentObject var storage: LocalStorage
    @StateObject private var viewModel = RolloverViewModel()
    @State private var selectedCategory: BudgetCategory?
    @State private var showRolloverSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.carryoverItems.isEmpty {
                    EmptyState(message: "No carryover from previous month.")
                } else {
                    List {
                        ForEach(viewModel.carryoverItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.title).bold()
                                    Spacer()
                                    Text(item.amount.formatted()).bold().foregroundColor(.green)
                                }
                                Text(item.direction.localized).font(.caption).foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    Button("Keep Carryover") {
                                        viewModel.keepItem(item)
                                    }
                                    Button("Move to Savings") {
                                        viewModel.saveItem(item)
                                    }
                                    Button("Apply to Goal") {
                                        viewModel.applyToGoal(item)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Rollover")
        }
    }
}

class RolloverViewModel: ObservableObject {
    @Published var carryoverItems: [RolloverItem] = []

    func keepItem(_ item: RolloverItem) {
        carryoverItems.removeAll { $0.id == item.id }
    }

    func saveItem(_ item: RolloverItem) {
        // Logic: transfer to savings category
        carryoverItems.removeAll { $0.id == item.id }
    }

    func applyToGoal(_ item: RolloverItem) {
        // Logic: add to first open goal
        carryoverItems.removeAll { $0.id == item.id }
    }
}

struct RolloverItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let amount: Money
    let direction: RolloverDirection
    let sourceCategoryId: UUID
}
