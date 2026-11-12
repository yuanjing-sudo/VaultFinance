import SwiftUI

// MARK: - Multi-Currency Lab

struct MultiCurrencyView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var amount = "100"
    @State private var from = "USD"
    @State private var to = "EUR"
    @State private var budget = "2000"
    @State private var budgetCurrency = "JPY"
    @State private var days = 10.0

    private var sourceAmount: Double { Double(amount) ?? 0 }
    private var converted: Double { WealthLabEngine.convert(amount: sourceAmount, from: from, to: to) }
    private var sourceRate: CurrencyRate? { WealthLabEngine.currencies.first { $0.code == from } }
    private var targetRate: CurrencyRate? { WealthLabEngine.currencies.first { $0.code == to } }

    private var budgetAmount: Double { Double(budget) ?? 0 }
    private var convertedBudget: Double { WealthLabEngine.convert(amount: budgetAmount, from: storage.profile.currency, to: budgetCurrency) }
    private var perDay: Double { convertedBudget / max(days, 1) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                converterCard
                quickChips
                travelCard
                rateTable
                LabCallout(icon: "exclamationmark.triangle.fill", title: "Indicative rates",
                           message: "These are fixed educational rates bundled with the app, not live market quotes. Always check your bank or card provider before exchanging money.",
                           tint: VaultTheme.orange)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Multi-Currency")
        .inlineNavigationTitle()
    }

    private var hero: some View {
        LabHeroCard(
            eyebrow: "Multi-Currency Lab",
            title: "Plan across borders",
            subtitle: "Convert 12 currencies, size a travel budget, and see daily spending power.",
            icon: "globe.europe.africa.fill",
            gradient: VaultTheme.skyGradient
        )
    }

    private var converterCard: some View {
        VaultCard {
            VStack(spacing: 12) {
                VaultSectionHeader(title: "Converter", subtitle: "Type an amount and pick two currencies")
                HStack(spacing: 8) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.title3).bold()
                        .padding(10)
                        .background(Color.gray.opacity(0.09))
                        .cornerRadius(10)
                    currencyPicker(selection: $from, tint: VaultTheme.blue)
                }
                HStack {
                    Spacer()
                    Button {
                        let old = from
                        from = to
                        to = old
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(VaultTheme.blue)
                    }
                    .buttonStyle(PressableButtonStyle())
                    Spacer()
                }
                currencyPicker(selection: $to, tint: VaultTheme.green)

                VStack(spacing: 2) {
                    Text(WealthLabEngine.formatted(converted, currency: to))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(VaultTheme.green)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("1 \(from) = \(String(format: "%.4f", WealthLabEngine.convert(amount: 1, from: from, to: to))) \(to)")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)

                if let sourceRate, let targetRate {
                    Text("\(sourceRate.name) → \(targetRate.name)")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    private var quickChips: some View {
        HStack(spacing: 8) {
            chip("$100", "100")
            chip("$500", "500")
            chip("$1,000", "1000")
            chip("$5,000", "5000")
        }
    }

    private func chip(_ label: String, _ value: String) -> some View {
        Button {
            amount = value
        } label: {
            Text(label)
                .font(.caption2).bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 9).fill(VaultTheme.blue.opacity(0.10)))
                .foregroundColor(VaultTheme.blue)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var travelCard: some View {
        VaultCard(tint: VaultTheme.teal) {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Travel budget",
                                   subtitle: "Convert your budget and see a daily allowance")
                HStack {
                    Text(storage.profile.currency).font(.caption).bold()
                    TextField("Budget", text: $budget).keyboardType(.decimalPad)
                        .padding(8).background(Color.gray.opacity(0.09)).cornerRadius(8)
                    currencyPicker(selection: $budgetCurrency, tint: VaultTheme.teal)
                }
                HStack {
                    Text("Trip length").font(.caption).bold()
                    Spacer()
                    Text("\(Int(days)) days").font(.caption).bold().foregroundColor(VaultTheme.teal)
                }
                Slider(value: $days, in: 1...45, step: 1)
                HStack(spacing: 10) {
                    LabStat(label: "Converted", value: WealthLabEngine.formatted(convertedBudget, currency: budgetCurrency),
                            icon: "arrow.left.arrow.right", tint: VaultTheme.teal)
                    LabStat(label: "Per day", value: WealthLabEngine.formatted(perDay, currency: budgetCurrency),
                            icon: "calendar", tint: VaultTheme.blue)
                }
                Text("That is about \(WealthLabEngine.formatted(perDay / max(WealthLabEngine.convert(amount: 1, from: budgetCurrency, to: storage.profile.currency), 0.0001), currency: storage.profile.currency)) per day in your home currency.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var rateTable: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 8) {
                VaultSectionHeader(title: "1 \(storage.profile.currency) buys",
                                   subtitle: "Fixed reference rates")
                let basePerUSD = WealthLabEngine.currencies.first(where: { $0.code == storage.profile.currency })?.perUSD ?? 1
                ForEach(WealthLabEngine.currencies) { rate in
                    HStack {
                        Text(rate.code).font(.caption).bold().frame(width: 42, alignment: .leading)
                        Text(rate.name).font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", rate.perUSD / basePerUSD) + " \(rate.symbol)")
                            .font(.caption2).bold()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func currencyPicker(selection: Binding<String>, tint: Color) -> some View {
        Picker("Currency", selection: selection) {
            ForEach(WealthLabEngine.currencies) { rate in
                Text("\(rate.code) · \(rate.name)").tag(rate.code)
            }
        }
        .pickerStyle(.menu)
        .tint(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.10)))
    }
}
