import SwiftUI

// MARK: - App Router (smooth navigation + deep breadcrumbs)

// Central navigation state. One navigation path + route stack per tab so each tab
// keeps its own deep history, and a shared breadcrumb trail reflects the active tab.
@MainActor
class AppRouter: ObservableObject {
    enum Tab: String, CaseIterable, Hashable, Identifiable {
        case home, budget, calendar, wealth, learn, news, indicators, piggyBank, analytics, bills, subscriptions, reports, profile, settings

        var id: String { rawValue }

        var label: String {
            switch self {
            case .home: return "Home"
            case .budget: return "Budget"
            case .calendar: return "Calendar"
            case .wealth: return "Wealth"
            case .learn: return "Learn"
            case .news: return "News"
            case .indicators: return "Indicators"
            case .piggyBank: return "Piggy Bank"
            case .analytics: return "Analytics"
            case .bills: return "Bills"
            case .subscriptions: return "Subscriptions"
            case .reports: return "Reports"
            case .profile: return "Profile"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .budget: return "list.bullet.rectangle"
            case .calendar: return "calendar"
            case .wealth: return "chart.bar.fill"
            case .learn: return "graduationcap.fill"
            case .news: return "newspaper.fill"
            case .indicators: return "gauge"
            case .piggyBank: return "pawprint.fill"
            case .analytics: return "chart.pie.fill"
            case .bills: return "doc.fill"
            case .subscriptions: return "eyes"
            case .reports: return "chart.bar.doc.horizontal"
            case .profile: return "person.fill"
            case .settings: return "gear"
            }
        }
    }

    /// One NavigationPath per tab drives actual SwiftUI navigation.
    @Published var paths: [Tab: NavigationPath] = [:]
    /// Parallel route stacks per tab drive breadcrumb display.
    @Published var stacks: [Tab: [Route]] = [:]
    /// Computed breadcrumb trail for the currently selected tab.
    @Published var breadcrumbs: [BreadcrumbItem] = []
    @Published var selectedTab: Tab = .home

    init() {
        for tab in Tab.allCases {
            paths[tab] = NavigationPath()
            stacks[tab] = [.home] // every tab roots at Home
        }
        rebuildBreadcrumbs()
    }

    // MARK: - Mutations

    func push(_ route: Route) {
        var path = paths[selectedTab] ?? NavigationPath()
        var stack = stacks[selectedTab] ?? [.home]
        path.append(route)
        stack.append(route)
        paths[selectedTab] = path
        stacks[selectedTab] = stack
        rebuildBreadcrumbs()
    }

    func pop() {
        var path = paths[selectedTab] ?? NavigationPath()
        var stack = stacks[selectedTab] ?? [.home]
        guard stack.count > 1 else { return } // never pop the root
        path.removeLast()
        stack.removeLast()
        paths[selectedTab] = path
        stacks[selectedTab] = stack
        rebuildBreadcrumbs()
    }

    func popToRoot() {
        paths[selectedTab] = NavigationPath()
        stacks[selectedTab] = [.home]
        rebuildBreadcrumbs()
    }

    func selectTab(_ tab: Tab) {
        selectedTab = tab
        rebuildBreadcrumbs()
    }

    // MARK: - Breadcrumbs

    private func rebuildBreadcrumbs() {
        let stack = stacks[selectedTab] ?? [.home]
        breadcrumbs = stack.map { BreadcrumbItem(route: $0) }
    }

    /// Navigate to a specific breadcrumb level: switches to that route's tab and
    /// rebuilds the path/stack up to that crumb (pops everything after it).
    func navigateToBreadcrumb(at index: Int) {
        guard index >= 0, index < breadcrumbs.count else { return }
        let target = breadcrumbs[index]
        let targetTab = target.route.tab

        var newPath = NavigationPath()
        var newStack: [Route] = [.home]
        newPath.append(Route.home)
        for i in 1...index {
            let r = breadcrumbs[i].route
            newStack.append(r)
            newPath.append(r)
        }
        paths[targetTab] = newPath
        stacks[targetTab] = newStack
        selectedTab = targetTab
        rebuildBreadcrumbs()
    }
}
