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
    let waitingForVacancyId: Bool
    let onTextChanged: (String) -> Void
    let onSend: () -> Void
    let onFavoritesTapped: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(
        text: String,
        isSending: Bool,
        waitingForVacancyId: Bool = false,
        onTextChanged: @escaping (String) -> Void,
        onSend: @escaping () -> Void,
        onFavoritesTapped: (() -> Void)? = nil
    ) {
        self.text = text
        self.isSending = isSending
        self.waitingForVacancyId = waitingForVacancyId
        self.onTextChanged = onTextChanged
        self.onSend = onSend
        self.onFavoritesTapped = onFavoritesTapped
    }
    
    var body: some View {
        VStack(spacing: CGFloat.zero) {
        HStack(spacing: Layout.rowSpacing) {
            if waitingForVacancyId, let onFavoritesTapped {
                Button {
                    onFavoritesTapped()
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: Layout.actionButtonSide, height: Layout.actionButtonSide)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.12))
                        )
                }
                .disabled(isSending)
            }
            
            TextField(
                waitingForVacancyId ? "Выберите вакансию" : "Сообщение",
                text: .init(
                    get: { text },
                    set: { onTextChanged($0) }
                )
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, Layout.fieldHorizontalPadding)
            .padding(.vertical, Layout.fieldVerticalPadding)
            .background(Color.fieldBackground)
            .cornerRadius(Layout.fieldCornerRadius)
            .focused($isFocused)
            .disabled(isSending)
            
            Button(action: {
                onSend()
                isFocused = true
            }, label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: Layout.actionButtonSide, height: Layout.actionButtonSide)
                    .background(
                        Circle()
                            .fill(canSend ? Color.brandPrimary : Color.gray)
                    )
            })
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, Layout.outerVerticalPadding)
        }
        .background(Color.cardBackground)
        .shadow(color: shadowColor, radius: Layout.barShadowRadius, x: .zero, y: Layout.barShadowY)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension ChatInputBar {
    enum Layout {
        static let rowSpacing: CGFloat = 12
        static let actionButtonSide: CGFloat = 40
        static let fieldHorizontalPadding: CGFloat = 16
        static let fieldVerticalPadding: CGFloat = 10
        static let fieldCornerRadius: CGFloat = 20
        static let outerVerticalPadding: CGFloat = 8
        static let barShadowRadius: CGFloat = 4
        static let barShadowY: CGFloat = -2
    }
}

#Preview {
    VStack {
        Spacer()
        
        ChatInputBar(
            text: "",
            isSending: false,
            onTextChanged: { _ in },
            onSend: {}
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
            onSend: {}
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
            onSend: {}
        )
    }
}
