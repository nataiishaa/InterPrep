//
//  ChatContainer.swift
//  InterPrep
//
//  Chat container
//

import ArchitectureCore
import NetworkMonitorService
import SwiftUI

public struct ChatContainer: View {
    @State private var store: ChatStore
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    
    public init(store: ChatStore) {
        self.store = store
    }
    
    public var body: some View {
        ChatView(model: makeModel())
            .task {
                store.send(.onAppear)
            }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                if isConnected && store.state.error != nil {
                    store.send(.onAppear)
                }
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
            },
            onRetry: {
                store.send(.onAppear)
            },
            onClose: {
                dismiss()
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
