import SwiftUI

// MARK: - Personalized Plan

struct PersonalizedPlanView: View {
    @EnvironmentObject var storage: LocalStorage

    @State private var income = ""
    @State private var dependents = 0
    @State private var risk = "moderate"
    @State private var savingsTarget = 20.0
    @State private var plan: PersonalizedPlan?
    @State private var savedMessage = ""

    private let risks = ["conservative", "moderate", "aggressive"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabHeroCard(
                    eyebrow: "Personalized Plan",
                    title: plan == nil ? "Two minutes to a clearer plan" : "Your \(plan?.riskProfile ?? "Balanced") plan",
                    subtitle: "Turn your income, dependents and risk comfort into a concrete monthly blueprint.",
                    icon: "map.fill",
                    gradient: VaultTheme.brandGradient
                )

                quizCard

                if let plan {
                    planCard(plan)
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("My Plan")
        .inlineNavigationTitle()
        .onAppear {
            if income.isEmpty { income = String(Int(storage.profile.monthlyIncome)) }
            dependents = storage.profile.dependents
            risk = risks.contains(storage.profile.riskTolerance) ? storage.profile.riskTolerance : "moderate"
            savingsTarget = storage.profile.savingsTargetPercent
            if plan == nil { plan = storage.personalizedPlan }
        }
    }

    private var quizCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Quick check-in", subtitle: "Adjust anything that has changed")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly take-home income").font(.caption).bold()
                    TextField("Income", text: $income)
                        .keyboardType(.decimalPad)
                        .padding(9)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(9)
                }
                Stepper("Dependents: \(dependents)", value: $dependents, in: 0...10)
                    .font(.caption).bold()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Savings target").font(.caption).bold()
                        Spacer()
                        Text("\(Int(savingsTarget))% of income").font(.caption).bold().foregroundColor(VaultTheme.green)
                    }
                    Slider(value: $savingsTarget, in: 5...50, step: 1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Risk comfort").font(.caption).bold()
                    Picker("Risk", selection: $risk) {
                        ForEach(risks, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                VaultPrimaryButton(title: "Build my plan", icon: "wand.and.stars") {
                    build()
                }
            }
        }
    }

    private func planCard(_ plan: PersonalizedPlan) -> some View {
        VStack(spacing: 12) {
            VaultCard(tint: VaultTheme.green) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VaultPill(text: plan.riskProfile, icon: "figure.walk", color: VaultTheme.green, filled: true)
                        Spacer()
                        Text("Emergency target").font(.caption2).foregroundColor(.secondary)
                    }
                    Text(WealthLabEngine.formatted(plan.recommendedEmergencyFund, currency: storage.profile.currency))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Text("A fully funded cushion is your first big win. Then automate savings and investing.")
                        .font(.caption2).foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        LabStat(label: "Savings", value: "\(Int(plan.recommendedSavingsRate))%",
                                icon: "banknote.fill", tint: VaultTheme.blue)
                        LabStat(label: "Investing", value: "\(Int(plan.recommendedInvestingPercent))%",
                                icon: "chart.line.uptrend.xyaxis", tint: VaultTheme.green)
                    }
                }
            }

            VaultCard {
                VStack(alignment: .leading, spacing: 10) {
                    VaultSectionHeader(title: "Suggested monthly split",
                                       subtitle: "A starting point, not a straitjacket")
                    ForEach(plan.suggestedBudget) { category in
                        LabProgressRow(title: category.name,
                                       detail: "\(Int(category.percent))% · \(WealthLabEngine.formatted(category.amount, currency: storage.profile.currency))",
                                       progress: category.percent / 100,
                                       tint: VaultTheme.tint(for: category.type.color),
                                       trailing: "\(Int(category.percent))%")
                    }
                }
            }

            VaultCard(tint: VaultTheme.purple) {
                VStack(alignment: .leading, spacing: 9) {
                    VaultSectionHeader(title: "Your next steps")
                    ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption2).bold()
                                .frame(width: 20, height: 20)
                                .background(VaultTheme.purple.opacity(0.15))
                                .foregroundColor(VaultTheme.purple)
                                .clipShape(Circle())
                            Text(step).font(.caption2).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }

            VStack(spacing: 9) {
                VaultPrimaryButton(title: "Save this plan", icon: "checkmark.seal.fill",
                                   gradient: VaultTheme.savingsGradient) {
                    storage.personalizedPlan = plan
                    storage.save()
                    savedMessage = "Plan saved. Money Lab will show it as your current blueprint."
                }
                if !storage.goals.contains(where: { $0.title.lowercased().contains("emergency") }) {
                    VaultSecondaryButton(title: "Create emergency fund goal", icon: "shield.lefthalf.filled") {
                        storage.goals.append(
                            FinancialGoal(title: "Emergency Fund",
                                          targetAmount: plan.recommendedEmergencyFund,
                                          currentAmount: storage.profile.existingSavings,
                                          horizon: .lifelong,
                                          notes: "Created from personalized plan")
                        )
                        storage.save()
                        savedMessage = "Emergency fund goal created."
                    }
                }
                if !savedMessage.isEmpty {
                    Text(savedMessage).font(.caption2).bold().foregroundColor(VaultTheme.green)
                }
            }
        }
    }

    private func build() {
        var sampled = storage.profile
        sampled.monthlyIncome = Double(income) ?? storage.profile.monthlyIncome
        sampled.dependents = dependents
        sampled.riskTolerance = risk
        sampled.savingsTargetPercent = savingsTarget
        plan = WealthLabEngine.buildPlan(profile: sampled, categories: storage.categories,
                                         liabilities: storage.liabilities)
    }
}
