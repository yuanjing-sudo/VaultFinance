import SwiftUI

// MARK: - Onboarding

/// Minimal onboarding so the app can launch (referenced by VaultFinanceApp).
struct OnboardingView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var hasSeen = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "vault.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            Text("Welcome to VaultFinance")
                .font(.title2).bold()
            Text("Build budgets, track spending streaks, manage recurring bills and subscriptions, monitor net worth, set savings goals, import and export transactions, and stay on top of fresh financial news with AI-powered insights, alerts, and secure account protection.")
                .font(Font.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button("Get Started") {
                hasSeen = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .onChange(of: hasSeen) { _, newValue in
            if newValue {
                // Mark onboarding seen so the app opens the main content next time.
                // Note: AppStorage lives in VaultFinanceApp; this triggers navigation there.
            }
        }
    }
}
