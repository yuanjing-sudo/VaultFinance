import Foundation
import Accelerate

// MARK: - Accelerate Framework Integration
// Uses vDSP, vImage, simd, and BLAS for financial signal processing and math.

final class AccelerateService {
    static let shared = AccelerateService()
    private init() {}

    // MARK: - Spending Cycle Analysis (vDSP FFT)

    /// Detect recurring weekly/monthly spending cycles using FFT on daily spending amounts.
    func detectSpendingCycle(dailyAmounts: [Double]) -> (dominantPeriodDays: Int, strength: Double) {
        let n = dailyAmounts.count
        guard n >= 4 else { return (0, 0) }

        let log2n = vDSP_Length(log2(Double(n)))
        let fftSetup = vDSP_DFT_zop_CreateSetup(nil, n, vDSP_DFT_Direction.FORWARD)

        var realIn = dailyAmounts
        var imagIn = [Double](repeating: 0, count: n)
        var realOut = [Double](repeating: 0, count: n)
        var imagOut = [Double](repeating: 0, count: n)

        var complexIn = [DSPSplitComplex(realp: &realIn, imagp: &imagIn)]
        var complexOut = [DSPSplitComplex(realp: &realOut, imagp: &imagOut)]

        vDSP_DFT_zop_Execute(fftSetup, &complexIn, &complexOut)
        vDSP_DFT_zop_DestroySetup(fftSetup)

        // Compute magnitudes
        var magnitudes = [Double](repeating: 0, count: n / 2)
        vDSP_zvmagsD(&complexOut[0], 1, &magnitudes, 1, vDSP_Length(n / 2))

        // Find peak (skip DC component at index 0)
        var maxMag: Double = 0
        var maxIndex: vDSP_Length = 1
        for i in 1..<n / 2 {
            if magnitudes[i] > maxMag {
                maxMag = magnitudes[i]
                maxIndex = vDSP_Length(i)
            }
        }

        let totalEnergy = magnitudes.reduce(0, +)
        let strength = totalEnergy > 0 ? maxMag / totalEnergy : 0

        // Convert bin index to period in days
        let period = maxIndex == 0 ? 0 : Int(round(Double(n) / Double(maxIndex)))
        return (period, strength)
    }

    // MARK: - Spending Trend (vDSP linear regression / least squares)

    /// Compute the slope (trend) of spending over time using least squares.
    func spendingTrend(dailyAmounts: [Double]) -> (slope: Double, intercept: Double) {
        let n = dailyAmounts.count
        guard n > 1 else { return (0, 0) }

        let x = stride(from: 0, to: n, by: 1).map { Double($0) }
        var sumX: Double = 0, sumY: Double = 0, sumXY: Double = 0, sumXX: Double = 0
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

    // MARK: - Volatility (standard deviation via vDSP)

    func spendingVolatility(dailyAmounts: [Double]) -> Double {
        guard !dailyAmounts.isEmpty else { return 0 }
        let mean = dailyAmounts.reduce(0, +) / Double(dailyAmounts.count)
        var squaredDiffs = [Double](repeating: 0, count: dailyAmounts.count)
        vDSP_vsqd(dailyAmounts, 1, &squaredDiffs, 1, vDSP_Length(dailyAmounts.count))
        var meanSq: Double = 0
        vDSP_meanvd(squaredDiffs, 1, &meanSq, vDSP_Length(dailyAmounts.count))
        let variance = meanSq - mean * mean
        return sqrt(max(variance, 0))
    }

    // MARK: - Portfolio Returns (simd vector math)

    /// Compute portfolio weighted return using simd.
    func portfolioReturn(weights: [Double], returns: [Double]) -> Double {
        guard weights.count == returns.count, !weights.isEmpty else { return 0 }
        let w = simd_double1d(weights)
        let r = simd_double1d(returns)
        let dot = simd_dot(w, r)
        let weightSum = weights.reduce(0, +)
        guard weightSum != 0 else { return 0 }
        return dot / weightSum
    }

    // MARK: - Correlation between two spending series

    func correlation(seriesA: [Double], seriesB: [Double]) -> Double {
        guard seriesA.count == seriesB.count, seriesA.count > 1 else { return 0 }
        let n = seriesA.count
        let meanA = seriesA.reduce(0, +) / Double(n)
        let meanB = seriesB.reduce(0, +) / Double(n)
        var cov: Double = 0, varA: Double = 0, varB: Double = 0
        for i in 0..<n {
            let da = seriesA[i] - meanA
            let db = seriesB[i] - meanB
            cov += da * db
            varA += da * da
            varB += db * db
        }
        let denom = sqrt(varA * varB)
        guard denom != 0 else { return 0 }
        return cov / denom
    }

    // MARK: - Moving Average (vDSP)

    func movingAverage(values: [Double], window: Int) -> [Double] {
        guard window > 0, !values.isEmpty else { return values }
        var result = [Double](repeating: 0, count: values.count)
        vDSP_vmovavgD(values, 1, [Double](repeating: 1.0 / Double(window), count: window), &result, 1, vDSP_Length(values.count), vDSP_Length(window))
        return result
    }
}
