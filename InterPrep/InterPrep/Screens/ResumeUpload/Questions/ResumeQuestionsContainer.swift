import CacheService
import DesignSystem
import NetworkService
import SwiftUI

public struct ResumeQuestionsContainer: View {
    private let sessionId: String
    private let initialQuestions: [ResumeQuestion]
    private let onComplete: () -> Void

    @State private var questions: [ResumeQuestion] = []
    @State private var answers: [String: String] = [:]
    @State private var currentQuestionIndex: Int = 0
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    public init(
        sessionId: String,
        initialQuestions: [ResumeQuestion],
        onComplete: @escaping () -> Void
    ) {
        self.sessionId = sessionId
        self.initialQuestions = initialQuestions
        self.onComplete = onComplete
    }

    public var body: some View {
        ResumeQuestionsView(
            model: .init(
                questions: questions,
                answers: answers,
                currentQuestionIndex: currentQuestionIndex,
                isSubmitting: isSubmitting,
                errorMessage: errorMessage,
                onAnswerChanged: { questionId, value in
                    answers[questionId] = value
                    errorMessage = nil
                },
                onNextQuestion: {
                    if currentQuestionIndex < questions.count - 1 {
                        currentQuestionIndex += 1
                    }
                },
                onPreviousQuestion: {
                    if currentQuestionIndex > 0 {
                        currentQuestionIndex -= 1
                    }
                },
                onSubmit: {
                    Task { await submitAnswers() }
                },
                onSkip: {
                    onComplete()
                }
            )
        )
        .task {
            if questions.isEmpty {
                questions = await enrichQuestionsWithAreasList(initialQuestions)
            }
        }
        .onChange(of: initialQuestions) { _, newValue in
            if questions.isEmpty {
                Task {
                    questions = await enrichQuestionsWithAreasList(newValue)
                }
            }
        }
    }

    private func submitAnswers() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil

        let coachAnswers = questions.compactMap { question -> Coach_QuestionAnswer? in
            guard let value = answers[question.id],
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            var qa = Coach_QuestionAnswer()
            qa.questionID = question.id
            qa.value = value
            return qa
        }

        let result = await NetworkServiceV2.shared.answerResume(
            sessionId: sessionId,
            answers: coachAnswers
        )

        isSubmitting = false

        switch result {
        case .success:
            onComplete()
        case .failure(let error):
            if let networkError = error as? NetworkError, let api = networkError.asAPIError {
                errorMessage = api.userMessage
            } else {
                errorMessage = "Не удалось отправить ответы. Попробуйте ещё раз."
            }
        }
    }

    private func enrichQuestionsWithAreasList(_ resumeQuestions: [ResumeQuestion]) async -> [ResumeQuestion] {
        let actualAreas = await AreasCache.shared.getAreas()

        return resumeQuestions.map { question in
            if question.id == "areas" && !actualAreas.isEmpty {
                return ResumeQuestion(
                    id: question.id,
                    text: question.text,
                    type: question.type,
                    options: actualAreas
                )
            } else {
                return question
            }
        }
    }
}

#Preview {
    ResumeQuestionsContainer(
        sessionId: "preview-session-id",
        initialQuestions: [
            ResumeQuestion(
                id: "areas",
                text: "Выберите регион поиска работы",
                type: "single_choice",
                options: [
                    "Москва", "Санкт-Петербург", "Казань",
                    "Новосибирск", "Екатеринбург", "Нижний Новгород",
                    "Самара", "Краснодар", "Ростов-на-Дону", "Россия"
                ]
            ),
            ResumeQuestion(
                id: "work_format",
                text: "Выберите предпочитаемый формат работы",
                type: "single_choice",
                options: ["Удаленно", "Гибрид", "Офис"]
            ),
            ResumeQuestion(
                id: "salary_min",
                text: "Укажите ожидаемую зарплату в рублях",
                type: "numeric_input",
                options: ["50000", "100000", "150000", "200000"]
            )
        ],
        onComplete: {}
    )
}
