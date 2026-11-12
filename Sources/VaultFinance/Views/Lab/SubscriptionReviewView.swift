import SwiftUI

// MARK: - Subscription Review

struct SubscriptionReviewView: View {
    @EnvironmentObject var storage: LocalStorage

    private var active: [Subscription] {
        storage.subscriptions.filter { $0.isActive }.sorted { $0.annualizedCost > $1.annualizedCost }
    }

    private var monthlyTotal: Double {
        active.reduce(0) { $0 + WealthLabEngine.monthlyEquivalent(subscription: $1) }
    }

    private var cancelSavings: Double {
        WealthLabEngine.potentialSavings(reviews: storage.subscriptionReviews)
    }

    private var dueCount: Int {
        WealthLabEngine.reviewsDueCount(reviews: storage.subscriptionReviews)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if active.isEmpty {
                    VaultCard {
                        VaultEmptyState(icon: "eyes", title: "No active subscriptions",
                                        message: "Add subscriptions or use the detective to find them from transactions.")
                    }
                } else {
                    reviewList
                }
                LabCallout(icon: "calendar.badge.clock", title: "Review rhythm",
                           message: "Revisit every subscription at least once a quarter. Prices creep up quietly.",
                           tint: VaultTheme.purple)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Subscription Review")
        .inlineNavigationTitle()
        .onAppear { syncReviews() }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            LabHeroCard(
                eyebrow: "Subscription Review",
                title: WealthLabEngine.formatted(monthlyTotal, currency: storage.profile.currency) + " / month",
                subtitle: "\(active.count) active plan(s) · \(dueCount) review(s) due · \(WealthLabEngine.formatted(cancelSavings, currency: storage.profile.currency)) marked for cancellation.",
                icon: "checklist",
                gradient: VaultTheme.sunsetGradient
            )
            HStack(spacing: 10) {
                LabStat(label: "Annual spend", value: WealthLabEngine.formatted(monthlyTotal * 12, currency: storage.profile.currency),
                        icon: "calendar", tint: VaultTheme.orange)
                LabStat(label: "Potential savings", value: WealthLabEngine.formatted(cancelSavings, currency: storage.profile.currency),
                        icon: "scissors", tint: VaultTheme.green)
            }
        }
    }

    private var reviewList: some View {
        VStack(spacing: 10) {
            ForEach(active) { subscription in
                reviewCard(for: subscription)
            }
        }
    }

    private func reviewCard(for subscription: Subscription) -> some View {
        let review = WealthLabEngine.review(for: subscription, reviews: storage.subscriptionReviews)
        let verdict = review?.verdict ?? .review
        return VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top, spacing: 9) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.title).font(.subheadline).bold()
                        Text("\(WealthLabEngine.formatted(WealthLabEngine.monthlyEquivalent(subscription: subscription), currency: storage.profile.currency))/mo · \(subscription.cycle.localized)")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(WealthLabEngine.formatted(subscription.annualizedCost, currency: storage.profile.currency))
                            .font(.caption).bold()
                        Text("per year").font(.caption2).foregroundColor(.secondary)
                    }
                }

                if review?.priceHikeDetected == true {
                    VaultPill(text: "Price hike detected", icon: "arrow.up.right", color: VaultTheme.red)
                }

                HStack(spacing: 6) {
                    ForEach(SubscriptionVerdict.allCases) { option in
                        Button {
                            setVerdict(option, for: subscription)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: option.icon).font(.caption2)
                                Text(option.rawValue).font(.caption2).bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(verdict == option
                                          ? VaultTheme.tint(for: option.tint)
                                          : VaultTheme.tint(for: option.tint).opacity(0.10))
                            )
                            .foregroundColor(verdict == option ? .white : VaultTheme.tint(for: option.tint))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }

                TextField("Why this decision?", text: noteBinding(for: subscription), axis: .vertical)
                    .font(.caption2)
                    .lineLimit(1...3)
                    .padding(8)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)

                HStack {
                    Text(review.map { "Reviewed \($0.lastReviewed.formatted(.relative(presentation: .named)))" } ?? "Not reviewed yet")
                        .font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    if verdict == .cancel {
                        Text("Saves \(WealthLabEngine.formatted(subscription.annualizedCost, currency: storage.profile.currency))/yr")
                            .font(.caption2).bold().foregroundColor(VaultTheme.green)
                    }
                }
            }
        }
    }

    private func syncReviews() {
        var changed = false
        for subscription in active where WealthLabEngine.review(for: subscription, reviews: storage.subscriptionReviews) == nil {
            storage.subscriptionReviews.append(
                SubscriptionReview(subscriptionTitle: subscription.title,
                                   monthlyCost: WealthLabEngine.monthlyEquivalent(subscription: subscription),
                                   verdict: .review, lastReviewed: Date(),
                                   note: "")
            )
            changed = true
        }
        if changed { storage.save() }
    }

    private func setVerdict(_ verdict: SubscriptionVerdict, for subscription: Subscription) {
        let monthly = WealthLabEngine.monthlyEquivalent(subscription: subscription)
        if let index = storage.subscriptionReviews.firstIndex(where: { $0.subscriptionTitle == subscription.title }) {
            storage.subscriptionReviews[index].verdict = verdict
            storage.subscriptionReviews[index].monthlyCost = monthly
            storage.subscriptionReviews[index].lastReviewed = Date()
        } else {
            storage.subscriptionReviews.append(
                SubscriptionReview(subscriptionTitle: subscription.title, monthlyCost: monthly,
                                   verdict: verdict, lastReviewed: Date())
            )
        }
        storage.save()
    }

    private func noteBinding(for subscription: Subscription) -> Binding<String> {
        Binding(
            get: {
                WealthLabEngine.review(for: subscription, reviews: storage.subscriptionReviews)?.note ?? ""
            },
            set: { newValue in
                if let index = storage.subscriptionReviews.firstIndex(where: { $0.subscriptionTitle == subscription.title }) {
                    storage.subscriptionReviews[index].note = newValue
                } else {
                    storage.subscriptionReviews.append(
                        SubscriptionReview(subscriptionTitle: subscription.title,
                                           monthlyCost: WealthLabEngine.monthlyEquivalent(subscription: subscription),
                                           verdict: .review, lastReviewed: Date(), note: newValue)
                    )
                }
                storage.save()
            }
        )
    }
}
