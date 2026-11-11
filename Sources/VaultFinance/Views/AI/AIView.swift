import SwiftUI

struct AIView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var storage: LocalStorage
    @StateObject private var chatViewModel = AIChatViewModel()
    @State private var selectedCapability: AICapability? = .budgeting

    var body: some View {
        VStack(spacing: 0) {
            capabilitySelector
            chatView
        }
        .navigationTitle("AI Finance Assistant")
    }

    private var capabilitySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AICapability.allCases, id: \.self) { capability in
                    CapabilityChip(capability: capability, isSelected: selectedCapability == capability) {
                        selectedCapability = capability
                        chatViewModel.setCapability(capability)
                    }
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.12))
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(chatViewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                }
                .onAppear {
                    proxy.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
                }
            }

            inputRow
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Ask about your finances...", text: $chatViewModel.input)
                .padding(10)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(20)
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
                    .padding(10)
            }
        }
        .padding()
    }

    func sendMessage() {
        guard !chatViewModel.input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        chatViewModel.send(input: chatViewModel.input)
    }
}

// MARK: - Chat ViewModel

@MainActor class AIChatViewModel: ObservableObject {
    @Published var storage: LocalStorage?
    @Published var messages: [AIMessage] = []
    @Published var input = ""
    @Published var selectedCapability: AICapability = .budgeting
    @Published var isLoading = false

    init() {
        welcomeMessage()
    }

    @MainActor
    func send(input: String) {
        let userMessage = AIMessage(role: .user, content: input)
        messages.append(userMessage)
        self.input = ""
        isLoading = true

        Task { @MainActor in
            let response = await processQuery(input, capability: selectedCapability)
            isLoading = false
            messages.append(AIMessage(role: .assistant, content: response))
        }
    }

    func setCapability(_ capability: AICapability) {
        selectedCapability = capability
    }

    private func welcomeMessage() {
        messages.append(AIMessage(role: .assistant, content: "Hi! I'm your AI finance assistant. I can help with budgeting, savings, spending analysis, goals, wealth, education, lifestyle tips, and market news. How can I help today?"))
    }

    @available(iOS 18.0, *)
    private func processQuery(_ query: String, capability: AICapability) async -> String {
        switch capability {
        case .budgeting:
            return await handleBudgeting(query)
        case .spending:
            return await handleSpending(query)
        case .savings:
            return await handleSavings(query)
        case .goals:
            return await handleGoals(query)
        case .wealth:
            return await handleWealth(query)
        case .education:
            return await handleEducation(query)
        case .lifestyle:
            return await handleLifestyle(query)
        case .news:
            return await handleNews(query)
        }
    }

    // MARK: - Capability handlers

    private func handleBudgeting(_ query: String) async -> String {
        guard let storage = storage else { return "Set up your budget to get personalized advice." }
        let fixedNeeds = FinanceEngine.computeAllocation(profile: storage.profile, fixedNeedsMonthly: 2000).needs * storage.profile.totalMonthlyIncome / 100
        return AIService.shared.recommendBudget(profile: storage.profile, fixedNeeds: fixedNeeds)
    }

    private func handleSpending(_ query: String) async -> String {
        guard let storage = storage else { return "No transactions recorded yet." }
        return AIService.shared.analyzeSpending(patterns: storage.transactions)
    }

    private func handleSavings(_ query: String) async -> String {
        guard let storage = storage, let goal = storage.goals.first else {
            return "You don't have any savings goals set up yet. Add one in the Goals section!"
        }
        return AIService.shared.evaluateGoal(goal: goal, monthlyContribution: 100)
    }

    private func handleGoals(_ query: String) async -> String {
        guard let storage = storage, let goal = storage.goals.first else {
            return "Set up a savings goal to track your progress!"
        }
        return AIService.shared.evaluateGoal(goal: goal, monthlyContribution: 100)
    }

    private func handleWealth(_ query: String) async -> String {
        guard let storage = storage else { return "Add assets and liabilities to see your net worth." }
        let netWorth = FinanceEngine.computeNetWorth(assets: storage.assets, liabilities: storage.liabilities, cashInBank: storage.profile.existingSavings, savingsAccounts: 0).netWorth
        return "Your current net worth is \(Money(amount: netWorth).formatted()). Tap Wealth to see the breakdown and projections!"
    }

    private func handleEducation(_ query: String) async -> String {
        let concept = extractConcept(query)
        return AIService.shared.explainConcept(concept: concept)
    }

    private func handleLifestyle(_ query: String) async -> String {
        guard let storage = storage else { return "Set up a budget to see lifestyle recommendations." }
        let remaining = storage.categories.reduce(0) { $0 + $1.remaining }
        return AIService.shared.recommendActivities(budgetRemaining: remaining)
    }

    private func handleNews(_ query: String) async -> String {
        let news = MarketDataService.shared.newsFeed
        var response = "Here are the latest financial news updates:\n\n"
        for (i, item) in news.enumerated() {
            response.append("\(i + 1). \(item.title) — \(item.source)\n")
        }
        return response
    }

    private func extractConcept(_ query: String) -> String {
        let concepts = ["etf", "stock", "bond", "compound interest", "inflation", "dividend", "index fund", "roth ira", "401k", "mutual fund"]
        for concept in concepts {
            if query.lowercased().contains(concept) {
                return concept
            }
        }
        return query
    }
}

// MARK: - Types

struct AIMessage: Identifiable, Hashable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role: Hashable {
        case user
        case assistant
    }
}

struct CapabilityChip: View {
    let capability: AICapability
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(capability.localizedDescription)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.08))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .frame(width: 24)
            }
            Text(message.content)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.role == .assistant ? Color.blue.opacity(0.1) : Color.blue)
                .cornerRadius(16)
                .foregroundColor(message.role == .assistant ? .primary : .white)
            if message.role == .user {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)
    }
}

// MARK: - Extension for AIService singleton

extension AIService {
    static let shared = AIService()
}
