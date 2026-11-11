import SwiftUI

struct NetWorthView: View {
    let netWorth: Double
    let totalAssets: Double
    let totalLiabilities: Double

    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Net Worth Card
                VStack(spacing: 12) {
                    Text("Net Worth").font(.headline)
                    Text(Money(amount: netWorth).formatted()).font(.title).bold()
                    Text("Assets: \(Money(amount: totalAssets).formatted()) · Liabilities: \(Money(amount: totalLiabilities).formatted())").font(.subheadline).foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(16)

                if let healthScore = storage.healthScores.last {
                    FinancialHealthScoreView(score: healthScore)
                }

                // Growth Projection
                GrowthProjectionView(currentValue: netWorth)

                // Asset Allocation
                AssetAllocationView(assets: storage.assets)
            }
            .padding()
        }
    }
}

struct FinancialHealthScoreView: View {
    @EnvironmentObject var storage: LocalStorage
    let score: FinancialHealthScore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Health Score").font(.headline)
            HStack {
                Text("\(score.score)/100").font(.title).bold()
                Spacer()
                Text(score.recommendation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ForEach(score.factors) { factor in
                HStack {
                    VStack(alignment: .leading) {
                        Text(factor.name).font(.subheadline)
                        Text(factor.description).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(factor.score)/100").font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
    }
}

struct GrowthProjectionView: View {
    let currentValue: Double

    @State private var annualRate: Double = 5
    @State private var years: Int = 5

    var projectedPoints: [ProjectedPoint] {
        FinanceEngine.projectGrowth(current: currentValue, annualRate: annualRate, months: years * 12)
    }

    var finalValue: String {
        projectedPoints.last?.formattedValue ?? Money(amount: currentValue).formatted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wealth Projection").font(.headline)
                Spacer()
                Stepper("Rate: \(annualRate, specifier: "%.1f")%", value: $annualRate, in: 0...12, step: 0.5)
                Stepper("Years: \(years)", value: $years, in: 1...30, step: 1)
            }
            Text("Projected in \(years) years:").font(.subheadline)
            Text(finalValue).font(.title2).bold()
            // Simplified chart
            GeometryReader { geo in
                Path { path in
                    guard projectedPoints.count >= 2 else { return }
                    let xStep = geo.size.width / CGFloat(projectedPoints.count - 1)
                    let yMin = projectedPoints.min(by: { $0.projectedNetWorth < $1.projectedNetWorth })?.projectedNetWorth ?? 0
                    let yMax = projectedPoints.max(by: { $0.projectedNetWorth < $1.projectedNetWorth })?.projectedNetWorth ?? 1
                    let range = max(yMax - yMin, 1)

                    for (i, point) in projectedPoints.enumerated() {
                        let x = CGFloat(i) * xStep
                        let y = geo.size.height - ((point.projectedNetWorth - yMin) / range) * geo.size.height
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
            }
            .frame(height: 150)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
    }
}

struct AssetAllocationView: View {
    let assets: [AssetHolding]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Allocation").font(.headline)
            ForEach(assets) { asset in
                HStack {
                    Color.gray.opacity(0.12)
                        .frame(width: 24)
                    Text(asset.title).font(.subheadline)
                    Spacer()
                    Text(Money(amount: asset.currentMarketValue).formatted()).bold()
                }
                .padding(.vertical, 2)
            }
            if assets.isEmpty {
                Text("No assets tracked. Add your holdings in the Assets tab.").foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
    }

    func assetColor(_ category: AssetCategory) -> String {
        switch category {
        case .cash: return "#3b82f6"
        case .stock: return "#22c55e"
        case .realEstate: return "#14b8a6"
        case .alternative: return "#f59e0b"
        }
    }
}
