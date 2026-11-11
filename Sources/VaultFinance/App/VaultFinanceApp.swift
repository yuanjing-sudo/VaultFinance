import SwiftUI

enum FinanceKeyboardType {
    case numberPad
    case decimalPad
}

extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS) || os(tvOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

extension Text {
    func multilineTextAlignment(_ alignment: TextAlignment) -> Text { self }
}

extension TextField {
    func keyboardType(_ type: FinanceKeyboardType) -> some View { self }
    func multilineTextAlignment(_ alignment: TextAlignment) -> some View { self }
}

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
                    .environmentObject(AIService.shared)
            } else {
                OnboardingView()
                    .environmentObject(navigation)
                    .environmentObject(LocalStorage.shared)
                    .environmentObject(AIService.shared)
            }
        }
    }
}
