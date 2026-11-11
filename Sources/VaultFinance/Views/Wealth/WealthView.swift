import SwiftUI

struct WealthView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var marketDataService: MarketDataService

    var totalAssets: Double {
        storage.assets.reduce(0) { $0 + $1.currentMarketValue }
    }

    var totalLiabilities: Double {
        storage.liabilities.reduce(0) { $0 + $1.balance }
    }

    var netWorth: Double {
        let cashSavings = storage.profile.existingSavings
        return FinanceEngine.computeNetWorth(assets: storage.assets, liabilities: storage.liabilities, cashInBank: cashSavings, savingsAccounts: 0).netWorth
    }

    var body: some View {
        NavigationStack {
            TabView {
                NetWorthView(netWorth: netWorth, totalAssets: totalAssets, totalLiabilities: totalLiabilities)
                    .tabItem { Label("Portfolio", systemImage: "chart.bar.fill") }

                AssetListView(assets: storage.assets)
                    .tabItem { Label("Assets", systemImage: "wallet") }

                MarketInsightsView()
                    .tabItem { Label("Markets", systemImage: "globe") }
            }
            .navigationTitle("Wealth")
        }
    }
}
