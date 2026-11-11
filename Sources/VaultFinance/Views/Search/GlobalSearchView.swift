import SwiftUI

// MARK: - Global Search
// One search box across transactions, goals, bills, subscriptions, watchlist,
// challenges and events. Results are grouped and tappable.

struct GlobalSearchView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter
    @State private var query = ""

    struct SearchResult: Identifiable {
        let id = UUID()
        var title: String
        var subtitle: String
        var icon: String
        var color: String
        var tab: AppRouter.Tab
    }

    private var trimmed: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var results: [SearchResult] {
        guard !trimmed.isEmpty else { return [] }
        var out: [SearchResult] = []

        for tx in storage.transactions where matches(tx.title) || matches(tx.notes) {
            out.append(.init(title: tx.title,
                             subtitle: "\(tx.category.localized) · \(Money(amount: tx.amount).formatted())",
                             icon: "cart.fill", color: tx.category.color, tab: .reports))
        }
        for goal in storage.goals where matches(goal.title) {
            out.append(.init(title: goal.title,
                             subtitle: "Goal · \(Money(amount: goal.currentAmount).formatted()) saved",
                             icon: "target", color: "blue", tab: .goals))
        }
        for bill in storage.bills where matches(bill.title) {
            out.append(.init(title: bill.title,
                             subtitle: "Bill · due \(bill.nextDueDate.formatted(.dateTime.month(.abbreviated).day()))",
                             icon: "doc.fill", color: "red", tab: .bills))
        }
        for sub in storage.subscriptions where matches(sub.title) {
            out.append(.init(title: sub.title,
                             subtitle: "Subscription · \(Money(amount: sub.amount).formatted())/\(sub.cycle.localized.lowercased())",
                             icon: "eyes", color: "purple", tab: .subscriptions))
        }
        for item in storage.watchlist where matches(item.symbol) || matches(item.name) {
            out.append(.init(title: item.symbol,
                             subtitle: item.name.isEmpty ? "Watchlist" : item.name,
                             icon: "chart.line.uptrend.xyaxis", color: "green", tab: .markets))
        }
        for challenge in storage.challenges where matches(challenge.title) {
            out.append(.init(title: challenge.title,
                             subtitle: "Challenge · \(Int(challenge.progress * 100))% complete",
                             icon: "flag.checkered", color: "orange", tab: .challenges))
        }
        for event in storage.financialEvents where matches(event.title) {
            out.append(.init(title: event.title,
                             subtitle: "Event · \(event.date.formatted(.dateTime.month(.abbreviated).day()))",
                             icon: "calendar", color: "teal", tab: .events))
        }
        return out
    }

    private func matches(_ text: String) -> Bool {
        text.lowercased().contains(trimmed)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search everything…", text: $query)
                        .textFieldStyle(.plain)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.10)))

                if trimmed.isEmpty {
                    suggestions
                } else if results.isEmpty {
                    VaultEmptyState(icon: "magnifyingglass",
                                    title: "No matches",
                                    message: "Try a merchant, goal, bill, or symbol.")
                } else {
                    Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(results) { result in
                        Button {
                            router.selectTab(result.tab)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(VaultTheme.tint(for: result.color).opacity(0.14))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: result.icon)
                                        .font(.caption)
                                        .foregroundColor(VaultTheme.tint(for: result.color))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title).font(.subheadline).bold()
                                        .foregroundColor(.primary)
                                    Text(result.subtitle).font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.08)))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Search")
        .inlineNavigationTitle()
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Jump to").font(.caption).foregroundColor(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                ForEach(quickLinks) { link in
                    Button {
                        router.selectTab(link.tab)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: link.icon).font(.caption)
                            Text(link.title).font(.caption).bold()
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(VaultTheme.blue.opacity(0.08)))
                        .foregroundColor(VaultTheme.blue)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var quickLinks: [QuickLink] {
        [
            QuickLink(title: "Piggy Bank", icon: "pawprint.fill", tab: .piggyBank),
            QuickLink(title: "Calendar", icon: "calendar", tab: .calendar),
            QuickLink(title: "Goals", icon: "target", tab: .goals),
            QuickLink(title: "Challenges", icon: "flag.checkered", tab: .challenges),
            QuickLink(title: "Tools", icon: "wrench.and.screwdriver.fill", tab: .tools),
            QuickLink(title: "Credit", icon: "creditcard.fill", tab: .credit),
            QuickLink(title: "Watchlist", icon: "chart.line.uptrend.xyaxis", tab: .markets),
            QuickLink(title: "Events", icon: "calendar.badge.clock", tab: .events)
        ]
    }

    struct QuickLink: Identifiable {
        let id = UUID()
        var title: String
        var icon: String
        var tab: AppRouter.Tab
    }
}
