import Foundation

// MARK: - Market Data & News Service (Educational, mock data for local build)
// In production, replace with Alpha Vantage / Polygon / Financial Modeling Prep APIs.

class MarketDataService: ObservableObject, @unchecked Sendable {
    static let shared = MarketDataService()

    private init() {}

    // MARK: - Mock trending stocks

    var trendingStocks: [MarketStock] {
        [
            .init(symbol: "NVDA", name: "NVIDIA Corporation", price: 875.28, changePercent: 3.2,
                  marketCap: 2150000000000, peRatio: 68.5, revenueGrowth: 126.0, profitMargin: 55.0,
                  riskLevel: .high,
                  trendReason: "Data center demand and AI chip leadership drive strong quarterly growth.",
                  description: "Leader in AI accelerators and data center GPUs."),
            .init(symbol: "AVGO", name: "Broadcom Inc.", price: 1342.50, changePercent: 2.1,
                  marketCap: 625000000000, peRatio: 32.1, revenueGrowth: 47.0, profitMargin: 24.0,
                  riskLevel: .moderate,
                  trendReason: "AI networking and VMware integration exceed expectations.",
                  description: "Semiconductor and infrastructure software company."),
            .init(symbol: "MSFT", name: "Microsoft Corporation", price: 420.45, changePercent: 1.5,
                  marketCap: 3120000000000, peRatio: 36.8, revenueGrowth: 16.0, profitMargin: 36.0,
                  riskLevel: .moderate,
                  trendReason: "Azure cloud growth and AI integration across productivity suite.",
                  description: "Cloud computing, software, and AI services."),
            .init(symbol: "JPM", name: "JPMorgan Chase", price: 198.30, changePercent: 0.8,
                  marketCap: 570000000000, peRatio: 12.4, revenueGrowth: 8.0, profitMargin: 30.0,
                  riskLevel: .low,
                  trendReason: "Strong investment banking and net interest income.",
                  description: "Largest US bank by assets."),
        ]
    }

    // MARK: - Educational market insights

    var marketInsights: [String] {
        [
            "Interest rates have been a key driver of market volatility this quarter. Watch for central bank signals.",
            "Tech sector remains concentrated; consider diversifying across sectors to manage concentration risk.",
            "Inflation has cooled but remains above many central banks' targets. Bond yields may stay elevated.",
            "Dollar strength impacts emerging markets and commodity exporters.",
        ]
    }

    // MARK: - Sample news feed

    var newsFeed: [NewsItem] {
        [
            .init(title: "Fed Signals Potential Rate Cuts Later This Year", source: "MarketWatch", date: .init(), category: "Central Banks"),
            .init(title: "AI Chip Demand Shows No Signs of Slowing", source: "Bloomberg", date: .init(), category: "Technology"),
            .init(title: "Global Markets Rally on Inflation Data", source: "Reuters", date: .init(), category: "Markets"),
            .init(title: "What Is a Good Emergency Fund Size for 2026?", source: "Investopedia", date: .init(), category: "Personal Finance"),
        ]
    }

    // MARK: - Search stocks (educational)

    func search(query: String) -> [MarketStock] {
        guard !query.isEmpty else { return trendingStocks }
        let lower = query.lowercased()
        return trendingStocks.filter { $0.symbol.lowercased().contains(lower) || $0.name.lowercased().contains(lower) }
    }

    // MARK: - Educational explanations

    static func explainRisk(risk: MarketStock.InvestmentRisk) -> String {
        switch risk {
        case .low: return "Lower-risk investments typically offer more stable returns but lower potential growth."
        case .moderate: return "Moderate-risk investments balance potential returns with acceptable volatility."
        case .high: return "High-risk investments can deliver strong returns but may lose significant value."
        }
    }
}

struct NewsItem: Codable, Identifiable, Hashable {
    let id = UUID()
    var title: String
    var source: String
    var date: Date
    var category: String
    var summary: String

    init(title: String, source: String, date: Date, category: String, summary: String = "") {
        self.title = title
        self.source = source
        self.date = date
        self.category = category
        self.summary = summary.isEmpty ? "Summary unavailable in demo build." : summary
    }
}
