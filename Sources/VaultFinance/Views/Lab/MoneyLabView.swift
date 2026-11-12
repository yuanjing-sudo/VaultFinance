import SwiftUI

// MARK: - Money Lab
// The home for the advanced, non-platform feature set: safe-to-spend,
// debt payoff, portfolio, subscriptions, automations, tax, quests, and more.

struct MoneyLabView: View {
    @EnvironmentObject var storage: LocalStorage

    private var safe: SafeToSpendBreakdown {
        WealthLabEngine.safeToSpend(profile: storage.profile, transactions: storage.transactions,
                                    bills: storage.bills, goals: storage.goals)
    }

    private var anomalies: [SpendingAnomaly] {
        WealthLabEngine.detectAnomalies(transactions: storage.transactions)
    }

    private var detected: [DetectedSubscription] {
        WealthLabEngine.detectSubscriptions(transactions: storage.transactions)
    }

    private var reviewsDue: Int {
        WealthLabEngine.reviewsDueCount(reviews: storage.subscriptionReviews)
    }

    private var questsDone: Int {
        storage.weeklyQuests.filter { $0.isComplete }.count
    }

    private var negotiationSavings: Double {
        WealthLabEngine.negotiationOpportunities(bills: storage.bills)
            .reduce(0) { $0 + $1.estimatedAnnualSavings }
    }

