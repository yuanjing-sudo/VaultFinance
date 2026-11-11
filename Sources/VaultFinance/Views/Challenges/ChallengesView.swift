import Foundation
import SwiftUI

// MARK: - Savings Challenges
// Gamified challenges: 52-week, no-spend weekends, round-ups and custom goals.
// Progress is visual, animated, and easy to contribute to.

struct ChallengesView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingCreate = false
    @State private var contributingTo: SavingsChallenge?

    private var active: [SavingsChallenge] { storage.challenges.filter { !$0.isComplete } }
    private var completed: [SavingsChallenge] { storage.challenges.filter { $0.isComplete } }

    private var totalSaved: Double {
        storage.challenges.reduce(0) { $0 + $1.savedAmount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if active.isEmpty && completed.isEmpty {
                    VaultEmptyState(icon: "flag.checkered", title: "No challenges yet",
                                    message: "Pick a template below to start saving with momentum.",
                                    actionTitle: "Start a Challenge") { showingCreate = true }
                }
                if !active.isEmpty {
                    sectionTitle("Active")
                    ForEach(active) { challenge in
                        ChallengeCard(challenge: challenge) {
                            contributingTo = challenge
                        } onDelete: {
                            storage.challenges.removeAll { $0.id == challenge.id }
                            storage.save()
                        }
                    }
                }
                presetSection
                if !completed.isEmpty {
                    sectionTitle("Completed 🎉")
                    ForEach(completed) { challenge in
                        CompletedChallengeRow(challenge: challenge)
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Challenges")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateChallengeSheet { challenge in
                storage.challenges.append(challenge)
                storage.save()
            }
        }
        .sheet(item: $contributingTo) { challenge in
            ContributeChallengeSheet(challenge: challenge) { amount in
                guard let index = storage.challenges.firstIndex(where: { $0.id == challenge.id }) else { return }
                storage.challenges[index].savedAmount += amount
                storage.challenges[index].daysCompleted += 1
                storage.save()
                if storage.challenges[index].isComplete {
                    NotificationCenter.default.post(name: .vaultChallengeCompleted, object: nil)
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text).font(.headline).bold()
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Header

    private var headerCard: some View {
        VaultGradientCard(gradient: VaultTheme.sunsetGradient) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total challenge savings").font(.caption).opacity(0.9)
                    Text(Money(amount: totalSaved, currency: storage.profile.currency).formatted())
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("\(active.count) active · \(completed.count) completed")
                        .font(.caption2).opacity(0.85)
                }
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.18)).frame(width: 64, height: 64)
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 28)).foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Presets

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Popular Templates")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChallengeTemplate.all) { template in
                        Button {
                            storage.challenges.append(template.makeChallenge())
                            storage.save()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: template.icon)
                                    .font(.title3)
                                    .foregroundColor(VaultTheme.tint(for: template.color))
                                Text(template.title).font(.caption).bold()
                                    .foregroundColor(.primary)
                                Text(template.subtitle)
                                    .font(.caption2).foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .frame(width: 150, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(VaultTheme.tint(for: template.color).opacity(0.10))
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Template

struct ChallengeTemplate: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var color: String
    var type: SavingsChallenge.ChallengeType
    var target: Double

    static let all: [ChallengeTemplate] = [
        .init(title: "52-Week", subtitle: "Save $1 more each week", icon: "calendar.badge.clock",
              color: "blue", type: .fiftyTwoWeek, target: 1378),
        .init(title: "No-Spend Weekend", subtitle: "Zero discretionary spend", icon: "hand.raised.fill",
              color: "purple", type: .noSpend, target: 100),
        .init(title: "Round-Up Jar", subtitle: "Round every purchase up", icon: "arrow.up.circle.fill",
              color: "green", type: .roundUp, target: 500),
        .init(title: "Weekly Saver", subtitle: "Put aside a little weekly", icon: "7.circle.fill",
              color: "orange", type: .weekly, target: 520),
        .init(title: "Custom Goal", subtitle: "Make your own rules", icon: "slider.horizontal.3",
              color: "teal", type: .custom, target: 1000)
    ]

    func makeChallenge() -> SavingsChallenge {
        SavingsChallenge(title: title, description: subtitle,
                         targetAmount: target, type: type,
                         endDate: Date().addingTimeInterval(86400 * 52))
    }
}

