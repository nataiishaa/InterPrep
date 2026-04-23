//
//  ChatWelcomeView.swift
//  InterPrep
//
//  Onboarding card explaining chat capabilities
//

import DesignSystem
import SwiftUI

struct ChatWelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.brandPrimary)
                Text("Чем может помочь консультант")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                capabilityRow(
                    icon: "person.fill.questionmark",
                    title: "Подготовка к собеседованию",
                    subtitle: "Укажите вакансию — получите персональные рекомендации и вопросы"
                )
                capabilityRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Анализ резюме",
                    subtitle: "Оценка вашего резюме с конкретными рекомендациями по улучшению"
                )
                capabilityRow(
                    icon: "bookmark.fill",
                    title: "Избранные вакансии",
                    subtitle: "Выбирайте вакансии прямо из избранного — не нужно копировать ID"
                )
                capabilityRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Свободный диалог",
                    subtitle: "Задавайте любые вопросы о карьере, резюме и собеседованиях"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundSecondary)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private func capabilityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.brandPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ChatWelcomeView()
        .padding()
}
