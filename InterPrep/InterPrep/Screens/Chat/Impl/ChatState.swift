//
//  ChatState.swift
//  InterPrep
//
//  Chat state management
//

import ArchitectureCore
import DiscoveryModule
import Foundation

public struct ChatState {
    public var messages: [ChatMessage] = []
    public var inputText: String = ""
    public var isLoading: Bool = false
    public var isSending: Bool = false
    public var isConnected: Bool = false
    public var error: String?
    public var showResumeUploadPrompt: Bool = false
    public var consultant: Consultant?
    public var currentScenario: ChatScenario?
    public var waitingForVacancyId: Bool = false
    public var favoriteVacancies: [DiscoveryState.Vacancy] = []
    public var isLoadingFavorites: Bool = false
    public var showFavoritesPicker: Bool = false
    public static let systemHints: [String] = [
        "Расскажи про свой опыт",
        "Какие вопросы задают на интервью?",
        "Как рассказать о проектах?",
        "Помоги с ответом на слабые стороны",
        "Подготовь к техническому интервью"
    ]
    
    public init() {}
}

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let sender: MessageSender
    public let timestamp: Date
    public let status: MessageStatus
    public let buttons: [MessageButton]
    
    public init(
        id: UUID = UUID(),
        text: String,
        sender: MessageSender,
        timestamp: Date = Date(),
        status: MessageStatus = .sent,
        buttons: [MessageButton] = []
    ) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.status = status
        self.buttons = buttons
    }
}

public struct MessageButton: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let action: ButtonAction
    
    public init(
        id: UUID = UUID(),
        text: String,
        action: ButtonAction
    ) {
        self.id = id
        self.text = text
        self.action = action
    }
}

public enum ButtonAction: Equatable, Sendable {
    case selectScenario(ChatScenario)
    case confirmYes
    case confirmNo
    case selectInterviewType(String)
    case requestVacancyId
    case reviewResumeNow
}

public enum MessageSender: Equatable, Sendable {
    case user
    case consultant
}

public enum MessageStatus: Equatable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

public struct Consultant: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let avatar: String?
    public let title: String
    public let isOnline: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        avatar: String? = nil,
        title: String,
        isOnline: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.title = title
        self.isOnline = isOnline
    }
}

public enum ChatScenario: String, Identifiable, CaseIterable, Sendable {
    case interviewPrep = "interview_prep"
    case resumeConsultation = "resume_consultation"
    case other = "other"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .interviewPrep:
            return "Подготовка к собеседованию"
        case .resumeConsultation:
            return "Консультация по резюме"
        case .other:
            return "Другое"
        }
    }
}

