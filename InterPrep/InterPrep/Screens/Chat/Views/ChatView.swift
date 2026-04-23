//
//  ChatView.swift
//  InterPrep
//
//  Chat main view
//

import DesignSystem
import SwiftUI

struct ChatView: View {
    let model: Model
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                
                if model.isLoading && model.messages.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if model.messages.count <= 1 {
                                    ChatWelcomeView()
                                }
                                
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
                    isSending: model.isSending,
                    systemHints: model.systemHints,
                    waitingForVacancyId: model.waitingForVacancyId,
                    onTextChanged: model.onInputTextChanged,
                    onSend: model.onSendMessage,
                    onHintTapped: model.onHintTapped,
                    onFavoritesTapped: model.onShowFavoritesPicker
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
                        Text("Очистить чат")
                            .font(.subheadline)
                            .foregroundColor(.brandPrimary)
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
