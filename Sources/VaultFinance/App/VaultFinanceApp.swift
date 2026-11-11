import SwiftUI

@main
struct VaultFinanceApp: App {
    @StateObject var navigation = NavigationModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(navigation)
                    .environmentObject(LocalStorage.shared)
            } else {
                OnboardingView()
                    .environmentObject(navigation)
                    .environmentObject(LocalStorage.shared)
            }
        }
    }
}
