import SwiftUI

// MARK: - Achievements
// Gamified milestones with unlock status and progress.

struct AchievementsView: View {
    @EnvironmentObject var storage: LocalStorage

    private var unlocked: Int { storage.achievements.filter { $0.unlocked }.count }
    private var totalXP: Int {
        storage.achievements.filter { $0.unlocked }.reduce(0) { $0 + 50 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: VaultTheme.goldGradient) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Achievements").font(.caption).opacity(0.9)
                            Text("\(unlocked) of \(storage.achievements.count)")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                            Text("\(totalXP) XP earned").font(.caption2).opacity(0.9)
                        }
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(storage.achievements) { achievement in
                        AchievementBadgeCard(achievement: achievement)
                    }
                }

                if storage.achievements.isEmpty {
                    VaultEmptyState(icon: "trophy", title: "No achievements yet",
                                    message: "Keep budgeting and saving to unlock badges.")
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Achievements")
        .inlineNavigationTitle()
    }
}

struct AchievementBadgeCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.unlocked
                          ? VaultTheme.gold.opacity(0.18)
                          : Color.gray.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.unlocked ? VaultTheme.gold : .secondary)
            }
            Text(achievement.title)
                .font(.caption).bold()
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(achievement.description)
                .font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            VaultPill(text: achievement.unlocked ? "Unlocked" : "Locked",
                      icon: achievement.unlocked ? "checkmark.seal.fill" : "lock.fill",
                      color: achievement.unlocked ? VaultTheme.green : .gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.07)))
        .opacity(achievement.unlocked ? 1 : 0.75)
    }
}
