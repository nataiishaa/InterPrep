//
//  MessageBubbleView.swift
//  InterPrep
//
//  Message bubble component
//

import DesignSystem
import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let onButtonTap: ((MessageButton) -> Void)?
    let isSending: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showCopiedFeedback = false
    @State private var tappedButtonId: UUID?
    
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
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.text
                            showCopiedFeedback = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedFeedback = false
                            }
                        } label: {
                            Label("Копировать", systemImage: "doc.on.doc")
                        }
                    }
                    .overlay(alignment: isUser ? .bottomTrailing : .bottomLeading) {
                        if showCopiedFeedback {
                            Text("Скопировано")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.7))
                                )
                                .offset(y: -40)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                
                if !message.buttons.isEmpty, let onButtonTap = onButtonTap {
                    VStack(spacing: 6) {
                        ForEach(message.buttons) { button in
                            Button {
                                tappedButtonId = button.id
                                onButtonTap(button)
                            } label: {
                                HStack(spacing: 8) {
                                    if isSending && tappedButtonId == button.id {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 14, height: 14)
                                    }
                                    Text(button.text)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(isSending ? .secondary : .brandPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.backgroundSecondary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            (isSending ? Color.secondary : Color.brandPrimary).opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isSending)
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
            onButtonTap: { _ in },
            isSending: false
        )
        
        MessageBubbleView(
            message: ChatMessage(
                text: "Привет! Хотел бы обсудить подготовку к интервью",
                sender: .user,
                status: .read
            ),
            onButtonTap: nil,
            isSending: false
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
            onButtonTap: { _ in },
            isSending: false
        )
    }
    .padding()
}
