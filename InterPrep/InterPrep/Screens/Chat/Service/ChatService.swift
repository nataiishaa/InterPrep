import ChatFeature
import Foundation
import NetworkMonitorService
import NetworkService

public final actor ChatService: ChatServicing {
    private let networkService: NetworkServiceV2
    private var conversationId: String?

    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }

    public func fetchMessages() async throws -> [ChatMessage] {
        let online = await MainActor.run { NetworkMonitor.shared.isConnected }
        guard online else {
            throw ChatServiceError(
                message: "Нет интернета. Проверьте подключение и попробуйте снова",
                isConnectionFailure: true
            )
        }

        let welcomeMessage = ChatMessage(
            text: "Здравствуйте! Я карьерный консультант. Задайте вопрос по карьере, подготовке к собеседованию или резюме.",
            sender: .consultant,
            timestamp: Date().addingTimeInterval(-86400),
            status: .read,
            buttons: [
                MessageButton(text: "Подготовка к собеседованию", action: .selectScenario(.interviewPrep)),
                MessageButton(text: "Консультация по резюме", action: .selectScenario(.resumeConsultation)),
                MessageButton(text: "Другое", action: .selectScenario(.other))
            ]
        )

        let loaded = try await getCoachChatHistory(pageSize: 50, pageOffset: 0)
        let historyMessages = loaded
        return [welcomeMessage] + historyMessages.reversed()
    }

    public func fetchConsultant() async throws -> Consultant {
        Consultant(
            name: "Карьерный консультант",
            title: "AI-ассистент",
            isOnline: true
        )
    }

    public func connect() async throws {
    }

    public func disconnect() async {}

    public func clearHistory() async {
        conversationId = nil
    }

    public func sendMessage(_ message: ChatMessage) async throws -> ChatMessage? {
        let result = await networkService.ask(
            conversationId: conversationId,
            question: message.text
        )
        switch result {
        case .success(let response):
            if !response.conversationID.isEmpty {
                conversationId = response.conversationID
            }
            _ = try? await addChatMessage(conversationId: conversationId, content: message.text, isUser: true)
            _ = try? await addChatMessage(conversationId: conversationId, content: response.answer, isUser: false)
            return ChatMessage(
                text: response.answer,
                sender: .consultant,
                timestamp: Date(),
                status: .sent
            )
        case .failure(let error):
            throw await userFacingError(for: error)
        }
    }

    public func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage {
        let userQuestion = questionForButtonAction(action)
        _ = try? await addChatMessage(conversationId: conversationId, content: userQuestion, isUser: true)

        switch action {
        case .selectScenario(.interviewPrep):
            let reply = "Отлично! Для подготовки к собеседованию выберите вакансию из избранного.\n\nЕсли нужной вакансии нет — добавьте её в избранное на вкладке «Вакансии» и вернитесь сюда."
            _ = try? await addChatMessage(conversationId: conversationId, content: reply, isUser: false)
            return ChatMessage(text: reply, sender: .consultant, timestamp: Date(), status: .sent)

        case .selectScenario(.resumeConsultation):
            return ChatMessage(text: "Анализирую ваше резюме...", sender: .consultant, timestamp: Date(), status: .sent)

        case .selectScenario(.other):
            let reply = "Чем могу помочь?"
            _ = try? await addChatMessage(conversationId: conversationId, content: reply, isUser: false)
            return ChatMessage(text: reply, sender: .consultant, timestamp: Date(), status: .sent)

        default:
            let result = await networkService.ask(
                conversationId: conversationId,
                question: userQuestion
            )
            switch result {
            case .success(let response):
                if !response.conversationID.isEmpty {
                    conversationId = response.conversationID
                }
                _ = try? await addChatMessage(conversationId: conversationId, content: response.answer, isUser: false)
                return ChatMessage(
                    text: response.answer,
                    sender: .consultant,
                    timestamp: Date(),
                    status: .sent
                )
            case .failure(let error):
                throw await userFacingError(for: error)
            }
        }
    }

    @MainActor
    private func connectionFailureMessage() -> String {
        NetworkMonitor.shared.isConnected
            ? "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
            : "Нет интернета. Проверьте подключение и попробуйте снова"
    }

    private func userFacingError(for error: NetworkError) async -> Error {
        if error.isConnectionError {
            return ChatServiceError(
                message: await connectionFailureMessage(),
                isConnectionFailure: true
            )
        }
        if case .apiError(let api) = error {
            return ChatServiceError(message: api.userMessage, isConnectionFailure: false)
        }
        if case .transportError(let underlying) = error,
           NetworkError.isTransportLikelyConnectionFailure(underlying) {
            return ChatServiceError(
                message: await connectionFailureMessage(),
                isConnectionFailure: true
            )
        }
        if case .transportError(let underlying) = error {
            return ChatServiceError(
                message: (underlying as NSError).localizedDescription,
                isConnectionFailure: NetworkError.isTransportLikelyConnectionFailure(underlying)
            )
        }
        return ChatServiceError(message: error.localizedDescription, isConnectionFailure: false)
    }

    private func questionForButtonAction(_ action: ButtonAction) -> String {
        switch action {
        case .selectScenario(let scenario):
            return scenario.title
        case .confirmYes:
            return "Да, хочу получить оценку резюме"
        case .confirmNo:
            return "Нет, другие вопросы по карьере"
        case .selectInterviewType(let type):
            switch type {
            case "technical":
                return "Хочу подготовиться к техническому интервью"
            case "behavioral":
                return "Хочу подготовиться к поведенческому интервью"
            case "general":
                return "Нужны общие советы по собеседованию"
            default:
                return "Подготовка к собеседованию"
            }
        case .requestVacancyId:
            return "Запрос ID вакансии"
        case .reviewResumeNow:
            return "Анализ резюме"
        }
    }

    public func prepareForVacancy(vacancyId: String) async throws -> String {
        _ = try? await addChatMessage(conversationId: conversationId, content: "Подготовка к вакансии: \(vacancyId)", isUser: true)
        let result = await networkService.prepareForVacancy(vacancyId: vacancyId)
        switch result {
        case .success(let response):
            _ = try? await addChatMessage(conversationId: conversationId, content: response.recommendations, isUser: false)
            return response.recommendations
        case .failure(let error):
            throw await userFacingError(for: error)
        }
    }

    public func reviewResume() async throws -> (score: Double, recommendations: String) {
        let result = await networkService.reviewResume()
        switch result {
        case .success(let response):
            let replyText = "Оценка: \(String(format: "%.1f", response.score))/10\n\n\(response.recommendations)"
            _ = try? await addChatMessage(conversationId: conversationId, content: "Консультация по резюме", isUser: true)
            _ = try? await addChatMessage(conversationId: conversationId, content: replyText, isUser: false)
            return (score: response.score, recommendations: response.recommendations)
        case .failure(let error):
            throw await userFacingError(for: error)
        }
    }

    public func clearChatHistory(conversationId: String?) async throws -> (ok: Bool, deletedConversations: Int) {
        let result = await networkService.clearChatHistory(conversationId: conversationId)
        switch result {
        case .success(let response):
            if conversationId == nil || conversationId == self.conversationId {
                self.conversationId = nil
            }
            return (ok: response.ok, deletedConversations: Int(response.deletedConversations))
        case .failure(let error):
            throw await userFacingError(for: error)
        }
    }

    public func getCoachChatHistory(pageSize: Int, pageOffset: Int) async throws -> [ChatMessage] {
        let result = await networkService.getCoachChatHistory(pageSize: Int32(pageSize), pageOffset: Int32(pageOffset))
        switch result {
        case .success(let response):
            return response.entries.compactMap { entry -> ChatMessage? in
                let sender: MessageSender
                switch entry.kind {
                case .askUser:
                    sender = .user
                case .askAssistant, .reviewResume, .prepareVacancy:
                    sender = .consultant
                default:
                    return nil
                }

                let timestamp = ISO8601DateFormatter().date(from: entry.createdAt) ?? Date()

                return ChatMessage(
                    text: entry.content,
                    sender: sender,
                    timestamp: timestamp,
                    status: .read
                )
            }
        case .failure(let error):
            throw await userFacingError(for: error)
        }
    }

    public func addChatMessage(conversationId: String?, content: String, isUser: Bool) async throws -> String {
        let owner: Coach_ChatMessageOwner = isUser ? .user : .assistant
        let result = await networkService.addChatMessage(
            conversationId: conversationId ?? self.conversationId,
            content: content,
            owner: owner
        )
        switch result {
        case .success(let response):
            if !response.conversationID.isEmpty {
                self.conversationId = response.conversationID
            }
            return response.conversationID
        case .failure(let error):
            throw await userFacingError(for: error)
        }
    }

}

private struct ChatServiceError: Error, LocalizedError {
    let message: String
    let isConnectionFailure: Bool
    var errorDescription: String? { message }
}
