//
//  DiscoveryView+Model.swift
//  InterPrep
//
//  Discovery view model
//

import Foundation

extension DiscoveryView {
    public struct Model {
        public let selectedFilter: DiscoveryState.FilterType
        public let hasResume: Bool
        public let isLoading: Bool
        public let vacancies: [DiscoveryState.Vacancy]
        public let searchQuery: String
        public let onFilterChanged: (DiscoveryState.FilterType) -> Void
        public let onUploadResume: () -> Void
        public let onVacancyTap: (DiscoveryState.Vacancy) -> Void
        public let onToggleFavorite: (String) -> Void
        public let onSearchQueryChanged: (String) -> Void
        public let onSearchSubmitted: () -> Void
        
        public init(
            selectedFilter: DiscoveryState.FilterType,
            hasResume: Bool,
            isLoading: Bool,
            vacancies: [DiscoveryState.Vacancy],
            searchQuery: String,
            onFilterChanged: @escaping (DiscoveryState.FilterType) -> Void,
            onUploadResume: @escaping () -> Void,
            onVacancyTap: @escaping (DiscoveryState.Vacancy) -> Void,
            onToggleFavorite: @escaping (String) -> Void,
            onSearchQueryChanged: @escaping (String) -> Void,
            onSearchSubmitted: @escaping () -> Void
        ) {
            self.selectedFilter = selectedFilter
            self.hasResume = hasResume
            self.isLoading = isLoading
            self.vacancies = vacancies
            self.searchQuery = searchQuery
            self.onFilterChanged = onFilterChanged
            self.onUploadResume = onUploadResume
            self.onVacancyTap = onVacancyTap
            self.onToggleFavorite = onToggleFavorite
            self.onSearchQueryChanged = onSearchQueryChanged
            self.onSearchSubmitted = onSearchSubmitted
        }
    }
}

#if DEBUG
extension DiscoveryView.Model {
    public static func fixture(
        selectedFilter: DiscoveryState.FilterType = .all,
        hasResume: Bool = false,
        isLoading: Bool = false,
        vacancies: [DiscoveryState.Vacancy] = [],
        searchQuery: String = "",
        onFilterChanged: @escaping (DiscoveryState.FilterType) -> Void = { _ in },
        onUploadResume: @escaping () -> Void = {},
        onVacancyTap: @escaping (DiscoveryState.Vacancy) -> Void = { _ in },
        onToggleFavorite: @escaping (String) -> Void = { _ in },
        onSearchQueryChanged: @escaping (String) -> Void = { _ in },
        onSearchSubmitted: @escaping () -> Void = {}
    ) -> Self {
        .init(
            selectedFilter: selectedFilter,
            hasResume: hasResume,
            isLoading: isLoading,
            vacancies: vacancies,
            searchQuery: searchQuery,
            onFilterChanged: onFilterChanged,
            onUploadResume: onUploadResume,
            onVacancyTap: onVacancyTap,
            onToggleFavorite: onToggleFavorite,
            onSearchQueryChanged: onSearchQueryChanged,
            onSearchSubmitted: onSearchSubmitted
        )
    }
    
    public static var noResume: Self {
        .fixture(hasResume: false)
    }
    
    public static var loading: Self {
        .fixture(hasResume: true, isLoading: true)
    }
    
    public static var empty: Self {
        .fixture(hasResume: true, isLoading: false, vacancies: [])
    }
    
    public static var withVacancies: Self {
        .fixture(
            hasResume: true,
            vacancies: [
                .init(id: "1", title: "iOS Developer", company: "Yandex", description: "...", isFavorite: false, url: "https://hh.ru/vacancy/123456"),
                .init(id: "2", title: "Swift Developer", company: "Авито", description: "...", isFavorite: true, url: "https://hh.ru/vacancy/789012")
            ]
        )
    }
}
#endif
