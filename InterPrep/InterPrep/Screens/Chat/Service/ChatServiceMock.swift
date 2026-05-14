import DiscoveryModule
import Foundation

#if DEBUG

public final actor ChatServiceMock: ChatServicing {
    public init() {}

    public func fetchMessages() async throws -> [ChatMessage] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            ChatMessage(
                text: "Здравствуйте! Я карьерный консультант, чем могу помочь?",
                sender: .consultant,
                timestamp: Date(),
                status: .read,
                buttons: [
                    MessageButton(text: "Подготовка к собеседованию", action: .selectScenario(.interviewPrep)),
                    MessageButton(text: "Консультация по резюме", action: .selectScenario(.resumeConsultation)),
                    MessageButton(text: "Другое", action: .selectScenario(.other))
                ]
            )
        ]
    }

    public func fetchConsultant() async throws -> Consultant {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Consultant(
            name: "Анна Петрова",
            title: "Карьерный консультант",
            isOnline: true
        )
    }

    public func connect() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    public func disconnect() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    public func sendMessage(_ message: ChatMessage) async throws -> ChatMessage? {
        try await Task.sleep(nanoseconds: 600_000_000)
        return ChatMessage(
            // swiftlint:disable:next line_length
            text: "Принял. По вашему запросу могу подсказать: подготовьте краткий рассказ о себе, примеры проектов и типичные вопросы по вашей области. Если нужна помощь с конкретным вопросом — напишите его.",
            sender: .consultant
        )
    }

    public func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage {
        try await Task.sleep(nanoseconds: 800_000_000)

        switch action {
        case .selectScenario(let scenario):
            switch scenario {
            case .interviewPrep:
                return ChatMessage(text: "Выберите вакансию из избранного для подготовки к собеседованию.", sender: .consultant)
            case .resumeConsultation:
                return ChatMessage(text: "Анализирую ваше резюме...", sender: .consultant)
            case .other:
                return ChatMessage(text: "Чем могу помочь?", sender: .consultant)
            }
        case .confirmYes:
            return ChatMessage(text: "Отлично! Анализирую ваше резюме...", sender: .consultant)
        case .confirmNo:
            return ChatMessage(text: "Хорошо! Задавайте любые вопросы по карьере.", sender: .consultant)
        case .selectInterviewType(let type):
            let text: String
            switch type {
            case "technical": text = "Давайте начнем подготовку к техническому интервью. На какую позицию вы готовитесь?"
            case "behavioral": text = "Поведенческие интервью — важная часть. Расскажите о компании и позиции."
            default: text = "Давайте начнем подготовку!"
            }
            return ChatMessage(text: text, sender: .consultant)
        case .requestVacancyId, .reviewResumeNow:
            return ChatMessage(text: "Обрабатываю запрос...", sender: .consultant)
        }
    }

    public func clearHistory() async {}

    public func prepareForVacancy(vacancyId: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "Подготовка к вакансии \(vacancyId) — советы будут сгенерированы AI-консультантом."
    }

    public func reviewResume() async throws -> (score: Double, recommendations: String) {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return (score: 7.5, recommendations: "Резюме выглядит хорошо, но есть что улучшить.")
    }

    public func clearChatHistory(conversationId: String?) async throws -> (ok: Bool, deletedConversations: Int) {
        try await Task.sleep(nanoseconds: 200_000_000)
        return (ok: true, deletedConversations: conversationId != nil ? 1 : 5)
    }

    public func getCoachChatHistory(pageSize: Int, pageOffset: Int) async throws -> [ChatMessage] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            ChatMessage(
                text: "Как подготовиться к техническому интервью?",
                sender: .user,
                timestamp: Date().addingTimeInterval(-3600),
                status: .read
            ),
            ChatMessage(
                text: "Повторите алгоритмы, попрактикуйтесь на задачах и изучите систем-дизайн.",
                sender: .consultant,
                timestamp: Date().addingTimeInterval(-3500),
                status: .read
            )
        ]
    }

    public func addChatMessage(conversationId: String?, content: String, isUser: Bool) async throws -> String {
        try await Task.sleep(nanoseconds: 100_000_000)
        return "mock-conversation-id"
    }
}

#endif
