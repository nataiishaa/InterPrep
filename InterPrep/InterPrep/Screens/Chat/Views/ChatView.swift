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
                                    MessageBubbleView(message: message)
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
            .navigationTitle(model.consultant?.name ?? "Чат с консультантом")
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
    }
}

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
            onSendMessage: {}
        )
    )
}
