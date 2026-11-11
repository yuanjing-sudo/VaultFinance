import SwiftUI

struct LearnView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var selectedLesson: Lesson?

    var completedLessons: Int {
        storage.lessons.filter { !$0.locked }.count
    }

    var totalXP: Int {
        storage.lessons.reduce(0) { $0 + $1.xp }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Learning Dashboard
                learningDashboard

                // Learning Pathways
                learningPathways

                // Quizzes
                quizSection

                // Achievements
                achievementsSection
            }
            .padding()
        }
        .navigationTitle("Learn")
    }

    private var learningDashboard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress").bold().font(.headline)
                Spacer()
            }
            HStack(spacing: 20) {
                ProgressCard(title: "Lessons", value: "\(completedLessons)/\(storage.lessons.count)", icon: "book.fill")
                ProgressCard(title: "XP", value: "\(totalXP)", icon: "star.fill")
                ProgressCard(title: "Streak", value: "3 days", icon: "flame.fill")
            }
        }
    }

    private var learningPathways: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Pathway").font(.headline)
            ForEach(Lesson.LessonDifficulty.allCases, id: \.self) { level in
                LevelSection(level: level, lessons: storage.lessons.filter { $0.difficulty == level })
            }
        }
    }

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Quiz").bold().font(.headline)
                Spacer()
            }
            QuizCard()
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements").bold().font(.headline)
                Spacer()
            }
            ForEach(storage.achievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
}

// MARK: - Subcomponents

struct ProgressCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(.blue)
            Text(value).font(.title).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
    }
}

struct LevelSection: View {
    let level: Lesson.LessonDifficulty
    let lessons: [Lesson]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(level.rawValue).bold().font(.subheadline)
            ForEach(lessons) { lesson in
                LessonRowView(lesson: lesson)
                    .onTapGesture {
                        // Open lesson
                    }
            }
        }
    }
}

struct LessonRowView: View {
    let lesson: Lesson

    var body: some View {
        HStack {
            Image(systemName: lesson.locked ? "lock.fill" : "checkmark.circle.fill")
                .foregroundColor(lesson.locked ? .gray : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title).font(.subheadline)
                Text(lesson.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(lesson.xp) XP").font(.caption).bold().foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct QuizCard: View {
    @State private var showQuiz = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test your knowledge!").font(.subheadline)
            Button("Start Quiz") {
                showQuiz = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $showQuiz) {
                QuizSession()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.unlocked ? .amber : .gray)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title).font(.subheadline).bold()
                    Spacer()
                    if achievement.unlocked {
                        Text("Unlocked \(achievement.unlockedAt, style: .relative) ago").font(.caption).foregroundColor(.secondary)
                    } else {
                        Text("Locked").font(.caption).foregroundColor(.secondary)
                    }
                }
                Text(achievement.description).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
