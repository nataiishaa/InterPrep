import DiscoveryModule
import Foundation
import NetworkService

public final actor VacancyService: VacancyServicing, FavoritesProviding {
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
                    list = filterVacancies(list, by: searchQuery)
                }
                return list
            case .failure(let error):
                throw error
            }
        case .all:
            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedQuery.isEmpty {
                let result = await networkService.searchJobs(page: 0, perPage: 50)
                switch result {
                case .success(let response):
                    return response.items.map { mapVacancy($0, isFavorite: $0.isFavorite) }
                case .failure(let error):
                    throw error
                }
            }
            return try await fetchVacanciesAcrossPagesWithLocalFilter(query: trimmedQuery)
        }
    }

    private func fetchVacanciesAcrossPagesWithLocalFilter(query: String) async throws -> [DiscoveryState.Vacancy] {
        let tokens = Self.searchTokens(from: query)
        guard !tokens.isEmpty else {
            let result = await networkService.searchJobs(page: 0, perPage: 50)
            switch result {
            case .success(let response):
                return response.items.map { mapVacancy($0, isFavorite: $0.isFavorite) }
            case .failure(let error):
                throw error
            }
        }

        let perPage = 50
        let maxPagesHardCap = 25
        let targetMatchCount = 50
        var byId: [String: DiscoveryState.Vacancy] = [:]
        var totalPagesKnown: Int?
        var page = 0

        while page < maxPagesHardCap {
            if let total = totalPagesKnown, page >= total { break }

            let result = await networkService.searchJobs(page: page, perPage: perPage)
            switch result {
            case .success(let response):
                if totalPagesKnown == nil, response.pages > 0 {
                    totalPagesKnown = Int(response.pages)
                }
                if response.items.isEmpty { break }

                for item in response.items {
                    let mapped = mapVacancy(item, isFavorite: item.isFavorite)
                    byId[mapped.id] = mapped
                }

                let filteredCount = byId.values.filter { Self.matchesSearchTokens($0, tokens: tokens) }.count
                if filteredCount >= targetMatchCount { break }

                page += 1

            case .failure(let error):
                throw error
            }
        }

        let filtered = byId.values.filter { Self.matchesSearchTokens($0, tokens: tokens) }
        return filtered.sorted { lhs, rhs in
            let order = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
            if order != .orderedSame { return order == .orderedAscending }
            return lhs.id < rhs.id
        }
    }

    private static func searchTokens(from query: String) -> [String] {
        query
            .lowercased()
            .split { $0.isWhitespace || $0.isNewline }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static func vacancyHaystack(_ vacancy: DiscoveryState.Vacancy) -> String {
        [
            vacancy.title,
            vacancy.company,
            vacancy.description,
            vacancy.location,
            vacancy.experienceText ?? "",
            vacancy.salaryText ?? ""
        ].joined(separator: "\n").lowercased()
    }

    private static func matchesSearchTokens(_ vacancy: DiscoveryState.Vacancy, tokens: [String]) -> Bool {
        let haystack = vacancyHaystack(vacancy)
        return tokens.allSatisfy { haystack.contains($0) }
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

    private func filterVacancies(_ vacancies: [DiscoveryState.Vacancy], by searchQuery: String) -> [DiscoveryState.Vacancy] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return vacancies }
        let tokens = Self.searchTokens(from: trimmed)
        guard !tokens.isEmpty else { return vacancies }
        return vacancies.filter { Self.matchesSearchTokens($0, tokens: tokens) }
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
