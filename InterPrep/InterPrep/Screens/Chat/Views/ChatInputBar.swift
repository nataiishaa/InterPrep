//
//  ChatInputBar.swift
//  InterPrep
//
//  Chat input bar component
//

import DesignSystem
import SwiftUI

struct ChatInputBar: View {
    let text: String
    let isSending: Bool
    let systemHints: [String]
    let waitingForVacancyId: Bool
    let onTextChanged: (String) -> Void
    let onSend: () -> Void
    let onHintTapped: (String) -> Void
    let onFavoritesTapped: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(
        text: String,
        isSending: Bool,
        systemHints: [String] = ChatState.systemHints,
        waitingForVacancyId: Bool = false,
        onTextChanged: @escaping (String) -> Void,
        onSend: @escaping () -> Void,
        onHintTapped: @escaping (String) -> Void,
        onFavoritesTapped: (() -> Void)? = nil
    ) {
        self.text = text
        self.isSending = isSending
        self.systemHints = systemHints
        self.waitingForVacancyId = waitingForVacancyId
        self.onTextChanged = onTextChanged
        self.onSend = onSend
        self.onHintTapped = onHintTapped
        self.onFavoritesTapped = onFavoritesTapped
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if !systemHints.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(systemHints, id: \.self) { hint in
                            Button(action: { onHintTapped(hint) }, label: {
                                Text(hint)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.fieldBackground)
                                    .foregroundColor(Color.primary)
                                    .cornerRadius(16)
                            })
                            .disabled(isSending)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
            }
        
        HStack(spacing: 12) {
            if waitingForVacancyId, let onFavoritesTapped {
                Button {
                    onFavoritesTapped()
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.12))
                        )
                }
                .disabled(isSending)
            }
            
            TextField(
                waitingForVacancyId ? "ID вакансии или выберите из избранного" : "Сообщение",
                text: .init(
                    get: { text },
                    set: { onTextChanged($0) }
                )
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.fieldBackground)
            .cornerRadius(20)
            .focused($isFocused)
            .disabled(isSending)
            
            Button(action: {
                onSend()
                isFocused = true
            }, label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(canSend ? Color.brandPrimary : Color.gray)
                    )
            })
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        }
        .background(Color.cardBackground)
        .shadow(color: shadowColor, radius: 4, x: 0, y: -2)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        Spacer()
        
        ChatInputBar(
            text: "",
            isSending: false,
            onTextChanged: { _ in },
            onSend: {},
            onHintTapped: { _ in }
        )
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        
        ChatInputBar(
            text: "Привет! Как дела?",
            isSending: false,
            onTextChanged: { _ in },
            onSend: {},
            onHintTapped: { _ in }
        )
    }
}

#Preview("Sending") {
    VStack {
        Spacer()
        
        ChatInputBar(
            text: "",
            isSending: true,
            onTextChanged: { _ in },
            onSend: {},
            onHintTapped: { _ in }
        )
    }
}
