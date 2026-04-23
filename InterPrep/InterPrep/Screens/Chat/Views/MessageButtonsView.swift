//
//  MessageButtonsView.swift
//  InterPrep
//
//  Inline buttons under messages (Telegram style)
//

import DesignSystem
import SwiftUI

struct MessageButtonsView: View {
    let buttons: [MessageButton]
    let onTap: (MessageButton) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons) { button in
                Button {
                    onTap(button)
                } label: {
                    Text(button.text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MessageButtonsView(
            buttons: [
                MessageButton(text: "Помощь в подготовке к собеседованию", action: .selectScenario(.interviewPrep)),
                MessageButton(text: "Консультация по резюме", action: .selectScenario(.resumeConsultation)),
                MessageButton(text: "Другое", action: .selectScenario(.other))
            ],
            onTap: { _ in }
        )
        .padding()
        
        MessageButtonsView(
            buttons: [
                MessageButton(text: "Да", action: .confirmYes),
                MessageButton(text: "Нет", action: .confirmNo)
            ],
            onTap: { _ in }
        )
        .padding()
    }
}
