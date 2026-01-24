//
//  MessageBubbleView.swift
//  InterPrep
//
//  Message bubble component
//

import SwiftUI
import DesignSystem

struct MessageBubbleView: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    private var isUser: Bool {
        message.sender == .user
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isUser ? .white : .textOnBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isUser ? Color.brandPrimary : bubbleBackgroundColor)
                    )
                
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isUser {
                        statusIcon
                    }
                }
            }
            
            if !isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 12, height: 12)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .delivered:
            Image(systemName: "checkmark.circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.blue)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }
    
    private var bubbleBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(.systemGray5)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(
            message: ChatMessage(
                text: "Здравствуйте! Я ваш карьерный консультант.",
                sender: .consultant,
                status: .read
            )
        )
        
        MessageBubbleView(
            message: ChatMessage(
                text: "Привет! Хотел бы обсудить подготовку к интервью",
                sender: .user,
                status: .read
            )
        )
        
        MessageBubbleView(
            message: ChatMessage(
                text: "Отправляю сообщение...",
                sender: .user,
                status: .sending
            )
        )
    }
    .padding()
}
