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
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(vacancy.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Text(vacancy.company)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .frame(maxHeight: 200)
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
                .init(id: "1", title: "iOS Developer", company: "Авито", description: "", isFavorite: true),
                .init(id: "2", title: "Senior Go Developer", company: "Яндекс", description: "", isFavorite: true),
                .init(id: "3", title: "Frontend React Developer", company: "Тинькофф", description: "", isFavorite: true)
            ],
            isLoading: false,
            onSelect: { _ in },
            onDismiss: {}
        )
    }
}
