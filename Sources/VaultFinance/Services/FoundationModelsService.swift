import Foundation

// MARK: - Apple Foundation Models Integration
// Uses on-device Foundation Models (LLMModelSession) on iOS 18+/macOS 15+.
// Falls back to the existing deterministic AIService when unavailable.

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

actor FoundationModelsService {
    static let shared = FoundationModelsService()

    private init() {}

    /// Whether on-device Foundation Models are available.
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 18.0, macOS 15.0, *) {
            return true
        }
        #endif
        return false
    }

    /// Generate a financial insight using on-device Foundation Models.
    /// Falls back to a deterministic summary when the model is unavailable.
    func generateInsight(context: String) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 18.0, macOS 15.0, *), isAvailable {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: """
                You are a personal finance assistant. Keep answers concise, practical, and encouraging.
                Context: \(context)

                Provide 3 short, actionable insights.
                """)
                return response.content
            } catch {
                return fallbackInsight(context: context)
            }
        }
        #endif
        return fallbackInsight(context: context)
    }

    /// Generate a savings recommendation for a piggy bank.
    func generateSavingsRecommendation(deposited: Double, target: Double, currency: String) async -> String {
        let context = """
        User has deposited \(currency) \(deposited.formatted(.number)) toward a savings goal of
        \(currency) \(target.formatted(.number)). The piggy bank is \(Int((deposited/target)*100))% full.
        Suggest how to reach the goal faster.
        """
        return await generateInsight(context: context)
    }

    /// Analyze spending patterns with Foundation Models.
    func analyzeSpendingPatterns(transactions: [String]) async -> String {
        let context = """
        Analyze these spending transactions for patterns, waste, and savings opportunities:
        \(transactions.joined(separator: "\n"))
        """
        return await generateInsight(context: context)
    }

    // MARK: - Fallback (deterministic)

    private func fallbackInsight(context: String) -> String {
        return "On-device AI unavailable. \(context) Keep saving consistently and review your budget weekly."
    }
}
