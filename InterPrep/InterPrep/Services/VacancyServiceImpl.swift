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
            return response.vacancies.map { vacancy in
                DiscoveryState.Vacancy(
                    id: vacancy.id,
                    title: vacancy.title,
                    company: vacancy.company,
                    description: vacancy.description_p,
                    isFavorite: vacancy.isFavorite,
                    url: vacancy.url
                )
            }
        case .failure(let error):
            print("❌ Failed to fetch vacancies: \(error)")
            throw error
        }
    }
    
    public func toggleFavorite(id: String) async throws -> Bool {
        // Сначала получаем текущий список избранного
        let favoritesResult = await networkService.listFavorites()
        
        switch favoritesResult {
        case .success(let response):
            let isFavorite = response.vacancyIds.contains(id)
            
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
