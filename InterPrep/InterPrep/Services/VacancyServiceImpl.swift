//
//  VacancyServiceImpl.swift
//  InterPrep
//
//  Real implementation of VacancyService using NetworkServiceV2
//

import ChatFeature
import DiscoveryModule
import Foundation
import NetworkService

public final actor VacancyServiceImpl: VacancyService, FavoritesProviding {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy] {
        switch filter {
        case .favorites:
            let result = await networkService.listFavorites()
            switch result {
            case .success(let response):
                var list = response.vacancies.map { mapVacancy($0, isFavorite: true) }
                if !searchQuery.isEmpty {
                    let query = searchQuery.lowercased()
                    list = list.filter {
                        $0.title.lowercased().contains(query) ||
                        $0.company.lowercased().contains(query) ||
                        $0.description.lowercased().contains(query)
                    }
                }
                return list
            case .failure(let error):
                throw error
            }
        case .all:
            let result = await networkService.searchJobs(page: 0, perPage: 20)
            switch result {
            case .success(let response):
                return response.items.map { vacancy in
                    mapVacancy(vacancy, isFavorite: vacancy.isFavorite)
                }
            case .failure(let error):
                throw error
            }
        }
    }

    private func mapVacancy(_ vacancy: Jobs_Vacancy, isFavorite: Bool) -> DiscoveryState.Vacancy {
        DiscoveryState.Vacancy(
            id: vacancy.id,
            title: vacancy.name,
            company: vacancy.hasEmployer ? vacancy.employer.name : "Неизвестный работодатель",
            description: vacancy.description_p,
            isFavorite: isFavorite,
            url: vacancy.alternateURL.isEmpty ? nil : vacancy.alternateURL,
            location: vacancy.hasArea ? vacancy.area.name : "Не указано",
            salaryText: Self.salaryString(from: vacancy),
            experienceText: vacancy.experience.isEmpty ? nil : vacancy.experience,
            companyLogoURL: vacancy.hasEmployer && vacancy.employer.hasLogoURL && !vacancy.employer.logoURL.isEmpty ? vacancy.employer.logoURL : nil
        )
    }
    
    private static func salaryString(from vacancy: Jobs_Vacancy) -> String? {
        guard vacancy.hasSalary else { return nil }
        let salary = vacancy.salary
        let currency = salary.currency.isEmpty ? "₽" : salary.currency
        if salary.hasFrom && salary.hasTo {
            return "\(salary.from) - \(salary.to) \(currency)"
        }
        if salary.hasFrom { return "от \(salary.from) \(currency)" }
        if salary.hasTo { return "до \(salary.to) \(currency)" }
        return nil
    }
    
    public func fetchFavorites() async throws -> [DiscoveryState.Vacancy] {
        try await fetchVacancies(filter: .favorites, searchQuery: "")
    }
    
    public func toggleFavorite(id: String) async throws -> Bool {
        let favoritesResult = await networkService.listFavorites()
        
        switch favoritesResult {
        case .success(let response):
            let isFavorite = response.vacancies.contains { $0.id == id }
            if isFavorite {
                let result = await networkService.removeFavorite(vacancyId: id)
                switch result {
                case .success:
                    return false
                case .failure(let error):
                    throw error
                }
            } else {
                let result = await networkService.addFavorite(vacancyId: id)
                switch result {
                case .success:
                    return true
                case .failure(let error):
                    throw error
                }
            }
        case .failure(let error):
            throw error
        }
    }
}
