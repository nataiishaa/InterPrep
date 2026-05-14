import DiscoveryModule
import Foundation

extension ChatView {
    struct Model {
        let messages: [ChatMessage]
        let consultant: Consultant?
        let inputText: String
        let isLoading: Bool
        let isSending: Bool
        let isConnected: Bool
        let error: String?
        let systemHints: [String]
        let waitingForVacancyId: Bool
        let showFavoritesPicker: Bool
        let favoriteVacancies: [DiscoveryState.Vacancy]
        let isLoadingFavorites: Bool
        let onInputTextChanged: (String) -> Void
        let onSendMessage: () -> Void
        let onHintTapped: (String) -> Void
        let onButtonTapped: (MessageButton) -> Void
        let onDismissError: () -> Void
        let onClearHistory: () -> Void
        let onShowFavoritesPicker: () -> Void
        let onHideFavoritesPicker: () -> Void
        let onSelectFavoriteVacancy: (DiscoveryState.Vacancy) -> Void
        let onRetry: () -> Void
        let onClose: (() -> Void)?
    }
}

#if DEBUG
private struct NoopCallbacks {
    let onInputTextChanged: (String) -> Void = { _ in }
    let onSendMessage: () -> Void = {}
    let onHintTapped: (String) -> Void = { _ in }
    let onButtonTapped: (MessageButton) -> Void = { _ in }
    let onDismissError: () -> Void = {}
    let onClearHistory: () -> Void = {}
    let onShowFavoritesPicker: () -> Void = {}
    let onHideFavoritesPicker: () -> Void = {}
    let onSelectFavoriteVacancy: (DiscoveryState.Vacancy) -> Void = { _ in }
    let onRetry: () -> Void = {}
    let onClose: (() -> Void)? = nil
}

private let fixtureDate = Date(timeIntervalSince1970: 1704067200)

extension ChatView.Model {
    private static let noopCallbacks = NoopCallbacks()

    static var fixtureWelcome: Self {
        .init(
            messages: [
                ChatMessage(
                    text: "Здравствуйте! Я карьерный консультант, чем могу помочь?",
                    sender: .consultant,
                    timestamp: fixtureDate,
                    buttons: [
                        MessageButton(text: "Помощь в подготовке к собеседованию", action: .selectScenario(.interviewPrep)),
                        MessageButton(text: "Консультация по резюме", action: .selectScenario(.resumeConsultation)),
                        MessageButton(text: "Другое", action: .selectScenario(.other))
                    ]
                )
            ],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: false,
            isSending: false,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            waitingForVacancyId: false,
            showFavoritesPicker: false,
            favoriteVacancies: [],
            isLoadingFavorites: false,
            onInputTextChanged: noopCallbacks.onInputTextChanged,
            onSendMessage: noopCallbacks.onSendMessage,
            onHintTapped: noopCallbacks.onHintTapped,
            onButtonTapped: noopCallbacks.onButtonTapped,
            onDismissError: noopCallbacks.onDismissError,
            onClearHistory: noopCallbacks.onClearHistory,
            onShowFavoritesPicker: noopCallbacks.onShowFavoritesPicker,
            onHideFavoritesPicker: noopCallbacks.onHideFavoritesPicker,
            onSelectFavoriteVacancy: noopCallbacks.onSelectFavoriteVacancy,
            onRetry: noopCallbacks.onRetry,
            onClose: noopCallbacks.onClose
        )
    }

    static var fixtureWithMessages: Self {
        .init(
            messages: [
                ChatMessage(text: "Здравствуйте! Я карьерный консультант, чем могу помочь?", sender: .consultant, timestamp: fixtureDate),
                ChatMessage(text: "Привет! Хочу подготовиться к интервью", sender: .user, timestamp: fixtureDate, status: .read),
                ChatMessage(text: "Отлично! На какую позицию готовитесь?", sender: .consultant, timestamp: fixtureDate),
                ChatMessage(text: "iOS разработчик", sender: .user, timestamp: fixtureDate, status: .delivered)
            ],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: false,
            isSending: false,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            waitingForVacancyId: false,
            showFavoritesPicker: false,
            favoriteVacancies: [],
            isLoadingFavorites: false,
            onInputTextChanged: noopCallbacks.onInputTextChanged,
            onSendMessage: noopCallbacks.onSendMessage,
            onHintTapped: noopCallbacks.onHintTapped,
            onButtonTapped: noopCallbacks.onButtonTapped,
            onDismissError: noopCallbacks.onDismissError,
            onClearHistory: noopCallbacks.onClearHistory,
            onShowFavoritesPicker: noopCallbacks.onShowFavoritesPicker,
            onHideFavoritesPicker: noopCallbacks.onHideFavoritesPicker,
            onSelectFavoriteVacancy: noopCallbacks.onSelectFavoriteVacancy,
            onRetry: noopCallbacks.onRetry,
            onClose: noopCallbacks.onClose
        )
    }

