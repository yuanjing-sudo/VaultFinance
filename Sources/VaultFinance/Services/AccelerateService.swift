import Foundation

// MARK: - Financial signal processing helpers
// Kept pure-Swift so the package builds reliably across toolchains.

@MainActor
final class AccelerateService {
    static let shared = AccelerateService()
    private init() {}

    /// Detect a repeating spending cycle by checking autocorrelation over candidate periods.
    func detectSpendingCycle(dailyAmounts: [Double]) -> (dominantPeriodDays: Int, strength: Double) {
        guard dailyAmounts.count >= 7 else { return (0, 0) }

        let maxPeriod = min(dailyAmounts.count / 2, 30)
        var bestPeriod = 0
        var bestStrength: Double = 0

        for period in 2...maxPeriod {
            var numerator = 0.0
            var denominatorA = 0.0
            var denominatorB = 0.0
            let mean = dailyAmounts.reduce(0, +) / Double(dailyAmounts.count)

            for i in period..<dailyAmounts.count {
                let a = dailyAmounts[i] - mean
                let b = dailyAmounts[i - period] - mean
                numerator += a * b
                denominatorA += a * a
                denominatorB += b * b
            }

            let denominator = sqrt(max(denominatorA * denominatorB, 1e-9))
            let strength = denominator == 0 ? 0 : numerator / denominator
            if strength > bestStrength {
                bestStrength = strength
                bestPeriod = period
            }
        }

        return (bestPeriod, max(bestStrength, 0))
    }

    /// Compute the slope and intercept of spending over time via least squares.
    func spendingTrend(dailyAmounts: [Double]) -> (slope: Double, intercept: Double) {
        let n = dailyAmounts.count
        guard n > 1 else { return (0, 0) }

        let x = stride(from: 0, to: n, by: 1).map { Double($0) }
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumXX: Double = 0

        for i in 0..<n {
            sumX += x[i]
            sumY += dailyAmounts[i]
            sumXY += x[i] * dailyAmounts[i]
            sumXX += x[i] * x[i]
        }

        let denom = Double(n) * sumXX - sumX * sumX
        guard denom != 0 else { return (0, sumY / Double(n)) }

        let slope = (Double(n) * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / Double(n)
        return (slope, intercept)
    }

    /// Compute standard deviation for daily spending values.
    func spendingVolatility(dailyAmounts: [Double]) -> Double {
        guard !dailyAmounts.isEmpty else { return 0 }
        let mean = dailyAmounts.reduce(0, +) / Double(dailyAmounts.count)
        let variance = dailyAmounts.reduce(0.0) { partial, value in
            let delta = value - mean
            return partial + delta * delta
        } / Double(dailyAmounts.count)
        return sqrt(max(variance, 0))
    }

    /// Compute portfolio weighted return using a weighted average of asset returns.
    func portfolioReturn(weights: [Double], returns: [Double]) -> Double {
        guard weights.count == returns.count, !weights.isEmpty else { return 0 }
        let weightSum = weights.reduce(0, +)
        guard weightSum != 0 else { return 0 }
        let weightedReturn = zip(weights, returns).reduce(0.0) { partial, pair in
            partial + pair.0 * pair.1
        }
        return weightedReturn / weightSum
    }

    /// Pearson correlation between two spending series.
    func correlation(seriesA: [Double], seriesB: [Double]) -> Double {
        guard seriesA.count == seriesB.count, seriesA.count > 1 else { return 0 }

        let meanA = seriesA.reduce(0, +) / Double(seriesA.count)
        let meanB = seriesB.reduce(0, +) / Double(seriesB.count)

        var numerator = 0.0
        var denominatorA = 0.0
        var denominatorB = 0.0

        for i in 0..<seriesA.count {
            let diffA = seriesA[i] - meanA
            let diffB = seriesB[i] - meanB
            numerator += diffA * diffB
            denominatorA += diffA * diffA
            denominatorB += diffB * diffB
        }

        let denominator = sqrt(max(denominatorA * denominatorB, 1e-9))
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }

    /// Simple moving average using a sliding-window average.
    func movingAverage(values: [Double], window: Int) -> [Double] {
        guard window > 0, !values.isEmpty else { return values }
        var result = [Double](repeating: 0, count: values.count)

        for index in 0..<values.count {
            let start = max(0, index - window + 1)
            let end = min(values.count, index + 1)
            let slice = Array(values[start..<end])
            result[index] = slice.reduce(0, +) / Double(slice.count)
        }

        return result
    }
}
