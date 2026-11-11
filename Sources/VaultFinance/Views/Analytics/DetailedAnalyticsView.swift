import SwiftUI

// MARK: - Detailed Analytics View

/// Deep-dive analytics powered by the Accelerate framework (FFT, vDSP, simd).
/// Shows spending cycle detection, trend, volatility, moving averages, and correlation.
struct DetailedAnalyticsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var selectedDays: Int = 30

    var dailyAmounts: [Double] {
        let calendar = Calendar.current
        let now = Date()
        var amounts: [Double] = []
        for i in 0..<selectedDays {
            if let date = calendar.date(byAdding: .day, value: -(selectedDays - 1 - i), to: now) {
                let dayStart = calendar.startOfDay(for: date)
                let dayTotal = storage.spendingDays
                    .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                    .reduce(0) { $0 + $1.amount }
                amounts.append(dayTotal)
            }
        }
        return amounts
    }

    var cycleAnalysis: (period: Int, strength: Double) {
        AccelerateService.shared.detectSpendingCycle(dailyAmounts: dailyAmounts)
    }

    var trend: (slope: Double, intercept: Double) {
        AccelerateService.shared.spendingTrend(dailyAmounts: dailyAmounts)
    }

    var volatility: Double {
        AccelerateService.shared.spendingVolatility(dailyAmounts: dailyAmounts)
    }

    var movingAvg: [Double] {
        AccelerateService.shared.movingAverage(values: dailyAmounts, window: 7)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detailed Analytics")
                        .font(.title2).bold()
                    Text("Powered by Accelerate framework (vDSP, FFT, simd)")
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Time range selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Period").font(.subheadline).bold()
                    Picker("Days", selection: $selectedDays) {
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                        Text("60 Days").tag(60)
                        Text("90 Days").tag(90)
                    }
                    .pickerStyle(.segmented)
                }

                // Spending Cycle
                analyticsCard(title: "Spending Cycle Detection",
                              subtitle: "Recurring pattern found via FFT",
                              icon: "waveform",
                              content: {
                                  HStack {
                                      VStack(alignment: .leading, spacing: 4) {
                                          Text("Dominant Period")
                                              .font(.caption).foregroundColor(.secondary)
                                          Text("\(cycleAnalysis.period) days")
                                              .font(.title2).bold()
                                      }
                                      Spacer()
                                      VStack(alignment: .trailing, spacing: 4) {
                                          Text("Cycle Strength")
                                              .font(.caption).foregroundColor(.secondary)
                                          Text("\(cycleAnalysis.strength, specifier: "%.0f")%")
                                              .font(.title2).bold()
                                              .foregroundColor(cycleAnalysis.strength > 0.5 ? .green : .orange)
                                      }
                                  }
                              })

                // Spending Trend
                analyticsCard(title: "Spending Trend",
                              subtitle: "Least-squares regression over period",
                              icon: "chart.line.uptrend.xyaxis",
                              content: {
                                  HStack {
                                      VStack(alignment: .leading, spacing: 4) {
                                          Text("Daily Trend")
                                              .font(.caption).foregroundColor(.secondary)
                                          Text(trend.slope >= 0 ? "+\(trend.slope, specifier: "%.2f")" : "\(trend.slope, specifier: "%.2f")")
                                              .font(.title2).bold()
                                              .foregroundColor(trend.slope > 0 ? .red : .green)
                                          Text("/day").font(.caption2).foregroundColor(.secondary)
                                      }
                                      Spacer()
                                      VStack(alignment: .trailing, spacing: 4) {
                                          Text("Direction")
                                              .font(.caption).foregroundColor(.secondary)
                                          Text(trend.slope > 0 ? "Increasing 📈" : trend.slope < 0 ? "Decreasing 📉" : "Stable ➡️")
                                              .font(.subheadline).bold()
                                      }
                                  }
                              })

                // Volatility
                analyticsCard(title: "Spending Volatility",
                              subtitle: "Standard deviation of daily spending",
                              icon: "arrow.left.arrow.right",
                              content: {
                                  HStack {
                                      VStack(alignment: .leading, spacing: 4) {
                                          Text("Volatility")
                                              .font(.caption).foregroundColor(.secondary)
                                          Text(Money(amount: volatility).formatted())
                                              .font(.title2).bold()
                                      }
                                      Spacer()
                                      VStack(alignment: .trailing, spacing: 4) {
                                          Text("Consistency")
                                              .font(.caption).foregroundColor(.secondary)
                                          Text(volatility < 20 ? "High" : volatility < 50 ? "Medium" : "Low")
                                              .font(.subheadline).bold()
                                              .foregroundColor(volatility < 20 ? .green : .orange)
                                      }
                                  }
                              })

                // Moving Average Chart
                movingAverageChart

                // Insights
                insightsSection
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private func analyticsCard<Content: View>(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title).font(.headline).bold()
                Spacer()
                Text(subtitle).font(.caption2).foregroundColor(.secondary)
            }
            content()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private var movingAverageChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Moving Average").font(.headline).bold()
            GeometryReader { geo in
                ZStack {
                    let points = movingAvg
                    guard points.count > 1 else {
                        Text("Not enough data").foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        return EmptyView()
                    }
                    let maxVal = points.max() ?? 1
                    let minVal = points.min() ?? 0
                    let range = max(maxVal - minVal, 1)
                    let width = geo.size.width
                    let height = geo.size.height
                    let xStep = width / CGFloat(points.count - 1)

                    Path { path in
                        for (i, val) in points.enumerated() {
                            let x = CGFloat(i) * xStep
                            let y = height - ((val - minVal) / range) * height
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)

                    // Area fill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        for (i, val) in points.enumerated() {
                            let x = CGFloat(i) * xStep
                            let y = height - ((val - minVal) / range) * height
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(Color.blue.opacity(0.15))
                }
            }
            .frame(height: 140)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Insights").font(.headline).bold()
            VStack(spacing: 8) {
                InsightRow(icon: "lightbulb.fill", text: "Your spending shows a \(cycleAnalysis.period)-day cycle with \(Int(cycleAnalysis.strength * 100))% strength.", color: .blue)
                InsightRow(icon: trend.slope > 0 ? "arrow.up" : "arrow.down", text: trend.slope > 0 ? "Spending is increasing by \(Money(amount: trend.slope).formatted()) per day." : "Spending is decreasing — great job!", color: trend.slope > 0 ? .red : .green)
                InsightRow(icon: "chart.bar", text: "Volatility is \(Money(amount: volatility).formatted()) — \(volatility < 20 ? "very consistent" : "moderate variation").", color: .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text).font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
