//
//  ChatEffectHandler.swift
//  InterPrep
//
//  Chat effect handler
//

import Foundation
import ArchitectureCore

// MARK: - Effect Handler

public actor ChatEffectHandler: EffectHandler {
    public typealias S = ChatState
    
    private let chatService: ChatServiceProtocol
    
    public init(chatService: ChatServiceProtocol) {
        self.chatService = chatService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case .loadMessages:
            do {
                let messages = try await chatService.fetchMessages()
                // Also load consultant and connect after loading messages
                let consultant = try await chatService.fetchConsultant()
                try await chatService.connect()
                // Note: We can only return one feedback at a time
                // In a real app, you might want to chain these differently
                return .messagesLoaded(messages)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .loadConsultant:
            do {
                let consultant = try await chatService.fetchConsultant()
                return .consultantLoaded(consultant)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .connect:
            do {
                try await chatService.connect()
                return .connectionStatusChanged(true)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .sendMessage(let message):
            do {
                let consultantReply = try await chatService.sendMessage(message)
                return .messageSent(message, consultantReply: consultantReply)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .handleButtonAction(let action):
            do {
                let response = try await chatService.handleButtonAction(action)
                return .consultantResponded(response)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Service Protocol

public protocol ChatServiceProtocol: Actor {
    func fetchMessages() async throws -> [ChatMessage]
    func fetchConsultant() async throws -> Consultant
    func connect() async throws
    func disconnect() async
    /// Отправляет сообщение; возвращает опциональный ответ консультанта (длинный ответ приходит одним сообщением).
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage?
    func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage
}

// MARK: - Mock Service

public final actor ChatServiceMock: ChatServiceProtocol {
    public init() {}
    
    public func fetchMessages() async throws -> [ChatMessage] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Приветственное сообщение с кнопками выбора сценария
        return [
            ChatMessage(
                text: "Здравствуйте! Я карьерный консультант, чем могу помочь?",
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
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 c
        return ChatMessage(
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
                return ChatMessage(
                    text: "Отлично! Выберите тип собеседования:",
                    sender: .consultant,
                    buttons: [
                        MessageButton(text: "Техническое интервью", action: .selectInterviewType("technical")),
                        MessageButton(text: "Поведенческое интервью", action: .selectInterviewType("behavioral")),
                        MessageButton(text: "Общие советы", action: .selectInterviewType("general"))
                    ]
                )
                
            case .resumeConsultation:
                return ChatMessage(
                    text: "Хочешь получить независимую оценку своего резюме или у тебя другие вопросы?",
                    sender: .consultant,
                    buttons: [
                        MessageButton(text: "Да", action: .confirmYes),
                        MessageButton(text: "Нет", action: .confirmNo)
                    ]
                )
                
            case .other:
                return ChatMessage(
                    text: "Расскажите, чем я могу вам помочь?",
                    sender: .consultant
                )
            }
            
        case .confirmYes:
            return ChatMessage(
                text: "Отлично! Загрузите ваше резюме, и я проведу детальный анализ.",
                sender: .consultant
            )
            
        case .confirmNo:
            return ChatMessage(
                text: "Хорошо! Задавайте любые вопросы по карьере, и я с удовольствием помогу.",
                sender: .consultant
            )
            
        case .selectInterviewType(let type):
            let responseText: String
            switch type {
            case "technical":
                responseText = "Отлично! Давайте начнем подготовку к техническому интервью. На какую позицию вы готовитесь?"
            case "behavioral":
                responseText = "Хорошо! Поведенческие интервью - важная часть. Расскажите о компании и позиции."
            case "general":
                responseText = "Вот основные советы:\n\n1. Изучите компанию\n2. Подготовьте вопросы\n3. Практикуйте ответы\n4. Будьте собой"
            default:
                responseText = "Давайте начнем подготовку!"
            }
            
            return ChatMessage(
                text: responseText,
                sender: .consultant
            )
        }
    }
}
