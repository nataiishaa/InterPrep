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
        switch filter {
        case .favorites:
            print("🔍 Fetching favorites list...")
            let result = await networkService.listFavorites()
            switch result {
            case .success(let response):
                print("✅ ListFavorites response received:")
                print("   - Total vacancies: \(response.vacancies.count)")
                if response.vacancies.isEmpty {
                    print("   ⚠️ Response is empty! No favorites found on backend.")
                } else {
                    print("   - Vacancy IDs: \(response.vacancies.map { $0.id })")
                    print("   - Vacancy titles: \(response.vacancies.map { $0.name })")
                }
                var list = response.vacancies.map { mapVacancy($0, isFavorite: true) }
                if !searchQuery.isEmpty {
                    let q = searchQuery.lowercased()
                    list = list.filter {
                        $0.title.lowercased().contains(q) ||
                        $0.company.lowercased().contains(q) ||
                        $0.description.lowercased().contains(q)
                    }
                }
                print("   - Returning \(list.count) vacancies after filtering")
                return list
            case .failure(let error):
                print("❌ Failed to fetch favorites: \(error)")
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
                print("❌ Failed to fetch vacancies: \(error)")
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
        print("🔄 Toggle favorite for vacancy: \(id)")
        
        // Сначала получаем текущий список избранного
        let favoritesResult = await networkService.listFavorites()
        
        switch favoritesResult {
        case .success(let response):
            let isFavorite = response.vacancies.contains { $0.id == id }
            print("   - Current favorites count: \(response.vacancies.count)")
            print("   - Is currently favorite: \(isFavorite)")
            
            // Если в избранном - удаляем, иначе - добавляем
            if isFavorite {
                print("   - Removing from favorites...")
                let result = await networkService.removeFavorite(vacancyId: id)
                switch result {
                case .success(let removeResponse):
                    print("   ✅ Successfully removed from favorites. Success: \(removeResponse.success)")
                    return false
                case .failure(let error):
                    print("   ❌ Failed to remove from favorites: \(error)")
                    throw error
                }
            } else {
                print("   - Adding to favorites...")
                let result = await networkService.addFavorite(vacancyId: id)
                switch result {
                case .success(let addResponse):
                    print("   ✅ Successfully added to favorites. Success: \(addResponse.success)")
                    return true
                case .failure(let error):
                    print("   ❌ Failed to add to favorites: \(error)")
                    throw error
                }
            }
        case .failure(let error):
            print("   ❌ Failed to get favorites list: \(error)")
            throw error
        }
    }
}
