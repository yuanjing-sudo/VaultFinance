import SwiftUI

struct ContentView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var storage: LocalStorage
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            NavigationStack(path: pathBinding) {
                VStack(spacing: 0) {
                    // Deep breadcrumb trail (updates as you navigate sections and drill in).
                    BreadcrumbsView(
                        items: router.breadcrumbs,
                        onSelect: { index in router.navigateToBreadcrumb(at: index) },
                        router: router
                    )

                    TabView(selection: $router.selectedTab) {
                        ForEach(AppRouter.Tab.allCases, id: \.self) { tab in
                            sectionView(for: tab)
                                .tag(tab)
                        }
                    }
                    .tabViewStyle(.automatic)
                }
            }
            // Deep navigation destinations driven by the router (breadcrumbs deepen here).
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .categoryDetail(let category):
                    CategoryDetailView(category: category)
                case .profileEdit:
                    ProfileEditView()
                case .assetDetail(let asset):
                    RouteDestinationView(route: route, subtitle: asset.title)
                case .goalDetail(let goal):
                    RouteDestinationView(route: route, subtitle: goal.title)
                case .lessonDetail(let lesson):
                    RouteDestinationView(route: route, subtitle: lesson.title)
                default:
                    RouteDestinationView(route: route)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environmentObject(router)
        .environmentObject(MarketDataService.shared) // required by MarketInsightsView & NewsFeedView
    }

    // Bind the outer NavigationStack path to the active tab's router path so deep
    // navigation (e.g. category → detail) is reflected in the path & breadcrumbs.
    private var pathBinding: Binding<NavigationPath> {
        Binding(
            get: { router.paths[router.selectedTab] ?? NavigationPath() },
            set: { router.paths[router.selectedTab] = $0 }
        )
    }

    @ViewBuilder
    private func sectionView(for tab: AppRouter.Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .budget:
            BudgetView()
        case .calendar:
            SpendingCalendarView()
        case .wealth:
            WealthView()
        case .learn:
            LearnView()
        case .news:
            NewsFeedView()
        case .indicators:
            FinancialIndicatorsView()
        case .piggyBank:
            PiggyBankView()
        case .analytics:
            DetailedAnalyticsView()
        case .bills:
            BillsView()
        case .subscriptions:
            SubscriptionsView()
        case .reports:
            ReportsView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        }
    }
}
