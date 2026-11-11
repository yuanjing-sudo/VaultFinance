import SwiftUI

struct Sidebar: View {
    @EnvironmentObject private var navigation: NavigationModel
    @EnvironmentObject private var storage: LocalStorage

    var body: some View {
        List {
            Section {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(Text("V").fontWeight(.bold).foregroundColor(.blue))
                    VStack(alignment: .leading) {
                        Text("Vault")
                            .font(.headline)
                        Text(Money(amount: storage.profile.totalMonthlyIncome).formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section("Navigation") {
                NavigationLink("Home") { HomeView() }
                NavigationLink("Budget") { BudgetView() }
                NavigationLink("Calendar") { SpendingCalendarView() }
                NavigationLink("Learn") { LearnView() }
                NavigationLink("Profile") { ProfileView() }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(width: 220)
        .background(Color(white: 0.97))
    }
}

struct LegacyContentView: View {
    var body: some View {
        HomeView()
    }
}
