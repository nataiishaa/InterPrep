//
//  ChatContainer.swift
//  InterPrep
//
//  Chat container
//

import ArchitectureCore
import SwiftUI

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
    
    private func makeModel() -> ChatView.Model {
        .init(
            messages: store.state.messages,
            consultant: store.state.consultant,
            inputText: store.state.inputText,
            isLoading: store.state.isLoading,
            isSending: store.state.isSending,
            isConnected: store.state.isConnected,
            error: store.state.error,
            systemHints: ChatState.systemHints,
            waitingForVacancyId: store.state.waitingForVacancyId,
            showFavoritesPicker: store.state.showFavoritesPicker,
            favoriteVacancies: store.state.favoriteVacancies,
            isLoadingFavorites: store.state.isLoadingFavorites,
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
            },
            onDismissError: {
                store.send(.dismissError)
            },
            onClearHistory: {
                store.send(.clearHistory)
            },
            onShowFavoritesPicker: {
                store.send(.showFavoritesPicker)
            },
            onHideFavoritesPicker: {
                store.send(.hideFavoritesPicker)
            },
            onSelectFavoriteVacancy: { vacancy in
                store.send(.selectFavoriteVacancy(vacancy))
            }
        )
    }
}

#Preview {
    ChatContainer(store: Store(
        state: ChatState(),
        effectHandler: ChatEffectHandler(
            chatService: ChatServiceMock()
        )
    ))
}
