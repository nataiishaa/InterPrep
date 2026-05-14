import Foundation

extension ResumeQuestionsView {
    public struct Model {
        public let questions: [ResumeQuestion]
        public let answers: [String: String]
        public let currentQuestionIndex: Int
        public let isSubmitting: Bool
        public let errorMessage: String?
        public let onAnswerChanged: (String, String) -> Void
        public let onNextQuestion: () -> Void
        public let onPreviousQuestion: () -> Void
        public let onSubmit: () -> Void
        public let onSkip: () -> Void

        public init(
            questions: [ResumeQuestion],
            answers: [String: String],
            currentQuestionIndex: Int,
            isSubmitting: Bool,
            errorMessage: String?,
            onAnswerChanged: @escaping (String, String) -> Void,
            onNextQuestion: @escaping () -> Void,
            onPreviousQuestion: @escaping () -> Void,
            onSubmit: @escaping () -> Void,
            onSkip: @escaping () -> Void
        ) {
            self.questions = questions
            self.answers = answers
            self.currentQuestionIndex = currentQuestionIndex
            self.isSubmitting = isSubmitting
            self.errorMessage = errorMessage
            self.onAnswerChanged = onAnswerChanged
            self.onNextQuestion = onNextQuestion
            self.onPreviousQuestion = onPreviousQuestion
            self.onSubmit = onSubmit
            self.onSkip = onSkip
        }
    }
}

#if DEBUG
extension ResumeQuestionsView.Model {
    static var preview: Self {
        .init(
            questions: [
                ResumeQuestion(
                    id: "areas",
                    text: "Выберите регион поиска работы",
                    type: "single_choice",
                    options: [
                        "Москва",
                        "Санкт-Петербург",
                        "Казань",
                        "Новосибирск",
                        "Екатеринбург",
                        "Нижний Новгород",
                        "Самара",
                        "Краснодар",
                        "Ростов-на-Дону",
                        "Россия"
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
            answers: [:],
            currentQuestionIndex: 0,
            isSubmitting: false,
            errorMessage: nil,
            onAnswerChanged: { _, _ in },
            onNextQuestion: {},
            onPreviousQuestion: {},
            onSubmit: {},
            onSkip: {}
        )
    }
}
#endif
