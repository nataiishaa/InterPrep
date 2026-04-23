//
//  DiscoveryState.swift
//  InterPrep
//
//  Discovery screen state
//

import ArchitectureCore
import Foundation

public struct DiscoveryState {
    public var selectedFilter: FilterType = .all
    public var isLoading = false
    public var hasResume = false 
    public var vacancies: [Vacancy] = []
    public var selectedVacancy: Vacancy?
    public var searchQuery: String = ""
    
    public init() {}
    
    public enum FilterType: Sendable {
        case all
        case favorites
    }
}

extension DiscoveryState {
    public struct Vacancy: Identifiable, Equatable, Hashable, Sendable {
        public let id: String
        public let title: String
        public let company: String
        public let description: String
        public let isFavorite: Bool
        public let url: String?
        public let location: String
        public let salaryText: String?
        public let experienceText: String?
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

extension DiscoveryState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case filterChanged(FilterType)
        case uploadResumeTapped
        case vacancyTapped(Vacancy)
        case toggleFavorite(String)
        case searchQueryChanged(String)
        case searchSubmitted
    }
    
    public enum Feedback: Sendable {
        case vacanciesLoaded([Vacancy])
        case loadingFailed(String)
        case favoriteToggled(String, Bool)
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
            if hasResume {
                state.isLoading = true
                return .loadVacancies(state.selectedFilter, searchQuery: state.searchQuery)
            } else {
                state.isLoading = false
            }
            
        case let .feedback(.vacanciesLoaded(vacancies)):
            state.isLoading = false
            state.vacancies = vacancies
            
        case let .feedback(.loadingFailed(error)):
            state.isLoading = false
            
        case let .feedback(.favoriteToggled(id, isFavorite)):
            if let index = state.vacancies.firstIndex(where: { $0.id == id }) {
                let vacancy = state.vacancies[index]
                state.vacancies[index] = Vacancy(
                    id: vacancy.id,
                    title: vacancy.title,
                    company: vacancy.company,
                    description: vacancy.description,
                    isFavorite: isFavorite,
                    url: vacancy.url,
                    location: vacancy.location,
                    salaryText: vacancy.salaryText,
                    experienceText: vacancy.experienceText,
                    companyLogoURL: vacancy.companyLogoURL
                )
            }
            
            if state.selectedFilter == .favorites {
                state.isLoading = true
                return .loadVacancies(.favorites, searchQuery: state.searchQuery)
            }
        }
        
        return nil
    }
}
