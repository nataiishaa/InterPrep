//
//  DiscoveryState.swift
//  InterPrep
//
//  Discovery screen state
//

import Foundation
import ArchitectureCore

public struct DiscoveryState {
    public var selectedFilter: FilterType = .all
    public var isLoading = false
    public var hasResume = false 
    public var vacancies: [Vacancy] = []
    public var selectedVacancy: Vacancy? = nil
    public var searchQuery: String = ""
    
    public init() {}
    
    public enum FilterType: Sendable {
        case all
        case favorites
    }
}

// MARK: - Models

extension DiscoveryState {
    public struct Vacancy: Identifiable, Equatable, Hashable, Sendable {
        public let id: String
        public let title: String
        public let company: String
        public let description: String
        public let isFavorite: Bool
        public let url: String? // URL вакансии на hh.ru
        /// Локация (город/регион)
        public let location: String
        /// Зарплата в виде строки, например "100 000 - 150 000 ₽"
        public let salaryText: String?
        /// Опыт, например "От 1 года до 3 лет"
        public let experienceText: String?
        /// URL логотипа работодателя
        public let companyLogoURL: String?
        
        public init(
            id: String,
            title: String,
            company: String,
            description: String,
            isFavorite: Bool,
            url: String? = nil,
            location: String = "",
            salaryText: String? = nil,
            experienceText: String? = nil,
            companyLogoURL: String? = nil
        ) {
            self.id = id
            self.title = title
            self.company = company
            self.description = description
            self.isFavorite = isFavorite
            self.url = url
            self.location = location
            self.salaryText = salaryText
            self.experienceText = experienceText
            self.companyLogoURL = companyLogoURL
        }
    }
}

// MARK: - FeatureState

extension DiscoveryState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case filterChanged(FilterType)
        case uploadResumeTapped
        case vacancyTapped(Vacancy)
        case toggleFavorite(String) // vacancy ID
        case searchQueryChanged(String)
        case searchSubmitted
    }
    
    public enum Feedback: Sendable {
        case vacanciesLoaded([Vacancy])
        case loadingFailed(String)
        case favoriteToggled(String, Bool) // ID, isFavorite
        case resumeCheckCompleted(hasResume: Bool)
    }
    
    public enum Effect: Sendable {
        case checkResume
        case loadVacancies(FilterType, searchQuery: String)
        case navigateToResumeUpload
        case navigateToVacancyDetail(Vacancy)
        case toggleFavorite(String)
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.onAppear):
            state.isLoading = true
            return .checkResume
            
        case let .input(.filterChanged(filter)):
            state.selectedFilter = filter
            state.isLoading = true
            return .loadVacancies(filter, searchQuery: state.searchQuery)
            
        case .input(.uploadResumeTapped):
            return .navigateToResumeUpload
            
        case let .input(.vacancyTapped(vacancy)):
            state.selectedVacancy = vacancy
            return .navigateToVacancyDetail(vacancy)
            
        case let .input(.toggleFavorite(id)):
            return .toggleFavorite(id)
            
        case let .input(.searchQueryChanged(query)):
            state.searchQuery = query
            
        case .input(.searchSubmitted):
            state.isLoading = true
            return .loadVacancies(state.selectedFilter, searchQuery: state.searchQuery)
            
        case let .feedback(.resumeCheckCompleted(hasResume)):
            state.hasResume = hasResume
            state.isLoading = true
            return .loadVacancies(state.selectedFilter, searchQuery: state.searchQuery)
            
        case let .feedback(.vacanciesLoaded(vacancies)):
            state.isLoading = false
            state.vacancies = vacancies
            
        case let .feedback(.loadingFailed(error)):
            state.isLoading = false
            // TODO: Handle error
            
        case let .feedback(.favoriteToggled(id, isFavorite)):
            if let index = state.vacancies.firstIndex(where: { $0.id == id }) {
                let v = state.vacancies[index]
                state.vacancies[index] = Vacancy(
                    id: v.id,
                    title: v.title,
                    company: v.company,
                    description: v.description,
                    isFavorite: isFavorite,
                    url: v.url,
                    location: v.location,
                    salaryText: v.salaryText,
                    experienceText: v.experienceText,
                    companyLogoURL: v.companyLogoURL
                )
            }
            
            // Если мы в фильтре "Избранное", перезагружаем список
            if state.selectedFilter == .favorites {
                state.isLoading = true
                return .loadVacancies(.favorites, searchQuery: state.searchQuery)
            }
        }
        
        return nil
    }
}
