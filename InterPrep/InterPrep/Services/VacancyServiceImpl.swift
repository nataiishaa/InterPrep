//
//  VacancyServiceImpl.swift
//  InterPrep
//
//  Real implementation of VacancyService using NetworkServiceV2
//

import Foundation
import NetworkService
import DiscoveryModule

public final actor VacancyServiceImpl: VacancyService {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy] {
        let result = await networkService.searchJobs(page: 0, perPage: 20)
        
        switch result {
        case .success(let response):
            return response.items.map { vacancy in
                DiscoveryState.Vacancy(
                    id: vacancy.id,
                    title: vacancy.name,
                    company: vacancy.hasEmployer ? vacancy.employer.name : "Неизвестный работодатель",
                    description: vacancy.description_p,
                    isFavorite: vacancy.isFavorite,
                    url: vacancy.alternateURL.isEmpty ? nil : vacancy.alternateURL,
                    location: vacancy.hasArea ? vacancy.area.name : "Не указано",
                    salaryText: Self.salaryString(from: vacancy),
                    experienceText: vacancy.experience.isEmpty ? nil : vacancy.experience,
                    companyLogoURL: vacancy.hasEmployer && vacancy.employer.hasLogoURL && !vacancy.employer.logoURL.isEmpty ? vacancy.employer.logoURL : nil
                )
            }
        case .failure(let error):
            print("❌ Failed to fetch vacancies: \(error)")
            throw error
        }
    }
    
    private static func salaryString(from vacancy: Jobs_Vacancy) -> String? {
        guard vacancy.hasSalary else { return nil }
        let s = vacancy.salary
        let currency = s.currency.isEmpty ? "₽" : s.currency
        if s.hasFrom && s.hasTo {
            return "\(s.from) - \(s.to) \(currency)"
        }
        if s.hasFrom { return "от \(s.from) \(currency)" }
        if s.hasTo { return "до \(s.to) \(currency)" }
        return nil
    }
    
    public func toggleFavorite(id: String) async throws -> Bool {
        // Сначала получаем текущий список избранного
        let favoritesResult = await networkService.listFavorites()
        
        switch favoritesResult {
        case .success(let response):
            let isFavorite = response.vacancies.contains { $0.id == id }
            
            // Если в избранном - удаляем, иначе - добавляем
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
