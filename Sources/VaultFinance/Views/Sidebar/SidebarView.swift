import SwiftUI

// MARK: - Sidebar Navigation

struct SidebarView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        List {
            Section(header: Text("Overview").font(.headline).bold()) {
                SidebarRow(tab: .home)
                SidebarRow(tab: .dashboard)
                SidebarRow(tab: .search)
            }
            Section(header: Text("Money").font(.headline).bold()) {
                SidebarRow(tab: .budget)
                SidebarRow(tab: .calendar)
                SidebarRow(tab: .wealth)
                SidebarRow(tab: .piggyBank)
                SidebarRow(tab: .goals)
                SidebarRow(tab: .bills)
                SidebarRow(tab: .subscriptions)
            }
            Section(header: Text("Grow").font(.headline).bold()) {
                SidebarRow(tab: .analytics)
                SidebarRow(tab: .reports)
                SidebarRow(tab: .credit)
                SidebarRow(tab: .challenges)
                SidebarRow(tab: .markets)
                SidebarRow(tab: .events)
                SidebarRow(tab: .tools)
            }
            Section(header: Text("Learn & Stay Informed").font(.headline).bold()) {
                SidebarRow(tab: .learn)
                SidebarRow(tab: .news)
                SidebarRow(tab: .indicators)
            }
            Section(header: Text("Account").font(.headline).bold()) {
                SidebarRow(tab: .profile)
                SidebarRow(tab: .settings)
                SidebarRow(tab: .more)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}

struct SidebarRow: View {
    @EnvironmentObject var router: AppRouter
    let tab: AppRouter.Tab

    var isSelected: Bool { router.selectedTab == tab }

    var body: some View {
        Button {
            router.selectTab(tab)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .frame(width: 24)
                Text(tab.label)
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
