//
//  ChatView.swift
//  InterPrep
//
//  Chat main view
//

import SwiftUI
import DesignSystem

struct ChatView: View {
    let model: Model
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Ошибка + Повторить (гайд: при INTERNAL предлагай кнопку «Повторить»)
                if let error = model.error {
                    HStack(spacing: 12) {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Button("Повторить") {
                            model.onDismissError()
                        }
                        .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                }
                
                // Messages
                if model.isLoading && model.messages.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(model.messages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        onButtonTap: model.onButtonTapped
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: model.messages.count) { _, _ in
                            if let lastMessage = model.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                ChatInputBar(
                    text: model.inputText,
                    isSending: model.isSending,
                    systemHints: model.systemHints,
                    onTextChanged: model.onInputTextChanged,
                    onSend: model.onSendMessage,
                    onHintTapped: model.onHintTapped
                )
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(model.consultant?.name ?? "Карьерный консультант")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let consultant = model.consultant {
                        VStack(spacing: 2) {
                            Text(consultant.name)
                                .font(.headline)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(consultant.isOnline ? Color.green : Color.gray)
                                    .frame(width: 6, height: 6)
                                
                                Text(consultant.isOnline ? "В сети" : "Не в сети")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.onClearHistory()
                    } label: {
                        Text("Новый чат")
                            .font(.subheadline)
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Model

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

// MARK: - Fixtures

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

// MARK: - Preview

#Preview("Welcome") {
    ChatView(model: .fixtureWelcome)
}

#Preview("With Messages") {
    ChatView(model: .fixtureWithMessages)
}

#Preview("With Buttons") {
    ChatView(model: .fixtureWithButtons)
}

#Preview("Loading") {
    ChatView(model: .fixtureLoading)
}

#Preview("Sending") {
    ChatView(model: .fixtureSending)
}
