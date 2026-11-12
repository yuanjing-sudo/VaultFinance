import SwiftUI

// MARK: - Weekly Quests & Streak Shields

struct WeeklyQuestsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var shieldMessage = ""
    @State private var showingShieldAlert = false
    @State private var challengeMessage = ""
    @State private var showingChallengeAlert = false

    private var quests: [WeeklyQuest] { storage.weeklyQuests }
    private var completed: Int { quests.filter { $0.isComplete }.count }
    private var xp: Int { quests.filter { $0.isComplete }.reduce(0) { $0 + $1.xp } }
    private var shields: Int { WealthLabEngine.availableShields(storage.streakShields) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                shieldsCard
                questList
                challengeTemplates
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Weekly Quests")
        .inlineNavigationTitle()
        .onAppear { storage.ensureWeeklyQuests() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("WEEKLY QUESTS").font(.caption2).bold().opacity(0.85)
                Spacer()
                Image(systemName: "star.fill").font(.title3)
            }
            Text("\(completed) of \(max(quests.count, 5)) complete")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
            Text("Earn XP, keep the streak alive, and make saving feel like a game.")
                .font(.caption).opacity(0.88)
            VaultProgressBar(progress: quests.isEmpty ? 0 : Double(completed) / Double(quests.count),
                             height: 8,
                             gradient: LinearGradient(colors: [.white.opacity(0.9), .white],
                                                      startPoint: .leading, endPoint: .trailing),
                             track: Color.white.opacity(0.25))
            HStack {
                Label("\(xp) XP earned", systemImage: "bolt.fill")
                Spacer()
                Label("\(storage.spendingStreak.currentStreak)-day streak", systemImage: "flame.fill")
            }
            .font(.caption2).opacity(0.9)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(VaultTheme.goldGradient)
        )
        .foregroundColor(.white)
    }

    private var shieldsCard: some View {
        VaultCard(tint: VaultTheme.orange) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(VaultTheme.orange.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title3).foregroundColor(VaultTheme.orange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(shields) streak shield\(shields == 1 ? "" : "s")").font(.subheadline).bold()
                    Text("A shield rescues yesterday's streak if life got in the way.")
                        .font(.caption2).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button("Use") {
                    if storage.useStreakShield() {
                        shieldMessage = "Shield used. Yesterday is covered and your streak is protected."
                    } else {
                        shieldMessage = "No shields available. Earn one by completing a 7-day streak or a weekly quest."
                    }
                    showingShieldAlert = true
                }
                .font(.caption).bold()
                .buttonStyle(.bordered)
                .disabled(shields == 0)
            }
        }
        .alert("Streak shield", isPresented: $showingShieldAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shieldMessage)
        }
    }

    private var questList: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 11) {
                VaultSectionHeader(title: "This week",
                                   subtitle: quests.first.map { "Week of \($0.weekStart.formatted(.dateTime.month(.abbreviated).day()))" } ?? "Generating…",
                                   actionTitle: "Refresh") {
                    storage.ensureWeeklyQuests(force: true)
                }
                if quests.isEmpty {
                    VaultEmptyState(icon: "star.circle", title: "No quests yet",
                                    message: "Tap refresh to build this week's quests.")
                } else {
                    ForEach(quests) { quest in
                        questRow(quest)
                        if quest.id != quests.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func questRow(_ quest: WeeklyQuest) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Image(systemName: quest.icon)
                    .foregroundColor(quest.isComplete ? VaultTheme.green : VaultTheme.gold)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(quest.title).font(.caption).bold()
                        .strikethrough(quest.isComplete)
                    Text(quest.detail).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Text("+\(quest.xp) XP")
                    .font(.caption2).bold().foregroundColor(VaultTheme.gold)
            }
            HStack(spacing: 8) {
                VaultProgressBar(progress: quest.fraction, height: 7,
                                 gradient: quest.isComplete ? VaultTheme.savingsGradient : VaultTheme.goldGradient)
                Text("\(Int(quest.progress))/\(Int(quest.target))")
                    .font(.caption2).foregroundColor(.secondary)
                if quest.isComplete {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(VaultTheme.green)
                } else {
                    Button("Complete") { complete(quest) }
                        .font(.caption2).bold()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var challengeTemplates: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "Start a challenge",
                                   subtitle: "Add a playful target to your challenges list")
                ForEach(WealthLabEngine.challengeTemplates) { template in
                    HStack(spacing: 10) {
                        Image(systemName: template.icon)
                            .foregroundColor(VaultTheme.tint(for: template.tint))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.title).font(.caption).bold()
                            Text(template.detail).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Start") { start(template) }
                            .font(.caption2).bold()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .alert("Challenge started", isPresented: $showingChallengeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(challengeMessage)
        }
    }

    private func complete(_ quest: WeeklyQuest) {
        guard let index = storage.weeklyQuests.firstIndex(where: { $0.id == quest.id }) else { return }
        storage.weeklyQuests[index].progress = storage.weeklyQuests[index].target
        storage.weeklyQuests[index].isComplete = true
        storage.save()
    }

    private func start(_ template: LabChallengeTemplate) {
        storage.challenges.append(
            SavingsChallenge(title: template.title, description: template.detail,
                             targetAmount: template.target, type: .custom,
                             endDate: Calendar.current.date(byAdding: .day, value: template.days, to: Date()) ?? Date())
        )
        storage.save()
        challengeMessage = "\(template.title) is now in your challenges list. You've got this."
        showingChallengeAlert = true
    }
}
