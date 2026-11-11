import SwiftUI

// MARK: - Profile View (read-only summary with edit entry point)

struct ProfileView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 72, height: 72)
                        .overlay(Text("V").foregroundColor(.white).bold())
                    Spacer()
                    Button("Edit") {
                        router.push(.profileEdit)
                    }
                    .buttonStyle(.borderedProminent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Details").font(.headline).bold()
                    ProfileRow(label: "Age", value: storage.profile.age.map(String.init) ?? "Not set")
                    ProfileRow(label: "Country", value: storage.profile.country ?? "Not set")
                    ProfileRow(label: "Currency", value: storage.profile.currency)
                    ProfileRow(label: "Employment", value: storage.profile.employmentStatus.localized)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Income & Savings").font(.headline).bold()
                    ProfileRow(label: "Monthly Income", value: Money(amount: storage.profile.monthlyIncome).formatted())
                    ProfileRow(label: "Existing Savings", value: Money(amount: storage.profile.existingSavings).formatted())
                    ProfileRow(label: "Total Monthly Income", value: Money(amount: storage.profile.totalMonthlyIncome).formatted())
                    ProfileRow(label: "Target Savings %", value: String(format: "%.0f%%", storage.profile.savingsTargetPercent))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("More Factors").font(.headline).bold()
                    ProfileRow(label: "Risk Tolerance", value: storage.profile.riskTolerance)
                    ProfileRow(label: "Investment Experience", value: storage.profile.investmentExperience)
                    ProfileRow(label: "Dependents", value: "\(storage.profile.dependents)")
                    ProfileRow(label: "Marital Status", value: storage.profile.maritalStatus ?? "Not set")
                    ProfileRow(label: "Housing Status", value: storage.profile.housingStatus ?? "Not set")
                    ProfileRow(label: "Debt Comfort", value: storage.profile.debtComfortLevel)
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
        .inlineNavigationTitle()
    }
}

struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
        .padding(.vertical, 4)
    }
}
