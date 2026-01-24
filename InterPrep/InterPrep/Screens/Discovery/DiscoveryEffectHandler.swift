//
//  DiscoveryEffectHandler.swift
//  InterPrep
//
//  Discovery effect handler
//

import Foundation
import ArchitectureCore

public actor DiscoveryEffectHandler: EffectHandler {
    public typealias S = DiscoveryState
    
    private let resumeService: ResumeService
    private let vacancyService: VacancyService
    
    public init(
        resumeService: ResumeService,
        vacancyService: VacancyService
    ) {
        self.resumeService = resumeService
        self.vacancyService = vacancyService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case .checkResume:
            let hasResume = await resumeService.hasResume()
            return .resumeCheckCompleted(hasResume: hasResume)
            
        case let .loadVacancies(filter, searchQuery):
            do {
                let vacancies = try await vacancyService.fetchVacancies(filter: filter, searchQuery: searchQuery)
                return .vacanciesLoaded(vacancies)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case let .toggleFavorite(id):
            do {
                let isFavorite = try await vacancyService.toggleFavorite(id: id)
                return .favoriteToggled(id, isFavorite)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .navigateToResumeUpload,
             .navigateToVacancyDetail:
            // Navigation handled by coordinator/navigation store
            return nil
        }
    }
}

// MARK: - Services

public protocol ResumeService: Actor {
    func hasResume() async -> Bool
}

public protocol VacancyService: Actor {
    func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy]
    func toggleFavorite(id: String) async throws -> Bool
}

// MARK: - Mock Services

public final actor ResumeServiceMock: ResumeService {
    public init() {}
    
    public func hasResume() async -> Bool {
        // Имитируем задержку
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        return true  // Резюме есть - покажем вакансии
    }
}

public final actor VacancyServiceMock: VacancyService {
    public init() {}
    
    public func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy] {
        // Имитируем задержку
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        
        // Моковые вакансии с реальными URL
        let allVacancies: [DiscoveryState.Vacancy] = [
            .init(
                id: "1",
                title: "AI-разработчик (Python / Go / PHP / Frontend)",
                company: "СП Солюшен",
                description: "Мы создаем экосистему сервисов и AI-продуктов. Ищем разработчика, который работает с ИИ.",
                isFavorite: true,
                url: "https://hh.ru/vacancy/129381806?query=go+разработчик&hhtmFrom=vacancy_search_list"
            ),
            .init(
                id: "2",
                title: "Node.js Backend Developer",
                company: "evrone.ru",
                description: "Разработка и поддержка высоконагруженных RESTful API. Node.js, Express.js/Nest.js, PostgreSQL, MongoDB.",
                isFavorite: false,
                url: "https://hh.ru/vacancy/129724881?query=go+разработчик&hhtmFrom=vacancy_search_list"
            ),
            .init(
                id: "3",
                title: "Go-разработчик (EDR)",
                company: "Positive Technologies",
                description: "Разработка новых модулей и сервисов на GO. Участие в проектировании масштабируемой архитектуры.",
                isFavorite: false,
                url: "https://hh.ru/vacancy/129798013?query=go+разработчик&hhtmFrom=vacancy_search_list"
            ),
            .init(
                id: "4",
                title: "Senior iOS Developer",
                company: "Авито",
                description: "Ищем опытного iOS разработчика в команду. SwiftUI, Combine, архитектура приложений.",
                isFavorite: false,
                url: "https://hh.ru/search/vacancy?text=Senior+iOS+Developer+Авито&area=1"
            ),
            .init(
                id: "5",
                title: "Middle iOS Developer",
                company: "Сбер",
                description: "Разработка банковских приложений. Swift, UIKit, CoreData. Удаленная работа.",
                isFavorite: true,
                url: "https://hh.ru/search/vacancy?text=Middle+iOS+Developer+Сбер&area=1"
            ),
            .init(
                id: "6",
                title: "iOS Developer",
                company: "ВКонтакте",
                description: "Работа над социальной сетью. Swift, SwiftUI, GraphQL. Офис в Москве.",
                isFavorite: false,
                url: "https://hh.ru/search/vacancy?text=iOS+Developer+ВКонтакте&area=1"
            ),
            .init(
                id: "7",
                title: "Lead iOS Developer",
                company: "Тинькофф",
                description: "Руководство командой iOS разработки. Архитектура, менторинг, код-ревью.",
                isFavorite: false,
                url: "https://hh.ru/search/vacancy?text=Lead+iOS+Developer+Тинькофф&area=1"
            )
        ]
        
        // Фильтруем по поисковому запросу
        var filteredVacancies = allVacancies
        if !searchQuery.isEmpty {
            let lowercasedQuery = searchQuery.lowercased()
            filteredVacancies = allVacancies.filter { vacancy in
                vacancy.title.lowercased().contains(lowercasedQuery) ||
                vacancy.company.lowercased().contains(lowercasedQuery) ||
                vacancy.description.lowercased().contains(lowercasedQuery)
            }
        }
        
        // Фильтруем по избранному если нужно
        switch filter {
        case .all:
            return filteredVacancies
        case .favorites:
            return filteredVacancies.filter { $0.isFavorite }
        }
    }
    
    public func toggleFavorite(id: String) async throws -> Bool {
        // Mock: просто переключаем
        return true
    }
}
