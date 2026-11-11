import SwiftUI

// MARK: - Profile Editor

/// Lets the user edit their profile: age, income, and additional financial factors.
struct ProfileEditView: View {
    @EnvironmentObject var storage: LocalStorage
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) var dismiss

    @State private var profile: UserProfile

    init() {
        // Seed from current storage; edits apply on save.
        _profile = State(initialValue: LocalStorage.shared.profile)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Details")) {
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", value: Binding(
                            get: { profile.age ?? 0 },
                            set: { profile.age = $0 == 0 ? nil : $0 }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Country")
                        Spacer()
                        TextField("Country (e.g. US)", text: Binding(
                            get: { profile.country ?? "" },
                            set: { profile.country = $0.isEmpty ? nil : $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Currency")
                        Spacer()
                        Picker("Currency", selection: $profile.currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                            Text("JPY").tag("JPY")
                            Text("INR").tag("INR")
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 260)
                        .multilineTextAlignment(.trailing)
                    }
                    Picker("Employment Status", selection: $profile.employmentStatus) {
                        ForEach(UserProfile.EmploymentStatus.allCases, id: \.self) { status in
                            Text(status.localized).tag(status)
                        }
                    }
                }

                Section(header: Text("Income & Savings")) {
                    HStack {
                        Text("Monthly Income")
                        Spacer()
                        TextField("Income", value: $profile.monthlyIncome, format: .currency(code: profile.currency))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Existing Savings")
                        Spacer()
                        TextField("Savings", value: $profile.existingSavings, format: .currency(code: profile.currency))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Target Savings %")
                        Spacer()
                        TextField("Target %", value: $profile.savingsTargetPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("% of income").font(.caption2).foregroundColor(.secondary)
                    }
                }

                Section(header: Text("More Factors")) {
                    Picker("Risk Tolerance", selection: $profile.riskTolerance) {
                        Text("Conservative").tag("conservative")
                        Text("Moderate").tag("moderate")
                        Text("Aggressive").tag("aggressive")
                    }
                    Picker("Investment Experience", selection: $profile.investmentExperience) {
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                    }
                    HStack {
                        Text("Dependents")
                        Spacer()
                        TextField("Dependents", value: $profile.dependents, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Marital Status")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { profile.maritalStatus ?? "single" },
                            set: { profile.maritalStatus = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Single").tag("single")
                            Text("Partnered").tag("partnered")
                            Text("Married").tag("married")
                            Text("Divorced").tag("divorced")
                            Text("Widowed").tag("widowed")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200, alignment: .trailing)
                    }
                    HStack {
                        Text("Housing Status")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { profile.housingStatus ?? "rent" },
                            set: { profile.housingStatus = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Rent").tag("rent")
                            Text("Own").tag("own")
                            Text("With Family").tag("with-family")
                            Text("Other").tag("other")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200, alignment: .trailing)
                    }
                    HStack {
                        Text("Debt Comfort")
                        Spacer()
                        Picker("", selection: $profile.debtComfortLevel) {
                            Text("Low").tag("low")
                            Text("Medium").tag("medium")
                            Text("High").tag("high")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200, alignment: .trailing)
                    }
                }

                Section {
                    Button("Save Profile") {
                        storage.profile = profile
                        storage.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
