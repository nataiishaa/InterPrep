//
//  ChatView+Model.swift
//  InterPrep
//
//  Chat view model
//

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
        let onInputTextChanged: (String) -> Void
        let onSendMessage: () -> Void
        let onHintTapped: (String) -> Void
        let onButtonTapped: (MessageButton) -> Void
        let onDismissError: () -> Void
        let onClearHistory: () -> Void
    }
}

#if DEBUG
extension ChatView.Model {
    static var fixtureWelcome: Self {
        .init(
            messages: [
                ChatMessage(
                    text: "Здравствуйте! Я карьерный консультант, чем могу помочь?",
                    sender: .consultant,
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onHintTapped: { _ in },
            onButtonTapped: { _ in },
            onDismissError: {},
            onClearHistory: {}
        )
    }
    
    static var fixtureWithMessages: Self {
        .init(
            messages: [
                ChatMessage(text: "Здравствуйте! Я карьерный консультант, чем могу помочь?", sender: .consultant),
                ChatMessage(text: "Привет! Хочу подготовиться к интервью", sender: .user, status: .read),
                ChatMessage(text: "Отлично! На какую позицию готовитесь?", sender: .consultant),
                ChatMessage(text: "iOS разработчик", sender: .user, status: .delivered)
            ],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: false,
            isSending: false,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onHintTapped: { _ in },
            onButtonTapped: { _ in },
            onDismissError: {},
            onClearHistory: {}
        )
    }
    
    static var fixtureWithButtons: Self {
        .init(
            messages: [
                ChatMessage(
                    text: "Выберите тип собеседования:",
                    sender: .consultant,
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onHintTapped: { _ in },
            onButtonTapped: { _ in },
            onDismissError: {},
            onClearHistory: {}
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onHintTapped: { _ in },
            onButtonTapped: { _ in },
            onDismissError: {},
            onClearHistory: {}
        )
    }
    
    static var fixtureSending: Self {
        .init(
            messages: [
                ChatMessage(text: "Здравствуйте!", sender: .consultant),
                ChatMessage(text: "Привет!", sender: .user, status: .sending)
            ],
            consultant: Consultant(name: "Карьерный консультант", title: "AI помощник", isOnline: true),
            inputText: "",
            isLoading: false,
            isSending: true,
            isConnected: true,
            error: nil,
            systemHints: ChatState.systemHints,
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onHintTapped: { _ in },
            onButtonTapped: { _ in },
            onDismissError: {},
            onClearHistory: {}
        )
    }
}
#endif
