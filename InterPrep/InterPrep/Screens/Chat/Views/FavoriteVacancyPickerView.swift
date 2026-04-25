//
//  FavoriteVacancyPickerView.swift
//  InterPrep
//
//  Inline picker for selecting a favorite vacancy in chat
//

import DesignSystem
import DiscoveryModule
import SwiftUI

struct FavoriteVacancyPickerView: View {
    let vacancies: [DiscoveryState.Vacancy]
    let isLoading: Bool
    let onSelect: (DiscoveryState.Vacancy) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.brandPrimary)
                    .font(.subheadline)
                Text("Избранные вакансии")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 24)
                    Spacer()
                }
            } else if vacancies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark.slash")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Нет избранных вакансий")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Добавьте вакансии в избранное на вкладке «Вакансии»")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vacancies) { vacancy in
                            Button {
                                onSelect(vacancy)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(vacancy.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            Text(vacancy.company)
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer(minLength: 4)
                                        Text("Подготовиться")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.brandPrimary)
                                            .cornerRadius(12)
                                    }

                                    HStack(spacing: 12) {
                                        if let salary = vacancy.salaryText, !salary.isEmpty {
                                            Label(salary, systemImage: "banknote")
                                                .font(.caption2)
                                                .foregroundColor(.primary.opacity(0.8))
                                        }
                                        if !vacancy.location.isEmpty {
                                            Label(vacancy.location, systemImage: "mappin.and.ellipse")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        if let experience = vacancy.experienceText, !experience.isEmpty {
                                            Label(experience, systemImage: "briefcase")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .lineLimit(1)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
        .padding(.horizontal, 12)
    }
}

#Preview {
    VStack {
        Spacer()
        FavoriteVacancyPickerView(
            vacancies: [
                .init(id: "1", title: "iOS Developer", company: "Авито", description: "", isFavorite: true, location: "Москва", salaryText: "250 000 – 350 000 ₽", experienceText: "3–6 лет"),
                .init(id: "2", title: "Senior Go Developer", company: "Яндекс", description: "", isFavorite: true, location: "Удалённо", salaryText: "300 000 – 500 000 ₽"),
                .init(id: "3", title: "Frontend React Developer", company: "Тинькофф", description: "", isFavorite: true, location: "Санкт-Петербург", experienceText: "1–3 года")
            ],
            isLoading: false,
            onSelect: { _ in },
            onDismiss: {}
        )
    }
}
