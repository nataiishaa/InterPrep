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
        VStack(spacing: Layout.stackSpacing) {
            ForEach(buttons) { button in
                Button {
                    onTap(button)
                } label: {
                    Text(button.text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Layout.buttonVerticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                                .fill(Color.backgroundSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: Layout.buttonStrokeWidth)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension MessageButtonsView {
    enum Layout {
        static let stackSpacing: CGFloat = 8
        static let buttonVerticalPadding: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 8
        static let buttonStrokeWidth: CGFloat = 1
        static let previewOuterSpacing: CGFloat = 20
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: MessageButtonsView.Layout.previewOuterSpacing) {
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
