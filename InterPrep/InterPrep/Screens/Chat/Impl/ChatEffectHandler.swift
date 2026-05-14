import AnalyticsService
import ArchitectureCore
import DiscoveryModule
import Foundation
import NetworkMonitorService
import NetworkService

public actor ChatEffectHandler: EffectHandler {
    public typealias StateType = ChatState

    private let chatService: ChatServicing
    private let favoritesProvider: FavoritesProviding?

    public init(chatService: ChatServicing, favoritesProvider: FavoritesProviding? = nil) {
        self.chatService = chatService
        self.favoritesProvider = favoritesProvider
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .loadMessages:
            await trackEvent(.chatStarted(vacancyId: nil))
            do {
                let messages = try await chatService.fetchMessages()
                try await chatService.connect()
                return .messagesLoaded(messages)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .loadConsultant:
            do {
                let consultant = try await chatService.fetchConsultant()
                return .consultantLoaded(consultant)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .connect:
            do {
                try await chatService.connect()
                return .connectionStatusChanged(true)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .sendMessage(let message):
            await trackEvent(.chatMessageSent(messageLength: message.text.count))
            do {
                let consultantReply = try await chatService.sendMessage(message)
                return .messageSent(message, consultantReply: consultantReply)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .handleButtonAction(let action):
            do {
                if case .selectScenario(.resumeConsultation) = action {
                    let (score, recommendations) = try await chatService.reviewResume()
                    return .resumeReviewReceived(score: score, recommendations: recommendations)
                }
                let response = try await chatService.handleButtonAction(action)
                return .consultantResponded(response)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .prepareForVacancy(let vacancyId):
            do {
                let recommendations = try await chatService.prepareForVacancy(vacancyId: vacancyId)
                return .vacancyPreparationReceived(recommendations)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .reviewResume:
            do {
                let (score, recommendations) = try await chatService.reviewResume()
                return .resumeReviewReceived(score: score, recommendations: recommendations)
            } catch {
                return .loadingFailed(userMessage(for: error))
            }

        case .clearHistory:
            do {
                _ = try await chatService.clearChatHistory(conversationId: nil)
                let messages = try await chatService.fetchMessages()
                return .messagesLoaded(messages)
            } catch {
                return .loadingFailed(userMessage(for: error))
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

    private func userMessage(for error: Error) -> String {
        if let localizable = error as? LocalizedError, let desc = localizable.errorDescription {
            return desc
        }
        if let ne = error as? NetworkError, ne.isConnectionError {
            return "Не удалось подключиться к серверу"
        }
        return "Произошла ошибка. Попробуйте позже"
    }

    @MainActor
    private func trackEvent(_ event: AnalyticsEvent) {
        AnalyticsManager.shared.track(event)
    }
}
