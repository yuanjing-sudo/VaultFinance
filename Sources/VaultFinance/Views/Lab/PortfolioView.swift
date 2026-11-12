import SwiftUI

// MARK: - Portfolio Tracker

struct PortfolioView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingEditor = false
    @State private var editingHolding: PortfolioHolding?
    @State private var lastRefresh: Date?

    private var holdings: [PortfolioHolding] { storage.portfolioHoldings }
    private var totalValue: Double { WealthLabEngine.portfolioValue(holdings) }
    private var totalCost: Double { WealthLabEngine.portfolioCost(holdings) }
    private var gain: Double { totalValue - totalCost }
    private var gainPercent: Double { totalCost > 0 ? gain / totalCost * 100 : 0 }

    private var slices: [DonutSlice] {
        WealthLabEngine.allocation(holdings: holdings).map {
            DonutSlice(label: $0.label, value: $0.value, color: VaultTheme.tint(for: $0.colorKey))
        }
    }

    private var actions: [RebalanceAction] { WealthLabEngine.rebalance(holdings: holdings) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if holdings.isEmpty {
                    emptyState
                } else {
                    allocationCard
                    holdingsCard
                    rebalanceCard
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Portfolio")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    refreshQuotes()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                Button {
                    editingHolding = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            HoldingEditor(holding: editingHolding)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PORTFOLIO VALUE").font(.caption2).bold().opacity(0.85)
                Spacer()
                Image(systemName: "chart.pie.fill").font(.title3)
            }
            Text(WealthLabEngine.formatted(totalValue, currency: storage.profile.currency))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
            HStack(spacing: 6) {
                Image(systemName: gain >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text("\(WealthLabEngine.formatted(abs(gain), currency: storage.profile.currency)) (\(WealthLabEngine.percent(abs(gainPercent)))) all time")
            }
            .font(.caption).bold()
            .opacity(0.9)
            Text("Cost basis \(WealthLabEngine.formatted(totalCost, currency: storage.profile.currency)) · \(holdings.count) holding(s)")
                .font(.caption2).opacity(0.8)
            if let lastRefresh {
                Text("Quotes refreshed \(lastRefresh.formatted(.relative(presentation: .named)))")
                    .font(.caption2).opacity(0.75)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(gain >= 0 ? VaultTheme.savingsGradient : VaultTheme.warningGradient)
        )
    }

    private var allocationCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Allocation", subtitle: "By asset class")
                HStack(spacing: 16) {
                    VaultDonutChart(slices: slices, lineWidth: 18,
                                    centerTitle: WealthLabEngine.formatted(totalValue, currency: storage.profile.currency),
                                    centerSubtitle: "Total")
                        .frame(width: 145, height: 145)
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(slices) { slice in
                            HStack(spacing: 6) {
                                Circle().fill(slice.color).frame(width: 8, height: 8)
                                Text(slice.label).font(.caption2)
                                Spacer()
                                Text(totalValue > 0 ? WealthLabEngine.percent(slice.value / totalValue * 100) : "0%")
                                    .font(.caption2).bold()
                            }
                        }
                    }
                }
            }
        }
    }

    private var holdingsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Holdings",
                                   subtitle: "Tap edit to update shares or price")
                ForEach(holdings) { holding in
                    Button {
                        editingHolding = holding
                        showingEditor = true
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(VaultTheme.tint(for: WealthLabEngine.allocationColor(for: holding.assetClass)).opacity(0.14))
                                    .frame(width: 36, height: 36)
                                Text(String(holding.symbol.prefix(2)))
                                    .font(.caption2).bold()
                                    .foregroundColor(VaultTheme.tint(for: WealthLabEngine.allocationColor(for: holding.assetClass)))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(holding.symbol).font(.caption).bold().foregroundColor(.primary)
                                Text("\(holding.shares.formatted(.number.precision(.fractionLength(0...3)))) @ \(WealthLabEngine.formatted(holding.currentPrice, currency: storage.profile.currency))")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(WealthLabEngine.formatted(holding.marketValue, currency: storage.profile.currency))
                                    .font(.caption).bold().foregroundColor(.primary)
                                Text("\(holding.gainLoss >= 0 ? "+" : "−")\(WealthLabEngine.percent(abs(holding.gainLossPercent)))")
                                    .font(.caption2).bold()
                                    .foregroundColor(holding.gainLoss >= 0 ? VaultTheme.green : VaultTheme.red)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                    if holding.id != holdings.last?.id { Divider() }
                }
            }
        }
    }

    private var rebalanceCard: some View {
        VaultCard(tint: VaultTheme.purple) {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Rebalance",
                                   subtitle: "Targets are percentages of the whole portfolio")
                if actions.isEmpty {
                    Text("Add target weights to see drift.").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(actions) { action in
                        HStack(spacing: 8) {
                            Text(action.symbol).font(.caption).bold().frame(width: 48, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Now \(WealthLabEngine.percent(action.currentPercent)) · Target \(WealthLabEngine.percent(action.targetPercent))")
                                    .font(.caption2).foregroundColor(.secondary)
                                Text("Drift \(action.drift >= 0 ? "+" : "")\(WealthLabEngine.percent(action.drift))")
                                    .font(.caption2)
                                    .foregroundColor(abs(action.drift) < 1 ? VaultTheme.green : VaultTheme.orange)
                            }
                            Spacer()
                            Text(action.recommendation)
                                .font(.caption2).bold()
                                .foregroundColor(action.dollarAction >= 0 ? VaultTheme.blue : VaultTheme.red)
                        }
                        .padding(.vertical, 3)
                    }
                    Text("Set weights so they add up to 100% for the cleanest guidance.")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VaultCard {
            VaultEmptyState(icon: "chart.pie.fill", title: "No holdings yet",
                            message: "Add a stock, ETF, crypto position or cash balance.",
                            actionTitle: "Add holding") {
                editingHolding = nil
                showingEditor = true
            }
        }
    }

    private func refreshQuotes() {
        let trending = Dictionary(uniqueKeysWithValues: MarketDataService.shared.trendingStocks.map { ($0.symbol, $0.price) })
        for index in storage.portfolioHoldings.indices {
            let symbol = storage.portfolioHoldings[index].symbol.uppercased()
            if let price = trending[symbol] {
                storage.portfolioHoldings[index].currentPrice = price
                storage.portfolioHoldings[index].lastUpdated = Date()
            } else if let item = storage.watchlist.first(where: { $0.symbol.uppercased() == symbol }) {
                storage.portfolioHoldings[index].currentPrice = item.price
                storage.portfolioHoldings[index].lastUpdated = Date()
            }
        }
        lastRefresh = Date()
        storage.save()
    }
}