// MARK: - Card

struct ChallengeCard: View {
    let challenge: SavingsChallenge
    var onContribute: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle().fill(VaultTheme.blue.opacity(0.12)).frame(width: 38, height: 38)
                        Image(systemName: icon)
                            .font(.caption).foregroundColor(VaultTheme.blue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.title).font(.subheadline).bold()
                        Text(challenge.type.localized).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VaultPill(text: "\(Int(challenge.progress * 100))%", color: VaultTheme.green)
                }
                VaultProgressBar(progress: challenge.progress,
                                 gradient: VaultTheme.savingsGradient)
                HStack {
                    Text(Money(amount: challenge.savedAmount).formatted())
                        .font(.caption).bold()
                    Text("of \(Money(amount: challenge.targetAmount).formatted())")
                        .font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("\(Money(amount: challenge.remaining).formatted()) to go")
                        .font(.caption2).foregroundColor(.secondary)
                }
                HStack(spacing: 10) {
                    Button {
                        onContribute()
                    } label: {
                        Label("Add Savings", systemImage: "plus")
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(VaultTheme.green.opacity(0.14)))
                            .foregroundColor(VaultTheme.green)
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash").font(.caption)
                            .padding(.vertical, 8).padding(.horizontal, 12)
                            .background(Capsule().fill(VaultTheme.red.opacity(0.10)))
                            .foregroundColor(VaultTheme.red)
                    }
                }
            }
        }
    }

    private var icon: String {
        switch challenge.type {
        case .fiftyTwoWeek: return "calendar"
        case .noSpend: return "hand.raised.fill"
        case .roundUp: return "arrow.up.circle.fill"
        case .weekly: return "7.circle.fill"
        case .custom: return "star.fill"
        }
    }
}

// MARK: - Completed Row

struct CompletedChallengeRow: View {
    let challenge: SavingsChallenge
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(VaultTheme.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title).font(.subheadline).bold()
                Text("Saved \(Money(amount: challenge.savedAmount).formatted())")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text("Done").font(.caption).bold().foregroundColor(VaultTheme.green)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
    }
}

// MARK: - Create Sheet

struct CreateChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (SavingsChallenge) -> Void

    @State private var title = ""
    @State private var target = ""
    @State private var type: SavingsChallenge.ChallengeType = .custom
    @State private var hasEndDate = true
    @State private var endDate = Date().addingTimeInterval(86400 * 30)

    var body: some View {
        NavigationStack {
            Form {
                Section("Challenge") {
                    TextField("Name", text: $title)
                    TextField("Target amount", text: $target)
                        .keyboardType(.decimalPad)
                    Picker("Type", selection: $type) {
                        ForEach(SavingsChallenge.ChallengeType.allCases, id: \.self) {
                            Text($0.localized).tag($0)
                        }
                    }
                }
                Section("Timeline") {
                    Toggle("Set end date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Ends", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Challenge")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onSave(SavingsChallenge(
                            title: title.isEmpty ? "Custom Challenge" : title,
                            targetAmount: Double(target) ?? 1000,
                            type: type,
                            endDate: endDate
                        ))
                        dismiss()
                    }
                    .bold()
                    .disabled(target.isEmpty)
                }
            }
        }
    }
}

// MARK: - Contribute Sheet

struct ContributeChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let challenge: SavingsChallenge
    var onSave: (Double) -> Void

    @State private var amount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Contribute") {
                    Text(challenge.title).font(.headline)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Text("Remaining: \(Money(amount: challenge.remaining).formatted())")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Savings")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(Double(amount) ?? 0)
                        dismiss()
                    }
                    .bold()
                    .disabled(Double(amount) == nil)
                }
            }
        }
    }
}

extension Notification.Name {
    static let vaultChallengeCompleted = Notification.Name("vaultChallengeCompleted")
}
