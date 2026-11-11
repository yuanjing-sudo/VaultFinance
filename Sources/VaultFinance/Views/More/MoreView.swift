import SwiftUI

// MARK: - More Hub
// A single entry point for secondary tools and settings, each opening a
// dedicated deep screen.

struct MoreView: View {
    @EnvironmentObject var storage: LocalStorage

    private struct MoreLink: Identifiable {
        let id = UUID()
        var title: String
        var subtitle: String
        var icon: String
        var color: String
    }

    private var links: [MoreLink] {
        [
            .init(title: "Spending Heatmap", subtitle: "Your daily spending as a calendar", icon: "square.grid.3x3.fill", color: "orange"),
            .init(title: "Net Worth Timeline", subtitle: "Track wealth across snapshots", icon: "chart.xyaxis.line", color: "green"),
            .init(title: "Achievements", subtitle: "Badges and milestones", icon: "trophy.fill", color: "gold"),
            .init(title: "Reminders", subtitle: "Never miss a money task", icon: "bell.fill", color: "purple"),
            .init(title: "Round-Ups", subtitle: "Spare change into savings", icon: "arrow.up.circle.fill", color: "teal"),
            .init(title: "Recurring Transactions", subtitle: "Automate repeat items", icon: "arrow.clockwise.circle.fill", color: "pink"),
            .init(title: "Export Data", subtitle: "Share a portable CSV", icon: "square.and.arrow.up", color: "blue"),
            .init(title: "Appearance", subtitle: "Accent, motion, currency", icon: "paintpalette.fill", color: "red")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.sunsetGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("More").font(.caption).opacity(0.9)
                        Text("Tools, milestones & settings").font(.title3).bold()
                        Text("Everything else, one tap away").font(.caption2).opacity(0.9)
                    }
                }

                ForEach(links) { link in
                    NavigationLink {
                        destination(for: link.title)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(VaultTheme.tint(for: link.color).opacity(0.14))
                                    .frame(width: 46, height: 46)
                                Image(systemName: link.icon)
                                    .foregroundColor(VaultTheme.tint(for: link.color))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(link.title).font(.subheadline).bold()
                                    .foregroundColor(.primary)
                                Text(link.subtitle).font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.08)))
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                dataCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("More")
        .inlineNavigationTitle()
    }

    @ViewBuilder
    private func destination(for title: String) -> some View {
        switch title {
        case "Spending Heatmap": SpendingHeatmapView()
        case "Net Worth Timeline": NetWorthTimelineView()
        case "Achievements": AchievementsView()
        case "Reminders": RemindersView()
        case "Round-Ups": RoundUpView()
        case "Recurring Transactions": RecurringTransactionsView()
        case "Export Data": ExportView()
        case "Appearance": ThemeSettingsView()
        default: RouteDestinationView(route: .settings)
        }
    }

    private var dataCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 8) {
                VaultSectionHeader(title: "Your Vault")
                row("Transactions", "\(storage.transactions.count)")
                row("Goals", "\(storage.goals.count)")
                row("Bills", "\(storage.bills.count)")
                row("Subscriptions", "\(storage.subscriptions.count)")
                row("Piggy deposits", "\(storage.piggyDeposits.count)")
                row("Spending days logged", "\(storage.spendingDays.count)")
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).bold()
        }
    }
}
