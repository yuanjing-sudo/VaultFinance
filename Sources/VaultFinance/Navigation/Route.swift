import SwiftUI

// MARK: - Navigation Routes

/// Every navigable destination in VaultFinance.
/// Associated values carry the model being viewed, enabling deep breadcrumbs.
enum Route: Hashable {
    case home
    case budget
    case categoryDetail(BudgetCategory)
    case wealth
    case assetDetail(AssetHolding)
    case goals
    case goalDetail(FinancialGoal)
    case learn
    case lessonDetail(Lesson)
    case calendar
    case news
    case indicators
    case piggyBank
    case analytics
    case bills
    case subscriptions
    case reports
    case profile
    case profileEdit
    case settings

    var label: String {
        switch self {
        case .home: return "Home"
        case .budget: return "Budget"
        case .categoryDetail(let c): return c.name
        case .wealth: return "Wealth"
        case .assetDetail(let a): return a.title
        case .goals: return "Goals"
        case .goalDetail(let g): return g.title
        case .learn: return "Learn"
        case .lessonDetail(let l): return l.title
        case .calendar: return "Spending Calendar"
        case .news: return "News"
        case .indicators: return "Indicators"
        case .piggyBank: return "Piggy Bank"
        case .analytics: return "Analytics"
        case .bills: return "Bills"
        case .subscriptions: return "Subscriptions"
        case .reports: return "Reports"
        case .profile: return "Profile"
        case .profileEdit: return "Edit Profile"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .budget: return "list.bullet.rectangle"
        case .categoryDetail: return "folder.fill"
        case .wealth: return "chart.bar.fill"
        case .assetDetail: return "wallet"
        case .goals: return "target"
        case .goalDetail: return "flag.fill"
        case .learn: return "graduationcap.fill"
        case .lessonDetail: return "book.fill"
        case .calendar: return "calendar"
        case .news: return "newspaper.fill"
        case .indicators: return "gauge"
        case .piggyBank: return "pawprint.fill"
        case .analytics: return "chart.pie.fill"
        case .bills: return "doc.fill"
        case .subscriptions: return "eyes"
        case .reports: return "chart.bar.doc.horizontal"
        case .profile: return "person.fill"
        case .profileEdit: return "person.crop.circle.badge.gearshape"
        case .settings: return "gear"
        }
    }

    /// The top-level tab that owns this route, used to switch sections from breadcrumbs.
    var tab: AppRouter.Tab {
        switch self {
        case .home: return .home
        case .budget, .categoryDetail: return .budget
        case .wealth, .assetDetail: return .wealth
        case .goals, .goalDetail: return .budget
        case .learn, .lessonDetail: return .learn
        case .calendar: return .calendar
        case .news: return .news
        case .indicators: return .indicators
        case .piggyBank: return .piggyBank
        case .analytics: return .analytics
        case .bills: return .bills
        case .subscriptions: return .subscriptions
        case .reports: return .reports
        case .profile, .profileEdit: return .profile
        case .settings: return .settings
        }
    }
}

// MARK: - Breadcrumb Item

struct BreadcrumbItem: Identifiable, Hashable {
    let id = UUID()
    let route: Route

    var label: String { route.label }
    var icon: String { route.icon }
}
