public protocol VacancyServicing: Actor {
    func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy]
    func toggleFavorite(id: String) async throws -> Bool
}

public protocol FavoritesProviding: Actor {
    func fetchFavorites() async throws -> [DiscoveryState.Vacancy]
}
