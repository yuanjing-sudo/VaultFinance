import SwiftUI

// MARK: - Round-Up Savings
// Turn spare change from every purchase into piggy-bank deposits.

struct RoundUpView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var settings: RoundUpSettings

    init() {
        _settings = State(initialValue: LocalStorage.shared.roundUpSettings)
    }

    private var estimatedMonthlySpare: Double {
        let monthly = storage.transactions
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        guard !monthly.isEmpty else { return 0 }
        return monthly.reduce(0) { $0 + FinanceEngine.roundUpAmount(transaction: abs($1.amount), roundTo: settings.roundTo) }
    }

    private var estimatedAnnual: Double { estimatedMonthlySpare * 12 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.savingsGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spare change this month").font(.caption).opacity(0.9)
                        Text(Money(amount: estimatedMonthlySpare, currency: storage.profile.currency).formatted())
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        Text("≈ \(Money(amount: estimatedAnnual).formatted()) a year").font(.caption2).opacity(0.9)
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Enable round-ups", isOn: $settings.isEnabled)
                            .font(.subheadline).bold()
                        Picker("Round to nearest", selection: $settings.roundTo) {
                            Text("$1").tag(1.0)
                            Text("$2").tag(2.0)
                            Text("$5").tag(5.0)
                        }
                        .pickerStyle(.segmented)
                        Text("Each purchase is rounded up and the difference is moved into your piggy bank.")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: "Recent Spare Change", subtitle: "Last 8 purchases")
                        ForEach(storage.transactions.prefix(8)) { tx in
                            HStack {
                                Text(tx.title).font(.caption).lineLimit(1)
                                Spacer()
                                Text("+\(Money(amount: FinanceEngine.roundUpAmount(transaction: abs(tx.amount), roundTo: settings.roundTo)).formatted())")
                                    .font(.caption2).bold()
                                    .foregroundColor(VaultTheme.green)
                            }
                        }
                        if storage.transactions.isEmpty {
                            Text("No purchases yet.").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

                VaultPrimaryButton(title: "Move Spare Change to Piggy", icon: "pawprint.fill") {
                    depositToPiggy()
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Round-Ups")
        .inlineNavigationTitle()
        .onDisappear {
            storage.roundUpSettings = settings
            storage.save()
        }
    }

    private func depositToPiggy() {
        guard estimatedMonthlySpare > 0 else { return }
        let piggyId = storage.piggyBank.id
        storage.piggyBank.depositedAmount += estimatedMonthlySpare
        storage.piggyBank.depositCount += 1
        storage.piggyBank.lastDepositDate = Date()
        storage.piggyDeposits.append(PiggyDeposit(piggyId: piggyId,
                                                  amount: estimatedMonthlySpare,
                                                  note: "Round-up savings",
                                                  source: .roundUp))
        storage.roundUpSettings = settings
        storage.save()
    }
}
