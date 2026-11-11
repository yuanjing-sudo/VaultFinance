import SwiftUI

struct AssetListView: View {
    @EnvironmentObject var storage: LocalStorage
    let assets: [AssetHolding]

    @State private var showAddAsset = false

    var body: some View {
        VStack(spacing: 16) {
            if assets.isEmpty {
                EmptyState(message: "No assets tracked. Tap + to add.")
            } else {
                GroupBox(label: Text("Your Assets")) {
                    ForEach(assets) { asset in
                        AssetRowView(asset: asset)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Assets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddAsset.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAsset) {
            AddAssetView()
        }
    }
}

struct AssetRowView: View {
    let asset: AssetHolding

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: asset.category.iconName)
                    .foregroundColor(.init(colorLiteral: assetCategoryColor(asset.category)))
                Text(asset.title).font(.subheadline).bold()
                Spacer()
                VStack(alignment: .trailing) {
                    Text(Money(amount: asset.currentMarketValue).formatted()).bold()
                    Text("\(asset.unrealizedGainLossPercent, specifier: "%.1f")% (\(Money(amount: asset.unrealizedGainLoss).formatted()))")
                        .font(.caption)
                        .foregroundColor(asset.unrealizedGainLoss >= 0 ? .green : .red)
                }
            }
            HStack {
                Text("Cost: \(Money(amount: asset.costBasis).formatted())").font(.caption).foregroundColor(.secondary)
                Text("· Qty: \(asset.quantity)").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text(asset.category.localized).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    func assetCategoryColor(_ category: AssetCategory) -> String {
        switch category {
        case .cash: return "#3b82f6"
        case .stock: return "#22c55e"
        case .realEstate: return "#14b8a6"
        case .alternative: return "#f59e0b"
        }
    }
}

struct AddAssetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var category: AssetCategory = .cash
    @State private var quantity: Double = 1
    @State private var costBasis: String = ""
    @State private var currentValue: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(AssetCategory.allCases, id: \.self) {
                            Text($0.localizedDescription).tag($0)
                        }
                    }
                }
                Section(header: Text("Values")) {
                    TextField("Quantity", value: $quantity, format: .number)
                    TextField("Cost Basis", text: $costBasis)
                        .keyboardType(.decimalPad)
                    TextField("Current Market Value", text: $currentValue)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Button("Add Asset") {
                        addAsset()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Asset")
        }
    }

    func addAsset() {
        guard let cost = Double(costBasis), let current = Double(currentValue) else { return }
        let asset = AssetHolding(
            title: title.isEmpty ? "New Asset" : title,
            category: category,
            quantity: quantity,
            costBasis: cost,
            currentMarketValue: current
        )
        storage.assets.append(asset)
    }
}

private extension String {
    var localized: String { self }
}
