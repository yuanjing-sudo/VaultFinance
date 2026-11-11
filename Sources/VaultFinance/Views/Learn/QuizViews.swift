import SwiftUI

struct QuizSession: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedOption: Int?
    @State private var score = 0
    @State private var showResult = false
    @State private var feedback = ""

    let questions = [
        QuizQuestion(
            id: UUID(),
            question: "What does the 50/30/20 rule allocate?",
            options: ["Needs/Wants/Savings", "Taxes/Food/Rent", "Cash/Stocks/Bonds", "Income/Expenses/Debt"],
            correctIndex: 0,
            explanation: "The 50/30/20 rule allocates 50% to needs, 30% to wants, and 20% to savings/debt repayment."
        ),
        QuizQuestion(
            id: UUID(),
            question: "Which is a fixed need?",
            options: ["Groceries", "Restaurant", "Rent", "Entertainment"],
            correctIndex: 2,
            explanation: "Rent is a fixed need — you pay it regularly and it's essential for housing."
        ),
        QuizQuestion(
            id: UUID(),
            question: "What is compound interest?",
            options: [
                "Interest on interest",
                "Interest only on principal",
                "Monthly bank fees",
                "Investment tax"
            ],
            correctIndex: 0,
            explanation: "Compound interest means you earn returns on your original investment plus previously earned interest."
        )
    ]

    var currentQuestion: QuizQuestion { questions[currentQuestionIndex] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if showResult {
                    resultView
                } else {
                    progressHeader
                    questionText
                    optionsList
                    feedbackView
                }
            }
            .padding()
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var progressHeader: some View {
        HStack {
            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
            Spacer()
            Text("Score: \(score)")
        }
        .font(.subheadline)
    }

    private var questionText: some View {
        Text(currentQuestion.question)
            .font(.headline)
    }

    private var optionsList: some View {
        VStack(spacing: 12) {
            ForEach(Array(questions[currentQuestionIndex].options.enumerated()), id: \.offset) { index, option in
                Button(action: { selectOption(index) }) {
                    HStack {
                        Text(option)
                        Spacer()
                        if selectedOption == index {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding()
                    .background(selectedOption == index ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedOption == index ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var feedbackView: some View {
        Group {
            if !feedback.isEmpty {
                VStack(spacing: 8) {
                    Text(feedback).font(.subheadline)
                        .foregroundColor(selectedOption == currentQuestion.correctIndex ? .green : .red)
                    if selectedOption == currentQuestion.correctIndex {
                        Button("Next Question") {
                            nextQuestion()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Continue") {
                            nextQuestion()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: score >= 2 ? "trophy.fill" : "star.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Quiz Complete!")
                .font(.title)
                .bold()
            Text("You scored \(score) out of \(questions.count)")
                .font(.subheadline)
            Button("Back to Learn") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    func selectOption(_ index: Int) {
        selectedOption = index
        if index == currentQuestion.correctIndex {
            score += 1
            feedback = "Correct! \(currentQuestion.explanation)"
        } else {
            feedback = "Not quite. \(currentQuestion.explanation)"
        }
    }

    func nextQuestion() {
        feedback = ""
        selectedOption = nil
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
        } else {
            showResult = true
        }
    }
}
