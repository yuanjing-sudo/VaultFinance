import SwiftUI

// MARK: - Watchlist & Price Alerts
// Track symbols, set target prices, and surface triggered alerts.

struct WatchlistView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAdd = false
    @State private var sortAscending = false

    private var items: [WatchlistItem] {
        let sorted = storage.watchlist.sorted { $0.symbol < $1.symbol }
        return sortAscending ? sorted : sorted.reversed()
    }

    private var triggered: [WatchlistItem] {
        storage.watchlist.filter { $0.isAlertTriggered }
    }

    private var totalValue: Double {
        storage.watchlist.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !triggered.isEmpty { alertBanner }
                summaryCard
                controls
                if items.isEmpty {
                    VaultEmptyState(icon: "star.slash", title: "No symbols yet",
                                    message: "Add stocks, ETFs, or crypto to track prices and alerts.",
                                    actionTitle: "Add Symbol") { showingAdd = true }
                } else {
                    ForEach(items) { item in
                        WatchlistRow(item: item) {
                            toggleAlert(item)
                        } onDelete: {
                            storage.watchlist.removeAll { $0.id == item.id }
                            storage.save()
                        }
                    }
                }
                forecastCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Watchlist")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddWatchlistItemSheet { item in
                storage.watchlist.append(item)
                storage.save()
            }
        }
    }

    // MARK: - Alert Banner

    private var alertBanner: some View {
        VaultCard(tint: VaultTheme.orange) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "bell.badge.fill").foregroundColor(VaultTheme.orange)
                    Text("\(triggered.count) alert\(triggered.count == 1 ? "" : "s") triggered")
                        .font(.subheadline).bold()
                }
                ForEach(triggered) { item in
                    Text("\(item.symbol) hit \(Money(amount: item.targetPrice ?? 0).formatted())")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VaultGradientCard(gradient: VaultTheme.brandGradient) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tracked").font(.caption).opacity(0.9)
                    Text("\(items.count) symbols").font(.title2).bold()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Combined quote").font(.caption).opacity(0.9)
                    Text(Money(amount: totalValue).formatted()).font(.title3).bold()
                }
            }
        }
    }

    private var controls: some View {
        HStack {
            VaultPill(text: "\(triggered.count) alerts", icon: "bell.fill",
                      color: triggered.isEmpty ? VaultTheme.green : VaultTheme.orange)
            Spacer()
            Button {
                withAnimation { sortAscending.toggle() }
            } label: {
                Label(sortAscending ? "A → Z" : "Z → A", systemImage: "arrow.up.arrow.down")
                    .font(.caption)
            }
        }
    }

    // MARK: - Forecast

    private var forecastCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Portfolio Mix", subtitle: "By symbol")
                VaultStackedBar(segments: storage.watchlist.prefix(6).enumerated().map { i, item in
                    DonutSlice(label: item.symbol, value: max(item.price, 1),
                               color: palette[i % palette.count])
                }, height: 14)
                HStack(spacing: 12) {
                    ForEach(recentSymbols.indices, id: \.self) { i in
                        let item = recentSymbols[i]
                        HStack(spacing: 4) {
                            Circle().fill(palette[i % palette.count]).frame(width: 7, height: 7)
                            Text(item.symbol).font(.caption2)
                        }
                    }
                }
            }
        }
    }

    private var palette: [Color] {
        [VaultTheme.blue, VaultTheme.green, VaultTheme.orange, VaultTheme.purple,
         VaultTheme.pink, VaultTheme.teal]
    }

    private var recentSymbols: [WatchlistItem] {
        Array(storage.watchlist.prefix(4))
    }

    private func toggleAlert(_ item: WatchlistItem) {
        guard let index = storage.watchlist.firstIndex(where: { $0.id == item.id }) else { return }
        storage.watchlist[index].alertAbove.toggle()
        storage.save()
    }
}

// MARK: - Row

struct WatchlistRow: View {
    let item: WatchlistItem
    var onToggle: () -> Void
    var onDelete: () -> Void

    private var positive: Bool { item.changePercent >= 0 }

    var body: some View {
        VaultCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(VaultTheme.blue.opacity(0.12)).frame(width: 42, height: 42)
                    Text(String(item.symbol.prefix(2)))
                        .font(.caption).bold().foregroundColor(VaultTheme.blue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.symbol).font(.subheadline).bold()
                    Text(item.name.isEmpty ? "Tracked asset" : item.name)
                        .font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    if let target = item.targetPrice {
                        Text("Alert \(item.alertAbove ? "above" : "below") \(Money(amount: target).formatted())")
                            .font(.caption2)
                            .foregroundColor(item.isAlertTriggered ? VaultTheme.orange : .secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(Money(amount: item.price).formatted())
                        .font(.subheadline).bold()
                    Text("\(positive ? "+" : "")\(item.changePercent, specifier: "%.2f")%")
                        .font(.caption2).bold()
                        .foregroundColor(positive ? VaultTheme.green : VaultTheme.red)
                }
            }
            .contextMenu {
                Button {
                    onToggle()
                } label: {
                    Label("Flip Alert Direction", systemImage: "arrow.triangle.swap")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Add Sheet

struct AddWatchlistItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (WatchlistItem) -> Void

    @State private var symbol = ""
    @State private var name = ""
    @State private var price = ""
    @State private var hasAlert = false
    @State private var target = ""
    @State private var alertAbove = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Symbol") {
                    TextField("AAPL", text: $symbol)
                    TextField("Company name", text: $name)
                    TextField("Current price", text: $price)
                        .keyboardType(.decimalPad)
                }
                Section("Alert") {
                    Toggle("Set price alert", isOn: $hasAlert)
                    if hasAlert {
                        TextField("Target price", text: $target)
                            .keyboardType(.decimalPad)
                        Picker("Notify when price is", selection: $alertAbove) {
                            Text("Above target").tag(true)
                            Text("Below target").tag(false)
                        }
                    }
                }
            }
            .navigationTitle("Add Symbol")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let item = WatchlistItem(
                            symbol: symbol.uppercased(),
                            name: name,
                            price: Double(price) ?? 0,
                            targetPrice: hasAlert ? Double(target) : nil,
                            alertAbove: alertAbove
                        )
                        onSave(item)
                        dismiss()
                    }
                    .bold()
                    .disabled(symbol.isEmpty)
                }
            }
        }
    }
}
