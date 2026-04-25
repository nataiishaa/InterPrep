//
//  ChatView.swift
//  InterPrep
//
//  Chat main view
//

import DesignSystem
import NetworkMonitorService
import SwiftUI

struct ChatView: View {
    let model: Model
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showClearConfirmation = false
    
    private var hasSubstantiveThread: Bool {
        let hasUser = model.messages.contains { $0.sender == .user }
        return hasUser || model.messages.count > 1
    }
    
    /// No saved thread and (offline or load failed) — show full-screen placeholder, not a half-broken welcome.
    private var shouldShowNoConnection: Bool {
        if model.isLoading { return false }
        if hasSubstantiveThread { return false }
        if !networkMonitor.isConnected { return true }
        if model.error != nil && model.messages.isEmpty { return true }
        return false
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let error = model.error, !shouldShowNoConnection {
                    HStack(spacing: 12) {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Button("Повторить") {
                            model.onDismissError()
                            model.onRetry()
                        }
                        .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                }
                
                if shouldShowNoConnection {
                    NoConnectionView(onRetry: { model.onRetry() })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if model.isLoading && model.messages.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    chatScrollContent
                }
                
                if !shouldShowNoConnection {
                    if !networkMonitor.isConnected && hasSubstantiveThread {
                        OfflineBanner()
                    }
                    
                    if model.showFavoritesPicker {
                        FavoriteVacancyPickerView(
                            vacancies: model.favoriteVacancies,
                            isLoading: model.isLoadingFavorites,
                            onSelect: model.onSelectFavoriteVacancy,
                            onDismiss: model.onHideFavoritesPicker
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    ChatInputBar(
                        text: model.inputText,
                        isSending: model.isSending || !networkMonitor.isConnected,
                        waitingForVacancyId: model.waitingForVacancyId,
                        onTextChanged: model.onInputTextChanged,
                        onSend: model.onSendMessage,
                        onFavoritesTapped: model.onShowFavoritesPicker
                    )
                }
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Карьерный консультант")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let onClose = model.onClose {
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Очистить чат?", isPresented: $showClearConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) {
                    model.onClearHistory()
                }
            } message: {
                Text("Вся история сообщений будет удалена. Это действие нельзя отменить.")
            }
        }
    }
    
    @ViewBuilder
    private var chatScrollContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.messages) { message in
                        MessageBubbleView(
                            message: message,
                            onButtonTap: model.onButtonTapped,
                            isSending: model.isSending
                        )
                        .id(message.id)
                    }
                    
                    if model.isSending {
                        HStack(alignment: .bottom, spacing: 8) {
                            TypingIndicatorView()
                                .id("loading-indicator")
                            Spacer(minLength: 60)
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                if let lastMessage = model.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onChange(of: model.messages.count) { _, _ in
                if let lastMessage = model.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: model.isSending) { _, isSending in
                if isSending {
                    withAnimation {
                        proxy.scrollTo("loading-indicator", anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatView(model: .fixtureWelcome)
                .previewDisplayName("Welcome")
            ChatView(model: .fixtureWithMessages)
                .previewDisplayName("With Messages")
            ChatView(model: .fixtureWithButtons)
                .previewDisplayName("With Buttons")
            ChatView(model: .fixtureLoading)
                .previewDisplayName("Loading")
            ChatView(model: .fixtureSending)
                .previewDisplayName("Sending")
        }
    }
}
