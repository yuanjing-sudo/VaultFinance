import SwiftUI

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter

    var body: some View {
        List {
            Section(header: Text("Account")) {
                Button("Edit Profile") {
                    router.push(.profileEdit)
                }
            }
            Section(header: Text("Data")) {
                Button("Refresh Demo Data") {
                    storage.refresh()
                    storage.save()
                }
                Button("Export Overview") {
                    // Placeholder for export functionality
                }
            }
            Section(header: Text("About")) {
                Text("VaultFinance — Personal Finance Companion")
                Text("Build budgets, track spending streaks, manage wealth, and read fresh financial news.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