    private var planExists: Bool { storage.personalizedPlan != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                LabHeroCard(
                    eyebrow: "Money Lab",
                    title: "Your money, upgraded",
                    subtitle: "Safe-to-spend, payoff plans, portfolio drift, quests and automations — all in one place.",
                    icon: "flask.fill",
                    gradient: VaultTheme.brandGradient
                )

                todaySection
                growSection
                optimizeSection
                understandSection
                playSection
                planSection
            }
            .padding()
            .padding(.bottom, 90)
        }
        .navigationTitle("Money Lab")
        .inlineNavigationTitle()
        .onAppear { storage.ensureWeeklyQuests() }
    }

    // MARK: - Today

    private var todaySection: some View {
        LabSection(title: "Today", subtitle: "Small signals that change your day", icon: "sun.max.fill") {
            VStack(spacing: 9) {
                NavigationLink {
                    SafeToSpendView()
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("SAFE TO SPEND").font(.caption2).bold()
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Text(WealthLabEngine.formatted(max(safe.remainingToday, 0), currency: storage.profile.currency))
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("left today · \(WealthLabEngine.formatted(safe.dailyAllowance, currency: storage.profile.currency)) daily allowance")
                            .font(.caption).foregroundColor(.white.opacity(0.85))
                        VaultProgressBar(progress: safe.progress, height: 7,
                                         gradient: LinearGradient(colors: [.white.opacity(0.9), .white],
                                                                  startPoint: .leading, endPoint: .trailing),
                                         track: Color.white.opacity(0.25))
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .fill(safe.remainingToday >= 0 ? VaultTheme.savingsGradient : VaultTheme.warningGradient)
                    )
                }
                .buttonStyle(PressableButtonStyle())

                LabLinkRow(title: "Weekly quests",
                           subtitle: "\(questsDone) of \(max(storage.weeklyQuests.count, 5)) complete · earn XP",
                           icon: "star.circle.fill", tint: VaultTheme.gold,
                           badge: questsDone >= 5 ? "Done" : "\(questsDone)/5") {
                    WeeklyQuestsView()
                }
                LabLinkRow(title: "Spending anomalies",
                           subtitle: anomalies.isEmpty ? "No unusual charges detected" : "\(anomalies.count) unusual charge(s) to review",
                           icon: "exclamationmark.magnifyingglass", tint: VaultTheme.orange,
                           badge: anomalies.isEmpty ? nil : "\(anomalies.count)") {
                    AnomalyInsightsView()
                }
            }
        }
    }

    // MARK: - Grow

    private var growSection: some View {
        LabSection(title: "Grow", subtitle: "Put every dollar to work", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 9) {
                LabLinkRow(title: "Debt payoff planner",
                           subtitle: "Snowball vs avalanche — see your debt-free date",
                           icon: "mountain.2.fill", tint: VaultTheme.red) {
                    DebtPayoffView()
                }
                LabLinkRow(title: "Portfolio tracker",
                           subtitle: "Allocation, gains and rebalancing drift",
                           icon: "chart.pie.fill", tint: VaultTheme.green) {
                    PortfolioView()
                }
                LabLinkRow(title: "Goal autopilot",
                           subtitle: "Required monthly amounts and projected dates",
                           icon: "target", tint: VaultTheme.blue) {
                    GoalAutopilotView()
                }
                LabLinkRow(title: "Multi-currency lab",
                           subtitle: "Convert and plan in 12 currencies",
                           icon: "globe.europe.africa.fill", tint: VaultTheme.teal) {
                    MultiCurrencyView()
                }
            }
        }
    }

    // MARK: - Optimize

    private var optimizeSection: some View {
        LabSection(title: "Optimize", subtitle: "Find money hiding in plain sight", icon: "wand.and.stars") {
            VStack(spacing: 9) {
                LabLinkRow(title: "Subscription detective",
                           subtitle: "\(detected.count) recurring charge(s) found in your transactions",
                           icon: "eyes", tint: VaultTheme.purple,
                           badge: detected.isEmpty ? nil : "\(detected.count)") {
                    SubscriptionDetectiveView()
                }
                LabLinkRow(title: "Subscription review",
                           subtitle: "Keep, review or cancel — \(WealthLabEngine.formatted(WealthLabEngine.potentialSavings(reviews: storage.subscriptionReviews))) potential annual savings",
                           icon: "checklist", tint: VaultTheme.pink,
                           badge: reviewsDue > 0 ? "\(reviewsDue) due" : nil) {
                    SubscriptionReviewView()
                }
                LabLinkRow(title: "Bill negotiation",
                           subtitle: "Scripts and targets worth \(WealthLabEngine.formatted(negotiationSavings)) a year",
                           icon: "phone.arrow.up.right.fill", tint: VaultTheme.orange) {
                    BillNegotiationView()
                }
                LabLinkRow(title: "Tax vault",
                           subtitle: "Documents, deadlines and deduction totals",
                           icon: "doc.text.fill", tint: VaultTheme.blue) {
                    TaxVaultView()
                }
                LabLinkRow(title: "Automation rules",
                           subtitle: "\(storage.automationRules.filter { $0.isEnabled }.count) active rules · \(storage.automationRuns.count) runs logged",
                           icon: "gearshape.2.fill", tint: VaultTheme.green) {
                    AutomationRulesView()
                }
            }
        }
    }

    // MARK: - Understand

    private var understandSection: some View {
        LabSection(title: "Understand", subtitle: "See the whole picture", icon: "brain.head.profile") {
            VStack(spacing: 9) {
                LabLinkRow(title: "Credit score simulator",
                           subtitle: "Test utilization, inquiries and payment scenarios",
                           icon: "creditcard.fill", tint: VaultTheme.gold) {
                    CreditSimulatorView()
                }
                LabLinkRow(title: "Financial health timeline",
                           subtitle: "\(storage.healthScores.count) score snapshot(s) and factor breakdown",
                           icon: "heart.text.square.fill", tint: VaultTheme.pink) {
                    HealthTimelineView()
                }
                LabLinkRow(title: "Statement import",
                           subtitle: "Paste or import a CSV and de-duplicate transactions",
                           icon: "square.and.arrow.down.fill", tint: VaultTheme.teal) {
                    StatementImportView()
                }
            }
        }
    }

    // MARK: - Play

    private var playSection: some View {
        LabSection(title: "Play", subtitle: "Make saving feel good", icon: "sparkles") {
            VStack(spacing: 9) {
                LabLinkRow(title: "Buddy challenges",
                           subtitle: "\(storage.buddyChallenges.filter { $0.isActive }.count) local challenge(s) — no cloud needed",
                           icon: "person.2.fill", tint: VaultTheme.blue) {
                    BuddyChallengesView()
                }
                LabLinkRow(title: "Piggy skins & seasons",
                           subtitle: "Unlock skins, pick a season and celebrate deposits",
                           icon: "paintpalette.fill", tint: VaultTheme.pink) {
                    PiggySkinsView()
                }
                LabLinkRow(title: "Accessibility & delight",
                           subtitle: "Reduced motion, haptics, contrast and labels",
                           icon: "accessibility", tint: VaultTheme.teal) {
                    AccessibilitySettingsView()
                }
            }
        }
    }

    // MARK: - Plan

    private var planSection: some View {
        LabSection(title: "Your plan", subtitle: "A personalized starting point", icon: "map.fill") {
            NavigationLink {
                PersonalizedPlanView()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: planExists ? "checkmark.seal.fill" : "wand.and.stars")
                            .foregroundColor(planExists ? VaultTheme.green : VaultTheme.purple)
                        Text(planExists ? "Your personalized plan is ready" : "Build my personalized plan")
                            .font(.subheadline).bold()
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                    }
                    Text(planExists
                         ? "Risk profile: \(storage.personalizedPlan?.riskProfile ?? "Balanced") · revisit anytime"
                         : "A two-minute quiz turns your profile into a concrete savings, spending and investing plan.")
                        .font(.caption2).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(VaultTheme.purple.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(VaultTheme.purple.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}
