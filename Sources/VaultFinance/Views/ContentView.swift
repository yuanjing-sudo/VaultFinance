import SwiftUI

struct ContentView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        NavigationStack {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }

                BudgetView()
                    .tabItem { Label("Budget", systemImage: "list.bullet.rectangle") }

                WealthView()
                    .tabItem { Label("Wealth", systemImage: "chart.bar.fill") }

                LearnView()
                    .tabItem { Label("Learn", systemImage: "graduationcap.fill") }

                AIView()
                    .tabItem { Label("AI", systemImage: "sparkles.fill") }
            }
            .navigationTitle("Vault — Personal Finance Companion")
        }
    }
}