// MARK: - Holding editor

struct HoldingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    private let existing: PortfolioHolding?
    private let assetClasses = ["Stock", "ETF", "Crypto", "Bond", "Cash", "Real Estate"]

    @State private var symbol: String
    @State private var name: String
    @State private var shares: String
    @State private var averageCost: String
    @State private var currentPrice: String
    @State private var assetClass: String
    @State private var targetWeight: String

    init(holding: PortfolioHolding?) {
        existing = holding
        _symbol = State(initialValue: holding?.symbol ?? "")
        _name = State(initialValue: holding?.name ?? "")
        _shares = State(initialValue: holding.map { String($0.shares) } ?? "")
        _averageCost = State(initialValue: holding.map { String($0.averageCost) } ?? "")
        _currentPrice = State(initialValue: holding.map { String($0.currentPrice) } ?? "")
        _assetClass = State(initialValue: holding?.assetClass ?? "ETF")
        _targetWeight = State(initialValue: holding.map { String($0.targetWeight) } ?? "0")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Symbol", text: $symbol)
                        .onChange(of: symbol) { _, newValue in
                            let upper = newValue.uppercased()
                            if upper != newValue { symbol = upper }
                        }
                    TextField("Name", text: $name)
                    Picker("Asset class", selection: $assetClass) {
                        ForEach(assetClasses, id: \.self) { Text($0).tag($0) }
                    }
                } header: { Text("Holding") }
                Section {
                    TextField("Shares / units", text: $shares).keyboardType(.decimalPad)
                    TextField("Average cost per share", text: $averageCost).keyboardType(.decimalPad)
                    TextField("Current price", text: $currentPrice).keyboardType(.decimalPad)
                    TextField("Target weight %", text: $targetWeight).keyboardType(.decimalPad)
                } header: { Text("Position") }
                Section {
                    Button(existing == nil ? "Add holding" : "Save changes") { save() }
                        .frame(maxWidth: .infinity)
                        .disabled(symbol.trimmingCharacters(in: .whitespaces).isEmpty)
                    if existing != nil {
                        Button("Delete holding", role: .destructive) { delete() }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Holding" : "Edit Holding")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let holding = PortfolioHolding(
            id: existing?.id ?? UUID(),
            symbol: symbol.uppercased().trimmingCharacters(in: .whitespaces),
            name: name,
            shares: Double(shares) ?? 0,
            averageCost: Double(averageCost) ?? 0,
            currentPrice: Double(currentPrice) ?? 0,
            assetClass: assetClass,
            targetWeight: Double(targetWeight) ?? 0,
            lastUpdated: Date()
        )
        if let index = storage.portfolioHoldings.firstIndex(where: { $0.id == holding.id }) {
            storage.portfolioHoldings[index] = holding
        } else {
            storage.portfolioHoldings.append(holding)
        }
        storage.save()
        dismiss()
    }

    private func delete() {
        guard let existing else { return }
        storage.portfolioHoldings.removeAll { $0.id == existing.id }
        storage.save()
        dismiss()
    }
}
