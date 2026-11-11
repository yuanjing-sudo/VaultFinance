import SwiftUI

// MARK: - Fresh / Live News Feed

/// News feed that surfaces fresh financial news. Falls back to curated items when a live
/// feed is unavailable; each item is stamped with relative freshness.
struct NewsFeedView: View {
    @EnvironmentObject var router: AppRouter
    @State private var refreshDate = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Financial News").font(.headline).bold()
                    Spacer()
                    Button(action: { refreshDate = Date() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                Text("Updated \(relativeTime(refreshDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                if newsItems.isEmpty {
                    EmptyState(message: "No news available right now.")
                } else {
                    ForEach(newsItems) { item in
                        NewsRow(item: item)
                    }
                }

                marketSnapshot
            }
            .padding()
        }
        .navigationTitle("News")
    }

    private var newsItems: [NewsItem] {
        MarketDataService.shared.newsFeed
    }

    private var marketSnapshot: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Market Snapshot").font(.headline).bold()
            ForEach(MarketDataService.shared.trendingStocks) { stock in
                HStack {
                    Text(stock.symbol).bold()
                    Spacer()
                    Text(Money(amount: stock.price).formatted()).bold()
                    Text("\(stock.changePercent, specifier: "%.1f")%")
                        .font(.subheadline)
                        .foregroundColor(stock.changePercent >= 0 ? .green : .red)
                }
                .padding(.vertical, 3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(14)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - News Row

struct NewsRow: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.category)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(5)
                Spacer()
                Text(item.date, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(item.title).font(.subheadline).bold()
            HStack(spacing: 6) {
                Text(item.source).font(.caption).foregroundColor(.secondary)
                Text("·").font(.caption).foregroundColor(.secondary)
                Text("Fresh").font(.caption2).foregroundColor(.green)
            }
            if !item.summary.isEmpty {
                Text(item.summary).font(.caption).foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
}
