import SwiftUI

// MARK: - Custom Bottom Tab Bar
// Works alongside the sidebar for deeper navigation. Animated selection,
// spring indicators, and a floating quick-action button.

struct BottomTabBar: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var scheme

    // The tabs shown in the bottom bar (primary destinations).
    private let primaryTabs: [AppRouter.Tab] = [.home, .budget, .piggyBank, .calendar, .lab]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(primaryTabs, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            VaultTheme.raised(scheme)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private func tabButton(_ tab: AppRouter.Tab) -> some View {
        let selected = router.selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                router.selectTab(tab)
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if selected {
                        Capsule()
                            .fill(VaultTheme.blue.opacity(0.14))
                            .frame(width: 44, height: 28)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: selected ? .bold : .regular))
                        .foregroundColor(selected ? VaultTheme.blue : .secondary)
                        .scaleEffect(selected ? 1.08 : 1.0)
                }
                .frame(height: 30)
                Text(tab.label)
                    .font(.system(size: 9, weight: selected ? .bold : .regular))
                    .foregroundColor(selected ? VaultTheme.blue : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scrollable Secondary Tab Strip

/// A horizontally scrollable strip exposing every destination — useful on
/// compact widths where the sidebar is collapsed.
struct SecondaryTabStrip: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var scheme

    private let tabs: [AppRouter.Tab] = [.dashboard, .lab, .goals, .tools, .credit, .challenges, .markets, .events, .analytics, .reports, .bills, .subscriptions, .search, .more, .news, .indicators, .learn, .profile, .settings]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs, id: \.self) { tab in
                    let selected = router.selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            router.selectTab(tab)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon).font(.caption2)
                            Text(tab.label).font(.caption2).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(selected ? VaultTheme.blue : VaultTheme.subtle(scheme))
                        )
                        .foregroundColor(selected ? .white : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(VaultTheme.raised(scheme))
    }
}

// MARK: - Floating Quick Actions

struct FloatingQuickActions: View {
    @Binding var isOpen: Bool
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if isOpen {
                quickButton("Add Spending", "cart.badge.plus", VaultTheme.orange) {
                    router.selectTab(.calendar)
                    isOpen = false
                }
                quickButton("Feed Piggy", "dollarsign.circle.fill", VaultTheme.green) {
                    router.selectTab(.piggyBank)
                    isOpen = false
                }
                quickButton("Add Bill", "doc.badge.plus", VaultTheme.blue) {
                    router.selectTab(.bills)
                    isOpen = false
                }
                quickButton("Reports", "chart.pie.fill", VaultTheme.purple) {
                    router.selectTab(.reports)
                    isOpen = false
                }
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    isOpen.toggle()
                }
            } label: {
                Image(systemName: isOpen ? "xmark" : "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle().fill(VaultTheme.brandGradient)
                            .shadow(color: VaultTheme.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func quickButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.caption).fontWeight(.semibold)
                Image(systemName: icon).font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Capsule().fill(color))
            .foregroundColor(.white)
            .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }
}