    static var fixtureWithButtons: Self {
        .init(
            messages: [
                ChatMessage(
                    text: "Выберите тип собеседования:",
                    sender: .consultant,
                    timestamp: fixtureDate,
                    buttons: [
                        MessageButton(text: "Техническое интервью", action: .selectScenario(.interviewPrep)),
                        MessageButton(text: "Поведенческое интервью", action: .selectScenario(.resumeConsultation)),
                        MessageButton(text: "Общие советы", action: .selectScenario(.other))
                    ]
                )
            ],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: false,
            isSending: false,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            waitingForVacancyId: false,
            showFavoritesPicker: false,
            favoriteVacancies: [],
            isLoadingFavorites: false,
            onInputTextChanged: noopCallbacks.onInputTextChanged,
            onSendMessage: noopCallbacks.onSendMessage,
            onHintTapped: noopCallbacks.onHintTapped,
            onButtonTapped: noopCallbacks.onButtonTapped,
            onDismissError: noopCallbacks.onDismissError,
            onClearHistory: noopCallbacks.onClearHistory,
            onShowFavoritesPicker: noopCallbacks.onShowFavoritesPicker,
            onHideFavoritesPicker: noopCallbacks.onHideFavoritesPicker,
            onSelectFavoriteVacancy: noopCallbacks.onSelectFavoriteVacancy,
            onRetry: noopCallbacks.onRetry,
            onClose: noopCallbacks.onClose
        )
    }

    static var fixtureLoading: Self {
        .init(
            messages: [],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: true,
            isSending: false,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            waitingForVacancyId: false,
            showFavoritesPicker: false,
            favoriteVacancies: [],
            isLoadingFavorites: false,
            onInputTextChanged: noopCallbacks.onInputTextChanged,
            onSendMessage: noopCallbacks.onSendMessage,
            onHintTapped: noopCallbacks.onHintTapped,
            onButtonTapped: noopCallbacks.onButtonTapped,
            onDismissError: noopCallbacks.onDismissError,
            onClearHistory: noopCallbacks.onClearHistory,
            onShowFavoritesPicker: noopCallbacks.onShowFavoritesPicker,
            onHideFavoritesPicker: noopCallbacks.onHideFavoritesPicker,
            onSelectFavoriteVacancy: noopCallbacks.onSelectFavoriteVacancy,
            onRetry: noopCallbacks.onRetry,
            onClose: noopCallbacks.onClose
        )
    }

    static var fixtureSending: Self {
        .init(
            messages: [
                ChatMessage(text: "Здравствуйте!", sender: .consultant, timestamp: fixtureDate),
                ChatMessage(text: "Привет!", sender: .user, timestamp: fixtureDate, status: .sending)
            ],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: false,
            isSending: true,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            waitingForVacancyId: false,
            showFavoritesPicker: false,
            favoriteVacancies: [],
            isLoadingFavorites: false,
            onInputTextChanged: noopCallbacks.onInputTextChanged,
            onSendMessage: noopCallbacks.onSendMessage,
            onHintTapped: noopCallbacks.onHintTapped,
            onButtonTapped: noopCallbacks.onButtonTapped,
            onDismissError: noopCallbacks.onDismissError,
            onClearHistory: noopCallbacks.onClearHistory,
            onShowFavoritesPicker: noopCallbacks.onShowFavoritesPicker,
            onHideFavoritesPicker: noopCallbacks.onHideFavoritesPicker,
            onSelectFavoriteVacancy: noopCallbacks.onSelectFavoriteVacancy,
            onRetry: noopCallbacks.onRetry,
            onClose: noopCallbacks.onClose
        )
    }
}
#endif
