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
    let onButtonTap: ((MessageButton) -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    private var isUser: Bool {
        message.sender == .user
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isUser ? .white : .textOnBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isUser ? Color.brandPrimary : bubbleBackgroundColor)
                    )
                
                if !message.buttons.isEmpty, let onButtonTap = onButtonTap {
                    VStack(spacing: 6) {
                        ForEach(message.buttons) { button in
                            Button {
                                onButtonTap(button)
                            } label: {
                                Text(button.text)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.brandPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.backgroundSecondary)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 280)
                }
                
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

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(
            message: ChatMessage(
                text: "Здравствуйте! Я карьерный консультант, чем могу помочь?",
                sender: .consultant,
                status: .read,
                buttons: [
                    MessageButton(text: "Помощь в подготовке к собеседованию", action: .selectScenario(.interviewPrep)),
                    MessageButton(text: "Консультация по резюме", action: .selectScenario(.resumeConsultation)),
                    MessageButton(text: "Другое", action: .selectScenario(.other))
                ]
            ),
            onButtonTap: { _ in }
        )
        
        MessageBubbleView(
            message: ChatMessage(
                text: "Привет! Хотел бы обсудить подготовку к интервью",
                sender: .user,
                status: .read
            ),
            onButtonTap: nil
        )
        
        MessageBubbleView(
            message: ChatMessage(
                text: "Хочешь получить независимую оценку своего резюме?",
                sender: .consultant,
                status: .read,
                buttons: [
                    MessageButton(text: "Да", action: .confirmYes),
                    MessageButton(text: "Нет", action: .confirmNo)
                ]
            ),
            onButtonTap: { _ in }
        )
    }
    .padding()
}
