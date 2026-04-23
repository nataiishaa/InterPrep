//
//  ChatEffectHandler.swift
//  InterPrep
//
//  Chat effect handler
//

import ArchitectureCore
import Foundation

public actor ChatEffectHandler: EffectHandler {
    public typealias StateType = ChatState
    
    private let chatService: ChatServicing
    private let favoritesProvider: FavoritesProviding?
    
    public init(chatService: ChatServicing, favoritesProvider: FavoritesProviding? = nil) {
        self.chatService = chatService
        self.favoritesProvider = favoritesProvider
    }
    
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .loadMessages:
            do {
                let messages = try await chatService.fetchMessages()
                let consultant = try await chatService.fetchConsultant()
                try await chatService.connect()
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
                if case .selectScenario(.resumeConsultation) = action {
                    let (score, recommendations) = try await chatService.reviewResume()
                    return .resumeReviewReceived(score: score, recommendations: recommendations)
                }
                return .consultantResponded(response)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .prepareForVacancy(let vacancyId):
            do {
                let recommendations = try await chatService.prepareForVacancy(vacancyId: vacancyId)
                return .vacancyPreparationReceived(recommendations)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .reviewResume:
            do {
                let (score, recommendations) = try await chatService.reviewResume()
                return .resumeReviewReceived(score: score, recommendations: recommendations)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .clearHistory:
            do {
                _ = try await chatService.clearChatHistory(conversationId: nil)
                let messages = try await chatService.fetchMessages()
                return .messagesLoaded(messages)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .loadFavorites:
            guard let provider = favoritesProvider else { return .favoritesLoadFailed }
            do {
                let vacancies = try await provider.fetchFavorites()
                return .favoritesLoaded(vacancies)
            } catch {
                return .favoritesLoadFailed
            }
        }
    }
}

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
                    text: "Отлично! Для подготовки к собеседованию мне нужен ID вакансии с hh.ru.\n\nВы можете скопировать его в правом верхнем углу после клика на вакансию и открытия подробной информации.\n\nПожалуйста, отправьте ID вакансии.",
                    sender: .consultant
                )
                
            case .resumeConsultation:
                return ChatMessage(
                    text: "Анализирую ваше резюме...",
                    sender: .consultant
                )
                
            case .other:
                return ChatMessage(
                    text: "Чем могу помочь?",
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
            
        case .requestVacancyId, .reviewResumeNow:
            return ChatMessage(
                text: "Обрабатываю запрос...",
                sender: .consultant
            )
        }
    }
    
    public func clearHistory() async {}
    
    public func prepareForVacancy(vacancyId: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "Рекомендации по подготовке к вакансии:\n\n1. Изучите требования к позиции\n2. Подготовьте примеры из опыта\n3. Изучите компанию и её продукты\n4. Подготовьте вопросы интервьюеру"
    }
    
    public func reviewResume() async throws -> (score: Double, recommendations: String) {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return (
            score: 7.5,
            recommendations: "Ваше резюме выглядит хорошо! Рекомендации:\n\n1. Добавьте больше конкретных достижений\n2. Укажите используемые технологии\n3. Добавьте ссылки на проекты"
        )
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
                text: "Вот несколько советов для подготовки к техническому интервью:\n\n1. Повторите основы алгоритмов\n2. Практикуйтесь на LeetCode\n3. Изучите систем дизайн",
                sender: .consultant,
                timestamp: Date().addingTimeInterval(-3500),
                status: .read
            )
        ]
    }
}
