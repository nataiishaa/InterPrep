//
//  ChatContainer.swift
//  InterPrep
//
//  Chat container
//

import SwiftUI
import ArchitectureCore

public struct ChatContainer: View {
    @StateObject private var store: ChatStore
    
    public init(store: @autoclosure @escaping () -> ChatStore) {
        _store = StateObject(wrappedValue: store())
    }
    
    public var body: some View {
        ChatView(model: makeModel())
            .task {
                store.send(.onAppear)
            }
    }
    
    // MARK: - Make Model
    
    private func makeModel() -> ChatView.Model {
        .init(
            messages: store.state.messages,
            consultant: store.state.consultant,
            inputText: store.state.inputText,
            isLoading: store.state.isLoading,
            isSending: store.state.isSending,
            isConnected: store.state.isConnected,
            systemHints: ChatState.systemHints,
            onInputTextChanged: { text in
                store.send(.inputTextChanged(text))
            },
            onSendMessage: {
                store.send(.sendMessage)
            },
            onHintTapped: { hint in
                store.send(.systemHintTapped(hint))
            },
            onButtonTapped: { button in
                store.send(.buttonTapped(button))
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ChatContainer(store: Store(
        state: ChatState(),
        effectHandler: ChatEffectHandler(
            chatService: ChatServiceMock()
        )
    ))
}
