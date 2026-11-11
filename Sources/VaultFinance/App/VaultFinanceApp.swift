import SwiftUI

@main
struct VaultFinanceApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(LocalStorage.shared)
                    .environmentObject(AIService())
            } else {
                OnboardingView()
                    .environmentObject(LocalStorage.shared)
            }
        }
    }
}
