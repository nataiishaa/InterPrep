//
//  ChatInputBar.swift
//  InterPrep
//
//  Chat input bar component
//

import SwiftUI
import DesignSystem

struct ChatInputBar: View {
    let text: String
    let isSending: Bool
    let onTextChanged: (String) -> Void
    let onSend: () -> Void
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Сообщение", text: .init(
                get: { text },
                set: { onTextChanged($0) }
            ))
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.fieldBackground)
            .cornerRadius(20)
            .focused($isFocused)
            .disabled(isSending)
            
            // Send button
            Button(action: {
                onSend()
                isFocused = true
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(canSend ? Color.brandPrimary : Color.gray)
                    )
            }
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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

// MARK: - Preview

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
