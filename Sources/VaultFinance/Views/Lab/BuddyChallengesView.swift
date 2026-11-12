import SwiftUI

// MARK: - Buddy Challenges (local, no cloud)

struct BuddyChallengesView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingBuddy = false
    @State private var showingChallenge = false

    private var buddies: [AccountabilityBuddy] {
        storage.buddies.sorted { $0.weeklySaved > $1.weeklySaved }
    }

    private var active: [BuddyChallenge] {
        storage.buddyChallenges.filter { $0.isActive }
    }

    private var mySaved: Double {
        storage.buddies.first(where: { $0.isMe })?.weeklySaved ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                leaderboard
                challenges
                LabCallout(icon: "iphone.gen3", title: "Local-only accountability",
                           message: "Buddies and challenges are stored on this device. No account, CloudKit, or network is used — this is a playful way to stay accountable.",
                           tint: VaultTheme.blue)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Buddy Challenges")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingBuddy = true } label: {
                    Image(systemName: "person.badge.plus")
                }
                Button { showingChallenge = true } label: {
                    Image(systemName: "flag.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingBuddy) { AddBuddyView() }
        .sheet(isPresented: $showingChallenge) { NewBuddyChallengeView() }
    }

    private var hero: some View {
        LabHeroCard(
            eyebrow: "Accountability",
            title: active.isEmpty ? "Start a friendly challenge" : "\(active.count) challenge\(active.count == 1 ? "" : "s") in play",
            subtitle: "Saved \(WealthLabEngine.formatted(mySaved, currency: storage.profile.currency)) this week. A little rivalry goes a long way.",
            icon: "person.2.fill",
            gradient: VaultTheme.sunsetGradient
        )
    }

    private var leaderboard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 9) {
                VaultSectionHeader(title: "This week's leaderboard",
                                   subtitle: "Weekly saved · streaks")
                if buddies.isEmpty {
                    VaultEmptyState(icon: "person.2.fill", title: "No buddies yet",
                                    actionTitle: "Add buddy") { showingBuddy = true }
                } else {
                    ForEach(buddies.indices, id: \.self) { index in
                        let buddy = buddies[index]
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption2).bold()
                                .foregroundColor(index == 0 ? VaultTheme.gold : .secondary)
                                .frame(width: 18)
                            Text(buddy.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(buddy.name + (buddy.isMe ? " (you)" : ""))
                                    .font(.caption).bold()
                                Text("\(buddy.streak)-day streak")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(WealthLabEngine.formatted(buddy.weeklySaved, currency: storage.profile.currency))
                                .font(.subheadline).bold()
                                .foregroundColor(buddy.isMe ? VaultTheme.blue : .primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var challenges: some View {
        VStack(spacing: 10) {
            ForEach(active) { challenge in
                goalCard(challenge)
            }
            if active.isEmpty {
                VaultCard {
                    VaultEmptyState(icon: "flag.checkered", title: "No active challenge",
                                    message: "Challenge a buddy to a no-spend weekend or a savings sprint.",
                                    actionTitle: "Create challenge") { showingChallenge = true }
                }
            }
        }
    }

    private func goalCard(_ challenge: BuddyChallenge) -> some View {
        let meWinning = challenge.myProgress >= challenge.buddyProgress
        return VaultCard(tint: meWinning ? VaultTheme.green : VaultTheme.orange) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.title).font(.subheadline).bold()
                        Text("vs \(challenge.buddyName) · ends \(challenge.endsOn.formatted(.dateTime.month(.abbreviated).day()))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VaultPill(text: meWinning ? "You're ahead" : "Catch up",
                              icon: meWinning ? "crown.fill" : "figure.run",
                              color: meWinning ? VaultTheme.green : VaultTheme.orange)
                }
                progressLine(label: "You", progress: challenge.myProgress,
                             target: challenge.target, tint: VaultTheme.blue)
                progressLine(label: challenge.buddyName, progress: challenge.buddyProgress,
                             target: challenge.target, tint: VaultTheme.purple)
                HStack {
                    Text("Reward: \(challenge.reward)")
                        .font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Button("+$10") { addProgress(challenge, amount: 10) }
                        .font(.caption2).bold()
                        .disabled(challenge.myProgress >= challenge.target)
                    if challenge.myProgress >= challenge.target {
                        Text("Won 🎉").font(.caption2).bold().foregroundColor(VaultTheme.green)
                    }
                }
            }
        }
    }

    private func progressLine(label: String, progress: Double, target: Double, tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.caption2).frame(width: 54, alignment: .leading)
            VaultProgressBar(progress: target > 0 ? progress / target : 0, height: 7,
                             gradient: LinearGradient(colors: [tint.opacity(0.7), tint],
                                                      startPoint: .leading, endPoint: .trailing))
            Text("\(WealthLabEngine.formatted(progress, currency: storage.profile.currency))/\(WealthLabEngine.formatted(target, currency: storage.profile.currency))")
                .font(.caption2).foregroundColor(.secondary)
                .frame(width: 94, alignment: .trailing)
        }
    }

    private func addProgress(_ challenge: BuddyChallenge, amount: Double) {
        guard let index = storage.buddyChallenges.firstIndex(where: { $0.id == challenge.id }) else { return }
        storage.buddyChallenges[index].myProgress = min(storage.buddyChallenges[index].myProgress + amount,
                                                        storage.buddyChallenges[index].target)
        if let meIndex = storage.buddies.firstIndex(where: { $0.isMe }) {
            storage.buddies[meIndex].weeklySaved += amount
        }
        storage.save()
    }
}

// MARK: - Add buddy

struct AddBuddyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var name = ""
    @State private var emoji = "🐼"
    @State private var weeklySaved = "25"

    private let emojis = ["🐼", "🦊", "🐯", "🐸", "🐨", "🦁", "🐙", "🐵"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Emoji", selection: $emoji) {
                        ForEach(emojis, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Saved this week", text: $weeklySaved).keyboardType(.decimalPad)
                } header: { Text("Buddy") }
                Section {
                    Button("Add buddy") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        storage.buddies.append(AccountabilityBuddy(name: trimmed, emoji: emoji,
                                                                   weeklySaved: Double(weeklySaved) ?? 0))
                        storage.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Buddy")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - New buddy challenge

struct NewBuddyChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: LocalStorage

    @State private var title = ""
    @State private var buddyName = ""
    @State private var target = "100"
    @State private var reward = "Bragging rights"

    private var buddies: [AccountabilityBuddy] {
        storage.buddies.filter { !$0.isMe }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Challenge name", text: $title)
                    Picker("Buddy", selection: $buddyName) {
                        Text("Choose a buddy").tag("")
                        ForEach(buddies) { buddy in
                            Text("\(buddy.emoji) \(buddy.name)").tag(buddy.name)
                        }
                    }
                    TextField("Target amount", text: $target).keyboardType(.decimalPad)
                    TextField("Reward", text: $reward)
                } header: { Text("Challenge") }
                Section {
                    Button("Start challenge") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
                              !buddyName.isEmpty else { return }
                        storage.buddyChallenges.append(
                            BuddyChallenge(title: title, buddyName: buddyName,
                                           target: Double(target) ?? 100, reward: reward)
                        )
                        storage.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Challenge")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if buddyName.isEmpty { buddyName = buddies.first?.name ?? "" }
            }
        }
    }
}
