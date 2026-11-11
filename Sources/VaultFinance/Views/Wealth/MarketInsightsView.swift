import SwiftUI

struct MarketInsightsView: View {
    @EnvironmentObject var marketDataService: MarketDataService
    @State private var searchQuery = ""
    @State private var selectedStock: MarketStock?

    var filteredStocks: [MarketStock] {
        guard !searchQuery.isEmpty else { return marketDataService.trendingStocks }
        return marketDataService.search(query: searchQuery)
    }

    var insights: [String] {
        marketDataService.marketInsights
    }

    var news: [NewsItem] {
        marketDataService.newsFeed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Market Insights
                if !insights.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Market Insights").bold().font(.headline)
                        ForEach(insights, id: \.self) { insight in
                            Text(insight).font(.subheadline)
                        }
                    }
                }

                // Trending Stocks
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Trending Stocks").bold().font(.headline)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search symbol or name", text: $searchQuery)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)

                    ForEach(filteredStocks) { stock in
                        StockRowView(stock: stock)
                    }
                }

                // News Feed
                VStack(alignment: .leading, spacing: 10) {
                    Text("Financial News").bold().font(.headline)
                    ForEach(news) { item in
                        NewsRowView(item: item)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Markets")
    }
}

struct StockRowView: View {
    let stock: MarketStock

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol).bold().font(.subheadline)
                    Text(stock.name).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(Money(amount: stock.price).formatted()).bold()
                    Text("\(stock.changePercent, specifier: "%.1f")%").font(.caption)
                        .foregroundColor(stock.changePercent >= 0 ? .green : .red)
                }
            }
            HStack(spacing: 8) {
                Text("P/E: \(stock.peRatio, specifier: "%.1f")").font(.caption).foregroundColor(.secondary)
                Text("· Rev Growth: \(stock.revenueGrowth, specifier: "%.1f")%").font(.caption).foregroundColor(.secondary)
                Text("· Margin: \(stock.profitMargin, specifier: "%.1f")%").font(.caption).foregroundColor(.secondary)
                Text("· Risk: \(stock.riskLevel.rawValue)").font(.caption).foregroundColor(.secondary)
            }
            Text(stock.trendReason).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct NewsRowView: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title).bold().font(.subheadline)
            HStack {
                Text(item.source).font(.caption).foregroundColor(.secondary)
                Text("· \(item.category)").font(.caption).foregroundColor(.secondary)
            }
            if !item.summary.isEmpty {
                Text(item.summary).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
