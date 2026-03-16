//
//  ChatServiceImpl.swift
//  InterPrep
//
//  Реализация чата с карьерным консультантом через API Ask (api-gateway gRPC).
//  Сохраняет conversation_id для продолжения диалога; таймаут запроса 120 с.
//

import Foundation
import ChatFeature
import NetworkService

public final actor ChatServiceImpl: ChatServiceProtocol {
    private let networkService: NetworkServiceV2
    private var conversationId: String?

    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }

    public func fetchMessages() async throws -> [ChatMessage] {
        // История диалога не подгружается с бэкенда; показываем приветствие локально.
        return [
            ChatMessage(
                text: "Здравствуйте! Я карьерный консультант. Задайте вопрос по карьере, подготовке к собеседованию или резюме.",
                sender: .consultant,
                timestamp: Date(),
                status: .read,
                buttons: [
                    MessageButton(text: "Помощь в подготовке к собеседованию", action: .selectScenario(.interviewPrep)),
                    MessageButton(text: "Консультация по резюме", action: .selectScenario(.resumeConsultation)),
                    MessageButton(text: "Другое", action: .selectScenario(.other))
                ]
            )
        ]
    }

    public func fetchConsultant() async throws -> Consultant {
        Consultant(
            name: "Карьерный консультант",
            title: "AI-ассистент",
            isOnline: true
        )
    }

    public func connect() async throws {
        // Ask — stateless по подключению; авторизация в каждом запросе через JWT.
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
            return ChatMessage(
                text: response.answer,
                sender: .consultant,
                timestamp: Date(),
                status: .sent
            )
        case .failure(let error):
            throw userFacingError(for: error)
        }
    }

    public func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage {
        let question = questionForButtonAction(action)
        let result = await networkService.ask(
            conversationId: conversationId,
            question: question
        )
        switch result {
        case .success(let response):
            if !response.conversationID.isEmpty {
                conversationId = response.conversationID
            }
            return ChatMessage(
                text: response.answer,
                sender: .consultant,
                timestamp: Date(),
                status: .sent
            )
        case .failure(let error):
            throw userFacingError(for: error)
        }
    }

    /// Сообщение для пользователя при обрыве соединения / таймауте (вместо сырого -1005).
    private func userFacingError(for error: NetworkError) -> Error {
        if error.isConnectionError {
            return ChatServiceError(message: "Соединение разорвано или таймаут. Проверьте интернет и нажмите «Повторить».")
        }
        if case .apiError(let api) = error {
            return ChatServiceError(message: api.userMessage)
        }
        return ChatServiceError(message: error.localizedDescription)
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
        }
    }
}

// MARK: - User-facing error

private struct ChatServiceError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
