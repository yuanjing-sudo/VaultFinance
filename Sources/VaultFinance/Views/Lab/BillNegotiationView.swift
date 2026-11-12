import SwiftUI

// MARK: - Bill Negotiation

struct BillNegotiationView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var applied: Set<UUID> = []

    private var opportunities: [NegotiationOpportunity] {
        WealthLabEngine.negotiationOpportunities(bills: storage.bills)
    }

    private var annualSavings: Double {
        opportunities.reduce(0) { $0 + $1.estimatedAnnualSavings }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabHeroCard(
                    eyebrow: "Bill Negotiation",
                    title: WealthLabEngine.formatted(annualSavings, currency: storage.profile.currency) + " potential / year",
                    subtitle: opportunities.isEmpty
                        ? "Add monthly bills to see negotiation targets."
                        : "\(opportunities.count) bill(s) with room to negotiate. A five-minute call can beat a loyalty discount you never asked for.",
                    icon: "phone.arrow.up.right.fill",
                    gradient: VaultTheme.warningGradient
                )

                if opportunities.isEmpty {
                    VaultCard {
                        VaultEmptyState(icon: "phone", title: "No bills to negotiate",
                                        message: "Recurring bills above $20/month appear here with a target and script.")
                    }
                } else {
                    HStack(spacing: 10) {
                        LabStat(label: "Current monthly", value: WealthLabEngine.formatted(opportunities.reduce(0) { $0 + $1.currentMonthly }, currency: storage.profile.currency),
                                icon: "banknote", tint: VaultTheme.orange)
                        LabStat(label: "Potential saving", value: WealthLabEngine.formatted(annualSavings, currency: storage.profile.currency),
                                icon: "arrow.down.right", tint: VaultTheme.green)
                    }
                    opportunitiesList
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 8) {
                        VaultSectionHeader(title: "How to ask")
                        bullet("Call the retention line, not general support.")
                        bullet("Ask for current promos, loyalty pricing or a competitor match.")
                        bullet("Be polite, specific and ready to cancel if the price stays high.")
                        bullet("Get the new rate and expiration date in writing.")
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Negotiation")
        .inlineNavigationTitle()
    }

    private var opportunitiesList: some View {
        VStack(spacing: 10) {
            ForEach(opportunities) { item in
                VaultCard(tint: applied.contains(item.billId) ? VaultTheme.green : VaultTheme.orange) {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline).bold()
                                Text("\(WealthLabEngine.formatted(item.currentMonthly, currency: storage.profile.currency))/mo now → target \(WealthLabEngine.formatted(item.targetMonthly, currency: storage.profile.currency))/mo")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            VaultPill(text: "\(WealthLabEngine.formatted(item.estimatedAnnualSavings, currency: storage.profile.currency))/yr",
                                      icon: "scissors", color: VaultTheme.green)
                        }

                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.script)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                HStack {
                                    ShareLink(item: item.script) {
                                        Label("Share script", systemImage: "square.and.arrow.up")
                                            .font(.caption2).bold()
                                    }
                                    Spacer()
                                    Button(applied.contains(item.billId) ? "Applied ✓" : "Apply target") {
                                        apply(item)
                                    }
                                    .font(.caption2).bold()
                                    .disabled(applied.contains(item.billId))
                                }
                            }
                            .padding(.top, 5)
                        } label: {
                            Text("Negotiation script").font(.caption).bold()
                        }
                    }
                }
            }
        }
    }

    private func apply(_ item: NegotiationOpportunity) {
        guard let index = storage.bills.firstIndex(where: { $0.id == item.billId }) else { return }
        storage.bills[index].amount = item.targetMonthly
        storage.bills[index].notes = (storage.bills[index].notes + " Negotiated target applied.").trimmingCharacters(in: .whitespaces)
        storage.save()
        applied.insert(item.billId)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle().fill(VaultTheme.orange).frame(width: 5, height: 5).padding(.top, 5)
            Text(text).font(.caption2).foregroundColor(.secondary)
            Spacer(minLength: 0)
        }
    }
}