extension ChatState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case inputTextChanged(String)
        case sendMessage
        case messageReceived(ChatMessage)
        case buttonTapped(MessageButton)
        case systemHintTapped(String)
        case dismissError
        case clearHistory
        case sendVacancyId(String)
        case showFavoritesPicker
        case hideFavoritesPicker
        case selectFavoriteVacancy(DiscoveryState.Vacancy)
        case dismissResumeUploadPrompt
    }
    
    public enum Feedback: Sendable {
        case messagesLoaded([ChatMessage])
        case consultantLoaded(Consultant)
        case messageSent(ChatMessage, consultantReply: ChatMessage?)
        case connectionStatusChanged(Bool)
        case loadingFailed(String)
        case consultantResponded(ChatMessage)
        case consultantChunk(messageId: UUID, chunk: String)
        case consultantStreamFinished(messageId: UUID)
        case vacancyPreparationReceived(String)
        case resumeReviewReceived(score: Double, recommendations: String)
        case favoritesLoaded([DiscoveryState.Vacancy])
        case favoritesLoadFailed
    }
    
    public enum Effect: Sendable {
        case loadMessages
        case loadConsultant
        case connect
        case sendMessage(ChatMessage)
        case handleButtonAction(ButtonAction)
        case clearHistory
        case prepareForVacancy(String)
        case reviewResume
        case loadFavorites
    }
    
    @MainActor
    // swiftlint:disable:next function_body_length
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.onAppear):
            state.error = nil
            state.isLoading = true
            return .loadMessages
            
        case .input(.inputTextChanged(let text)):
            state.inputText = text
            return nil
            
        case .input(.systemHintTapped(let hint)):
            state.inputText = hint
            return nil
            
        case .input(.sendMessage):
            guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            
            let message = ChatMessage(
                text: state.inputText,
                sender: .user,
                status: .sent
            )
            
            state.messages.append(message)
            state.inputText = ""
            state.isSending = true
            
            if state.waitingForVacancyId {
                state.waitingForVacancyId = false
            }
            
            return .sendMessage(message)
            
        case .input(.messageReceived(let message)):
            state.messages.append(message)
            return nil
            
        case .input(.buttonTapped(let button)):
            state.isSending = true
            if case .selectScenario(.interviewPrep) = button.action {
                state.currentScenario = .interviewPrep
                state.waitingForVacancyId = true
                if state.favoriteVacancies.isEmpty {
                    state.isLoadingFavorites = true
                }
            }
            return .handleButtonAction(button.action)
            
        case .input(.sendVacancyId(let vacancyId)):
            state.isSending = true
            return .prepareForVacancy(vacancyId)
            
        case .input(.dismissError):
            state.error = nil
            return nil
            
        case .input(.clearHistory):
            state.error = nil
            state.isSending = false
            state.isLoading = true
            return .clearHistory
            
        case .feedback(.messagesLoaded(let messages)):
            state.messages = messages
            state.isLoading = false
            return nil
            
        case .feedback(.consultantResponded(let message)):
            state.messages.append(message)
            state.isSending = false
            let isVacancyRequest = message.text.contains("из избранного") || state.currentScenario == .interviewPrep
            if isVacancyRequest {
                state.waitingForVacancyId = true
                state.showFavoritesPicker = true
                if state.favoriteVacancies.isEmpty {
                    state.isLoadingFavorites = true
                    return .loadFavorites
                }
            }
            return nil
            
        case .feedback(.vacancyPreparationReceived(let recommendations)):
            if let lastIndex = state.messages.lastIndex(where: { $0.sender == .user }) {
                let userMessage = state.messages[lastIndex]
                state.messages[lastIndex] = ChatMessage(
                    id: userMessage.id,
                    text: userMessage.text,
                    sender: userMessage.sender,
                    timestamp: userMessage.timestamp,
                    status: .sent
                )
            }
            let message = ChatMessage(
                text: recommendations,
                sender: .consultant,
                timestamp: Date(),
                status: .sent
            )
            state.messages.append(message)
            state.isSending = false
            state.waitingForVacancyId = false
            return nil
            
        case .feedback(.resumeReviewReceived(let score, let recommendations)):
            let message = ChatMessage(
                text: "Оценка вашего резюме: \(String(format: "%.1f", score))/10\n\n\(recommendations)",
                sender: .consultant,
                timestamp: Date(),
                status: .sent
            )
            state.messages.append(message)
            state.isSending = false
            return nil
            
        case .feedback(.consultantChunk(let messageId, let chunk)):
            if let index = state.messages.firstIndex(where: { $0.id == messageId }) {
                let current = state.messages[index]
                state.messages[index] = ChatMessage(
                    id: current.id,
                    text: current.text + chunk,
                    sender: current.sender,
                    timestamp: current.timestamp,
                    status: current.status,
                    buttons: current.buttons
                )
            }
            return nil
            
        case .feedback(.consultantStreamFinished(let messageId)):
            if let index = state.messages.firstIndex(where: { $0.id == messageId }) {
                let current = state.messages[index]
                state.messages[index] = ChatMessage(
                    id: current.id,
                    text: current.text,
                    sender: current.sender,
                    timestamp: current.timestamp,
                    status: .sent,
                    buttons: current.buttons
                )
            }
            return nil
            
        case .feedback(.consultantLoaded(let consultant)):
            state.consultant = consultant
            return nil
            
        case .feedback(.messageSent(let message, let consultantReply)):
            if let index = state.messages.firstIndex(where: { $0.id == message.id }) {
                state.messages[index] = ChatMessage(
                    id: message.id,
                    text: message.text,
                    sender: message.sender,
                    timestamp: message.timestamp,
                    status: .sent
                )
            }
            if let reply = consultantReply {
                state.messages.append(reply)
            }
            state.isSending = false
            return nil
            
        case .feedback(.connectionStatusChanged(let isConnected)):
            state.isConnected = isConnected
            return nil
            
        case .feedback(.loadingFailed(let error)):
            state.isLoading = false
            state.isSending = false
            let resumeKeywords = ["резюме", "resume", "Загрузите резюме", "Заполните профиль"]
            if resumeKeywords.contains(where: { error.localizedLowercase.contains($0.lowercased()) }) {
                state.showResumeUploadPrompt = true
                let message = ChatMessage(
                    text: "Для этого действия необходимо загрузить резюме. Загрузите резюме в разделе «Профиль» или «Документы», и я смогу вам помочь.",
                    sender: .consultant,
                    status: .sent
                )
                state.messages.append(message)
            } else {
                state.error = error
            }
            return nil
            
        case .input(.showFavoritesPicker):
            state.showFavoritesPicker = true
            if state.favoriteVacancies.isEmpty {
                state.isLoadingFavorites = true
                return .loadFavorites
            }
            return nil
            
        case .input(.hideFavoritesPicker):
            state.showFavoritesPicker = false
            return nil
            
        case .input(.selectFavoriteVacancy(let vacancy)):
            state.showFavoritesPicker = false
            var parts = ["\(vacancy.title) — \(vacancy.company)"]
            if let salary = vacancy.salaryText, !salary.isEmpty {
                parts.append(salary)
            }
            if !vacancy.location.isEmpty {
                parts.append(vacancy.location)
            }
            let message = ChatMessage(
                text: "Подготовиться к вакансии:\n\(parts.joined(separator: "\n"))",
                sender: .user,
                status: .sent
            )
            state.messages.append(message)
            state.isSending = true
            state.waitingForVacancyId = false
            return .prepareForVacancy(vacancy.id)
            
        case .feedback(.favoritesLoaded(let vacancies)):
            state.favoriteVacancies = vacancies
            state.isLoadingFavorites = false
            return nil
            
        case .feedback(.favoritesLoadFailed):
            state.isLoadingFavorites = false
            return nil
            
        case .input(.dismissResumeUploadPrompt):
            state.showResumeUploadPrompt = false
            return nil
        }
    }
}
