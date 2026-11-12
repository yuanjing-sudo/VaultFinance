import Foundation
import SwiftUI

// MARK: - Brilliant Dashboard
// The new home experience: animated piggy, streak flame, live charts,
// quick insights, and today's focus. Smooth, vivid, and informative.

struct BrilliantDashboardView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter
    @State private var showConfetti = false
    @State private var quickActionsOpen = false

    private var netWorth: Double {
        let assets = storage.assets.reduce(0) { $0 + $1.currentMarketValue } + storage.profile.existingSavings
        let liabilities = storage.liabilities.reduce(0) { $0 + $1.balance }
        return assets - liabilities
    }

    private var totalSpentThisMonth: Double {
        let cal = Calendar.current
        return storage.transactions
            .filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private var sparkValues: [Double] {
        let sorted = storage.spendingDays.sorted { $0.date < $1.date }
        if sorted.isEmpty { return [0, 0, 0, 0, 0, 0, 0] }
        return sorted.suffix(14).map { $0.amount }
    }

    private var safe: SafeToSpendBreakdown {
        WealthLabEngine.safeToSpend(profile: storage.profile, transactions: storage.transactions,
                                    bills: storage.bills, goals: storage.goals)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    greetingHeader
                    heroPiggyCard
                    streakAndNetWorthRow
                    quickStatsGrid
                    safeToSpendCard
                    spendingTrendCard
                    todayFocusCard
                    recentActivityCard
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }

            FloatingQuickActions(isOpen: $quickActionsOpen)
                .environmentObject(router)
                .environmentObject(storage)
                .padding(.trailing, 18)
                .padding(.bottom, 84)

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Vault")
        .inlineNavigationTitle()
        .onAppear {
            if storage.piggyBank.isFull && storage.themeSettings.showConfetti {
                fireConfetti()
            }
        }
    }

    // MARK: - Header

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting).font(.subheadline).foregroundColor(.secondary)
                Text("Let's grow your vault").font(.title2).bold()
            }
            Spacer()
            Button {
                router.selectTab(.profile)
            } label: {
                Circle()
                    .fill(VaultTheme.brandGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initial).font(.headline).bold().foregroundColor(.white)
                    )
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning ☀️"
        case 12..<18: return "Good afternoon 🌤"
        default: return "Good evening 🌙"
        }
    }

    private var initial: String {
        let c = storage.profile.currency
        return String(c.prefix(1))
    }

    // MARK: - Hero Piggy

    private var heroPiggyCard: some View {
        VaultGradientCard(gradient: VaultTheme.savingsGradient) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(storage.piggyBank.name)
                        .font(.caption).opacity(0.9)
                    Text(Money(amount: storage.piggyBank.depositedAmount, currency: storage.piggyBank.currency).formatted())
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("of \(Money(amount: storage.piggyBank.targetAmount, currency: storage.piggyBank.currency).formatted())")
                        .font(.caption).opacity(0.85)
                    VaultProgressBar(progress: storage.piggyBank.progress,
                                     height: 8,
                                     gradient: LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .leading, endPoint: .trailing),
                                     track: Color.white.opacity(0.25))
                        .frame(width: 150)
                    Text("\(Int(storage.piggyBank.percentFull))% full")
                        .font(.caption2).opacity(0.9)
                }
                Spacer()
                AnimatedPiggyBank(progress: storage.piggyBank.progress,
                                  themeColor: VaultTheme.gold,
                                  isBroken: storage.piggyBank.isBroken,
                                  isCelebrating: storage.piggyBank.isFull)
                    .frame(width: 130, height: 130)
                    .scaleEffect(0.7)
            }
        }
    }

    // MARK: - Streak + Net Worth

    private var streakAndNetWorthRow: some View {
        HStack(spacing: 12) {
            VaultCard(padding: 14) {
                VStack(spacing: 6) {
                    AnimatedStreakFlame(streak: storage.spendingStreak.currentStreak)
                        .frame(height: 54)
                    Text("\(storage.spendingStreak.currentStreak)")
                        .font(.title).bold()
                    Text("day streak").font(.caption2).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            VaultCard(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Net Worth").font(.caption).foregroundColor(.secondary)
                    Text(Money(amount: netWorth).formatted())
                        .font(.title3).bold()
                        .lineLimit(1).minimumScaleFactor(0.6)
                    VaultSparkline(values: sparkValues, tint: VaultTheme.green)
                        .frame(height: 30)
                    Text("Budget health \(storage.healthScores.last?.score ?? 0)/100")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Quick Stats

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            VaultStatTile(title: "Spent this month",
                          value: Money(amount: totalSpentThisMonth).formatted(),
                          icon: "cart.fill", color: VaultTheme.orange)
            VaultStatTile(title: "Monthly income",
                          value: Money(amount: storage.profile.totalMonthlyIncome).formatted(),
                          icon: "arrow.down.circle.fill", color: VaultTheme.green)
            VaultStatTile(title: "Active goals",
                          value: "\(storage.goals.filter { !$0.isComplete }.count)",
                          icon: "target", color: VaultTheme.blue)
            VaultStatTile(title: "Subscriptions",
                          value: Money(amount: FinanceEngine.subscriptionMonthlyTotal(storage.subscriptions)).formatted() + "/mo",
                          icon: "eyes", color: VaultTheme.purple)
        }
    }

    // MARK: - Safe to Spend

    private var safeToSpendCard: some View {
        NavigationLink {
            SafeToSpendView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        Text("SAFE TO SPEND")
                    }
                    .font(.caption2).bold()
                    Spacer()
                    Text("\(safe.daysLeftInMonth) days left")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.85))
                HStack(alignment: .firstTextBaseline) {
                    Text(Money(amount: max(safe.remainingToday, 0)).formatted())
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("left today")
                        .font(.caption2).opacity(0.8)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2).opacity(0.7)
                }
                .foregroundColor(.white)
                VaultProgressBar(progress: safe.progress, height: 7,
                                 gradient: LinearGradient(colors: [.white.opacity(0.9), .white],
                                                          startPoint: .leading, endPoint: .trailing),
                                 track: Color.white.opacity(0.25))
                Text("\(Money(amount: safe.spentToday).formatted()) spent · \(Money(amount: safe.dailyAllowance).formatted()) allowance")
                    .font(.caption2).foregroundColor(.white.opacity(0.8))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(safe.remainingToday >= 0 ? VaultTheme.skyGradient : VaultTheme.warningGradient)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Safe to spend \(Money(amount: max(safe.remainingToday, 0)).formatted()) today. Open details.")
    }

    // MARK: - Spending Trend

    private var spendingTrendCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Spending Trend", subtitle: "Last 14 days",
                                   actionTitle: "Details") { router.selectTab(.analytics) }
                VaultLineChart(points: sparkValues.enumerated().map {
                    ChartPoint(x: Double($0.offset), y: $0.element)
                }, tint: VaultTheme.blue)
                    .frame(height: 120)
            }
        }
    }

    // MARK: - Today's Focus

    private var todayFocusCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles").foregroundColor(VaultTheme.purple)
                    Text("Today's Focus").font(.headline).bold()
                }
                ForEach(dailyFocusItems.prefix(3)) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .foregroundColor(item.color)
                            .frame(width: 20)
                        Text(item.text).font(.subheadline)
                        Spacer()
                    }
                }
            }
        }
    }

    private var dailyFocusItems: [FocusItem] {
        var items: [FocusItem] = []
        let streak = storage.spendingStreak
        if streak.goalMetToday {
            items.append(FocusItem(icon: "checkmark.seal.fill", text: "Daily goal met — streak safe!", color: VaultTheme.green))
        } else {
            items.append(FocusItem(icon: "target", text: "Stay under \(Money(amount: streak.dailyGoal).formatted()) today.", color: VaultTheme.orange))
        }
        if !storage.piggyBank.isFull {
            items.append(FocusItem(icon: "pawprint.fill", text: "Feed the piggy \(Money(amount: storage.piggyBank.remaining).formatted()) to go.", color: VaultTheme.pink))
        } else {
            items.append(FocusItem(icon: "crown.fill", text: "Piggy is full — time to celebrate!", color: VaultTheme.gold))
        }
        if let bill = storage.bills.filter({ $0.isDueSoon }).sorted(by: { $0.nextDueDate < $1.nextDueDate }).first {
            items.append(FocusItem(icon: "doc.fill", text: "\(bill.title) due in \(bill.daysUntilDue) days.", color: VaultTheme.blue))
        } else {
            items.append(FocusItem(icon: "checkmark.circle", text: "No bills due this week.", color: VaultTheme.teal))
        }
        return items
    }

    // MARK: - Recent Activity

    private var recentActivityCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Recent Activity",
                                   actionTitle: "All") { router.selectTab(.reports) }
                if storage.transactions.isEmpty {
                    VaultEmptyState(icon: "tray", title: "No activity yet")
                } else {
                    ForEach(storage.transactions.prefix(4), id: \.id) { tx in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(VaultTheme.tint(for: tx.category.color))
                                .frame(width: 8, height: 8)
                            Text(tx.title).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(Money(amount: tx.amount).formatted())
                                .font(.subheadline).bold()
                                .foregroundColor(tx.amount < 0 ? VaultTheme.green : .primary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Confetti

    private func fireConfetti() {
        withAnimation { showConfetti = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showConfetti = false }
        }
    }
}

// MARK: - Focus Item

struct FocusItem: Identifiable {
    let id = UUID()
    var icon: String
    var text: String
    var color: Color
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false
    private let colors: [Color] = [VaultTheme.blue, VaultTheme.green, VaultTheme.orange, VaultTheme.pink, VaultTheme.purple, VaultTheme.gold]

    var body: some View {
        ZStack {
            ForEach(0..<40, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: CGFloat.random(in: 5...10), height: CGFloat.random(in: 5...10))
                    .offset(
                        x: animate ? CGFloat.random(in: -180...180) : 0,
                        y: animate ? CGFloat.random(in: 200...700) : -60
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(.easeIn(duration: Double.random(in: 1.0...2.2)), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}
