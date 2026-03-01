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
                
                // Input bar
                ChatInputBar(
                    text: model.inputText,
                    isSending: model.isSending,
                    onTextChanged: model.onInputTextChanged,
                    onSend: model.onSendMessage
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
        let onInputTextChanged: (String) -> Void
        let onSendMessage: () -> Void
        let onButtonTapped: (MessageButton) -> Void
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onButtonTapped: { _ in }
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onButtonTapped: { _ in }
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onButtonTapped: { _ in }
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onButtonTapped: { _ in }
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
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onButtonTapped: { _ in }
        )
    }
}
#endif

// MARK: - Preview

#Preview {
    ChatView(
        model: .init(
            messages: [
                ChatMessage(
                    text: "Здравствуйте! Я ваш карьерный консультант. Чем могу помочь?",
                    sender: .consultant,
                    timestamp: Date().addingTimeInterval(-3600)
                ),
                ChatMessage(
                    text: "Привет! Хотел бы обсудить подготовку к интервью",
                    sender: .user,
                    timestamp: Date().addingTimeInterval(-3500)
                ),
                ChatMessage(
                    text: "Отлично! Давайте начнем с того, на какую позицию вы готовитесь?",
                    sender: .consultant,
                    timestamp: Date().addingTimeInterval(-3400)
                )
            ],
            consultant: Consultant(
                name: "Анна Петрова",
                title: "Карьерный консультант",
                isOnline: true
            ),
            inputText: "",
            isLoading: false,
            isSending: false,
            isConnected: true,
            onInputTextChanged: { _ in },
            onSendMessage: {},
            onButtonTapped: { _ in }
        )
    )
}
