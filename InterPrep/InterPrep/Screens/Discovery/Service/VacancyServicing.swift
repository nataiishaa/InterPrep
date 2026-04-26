//
//  VacancyServicing.swift
//  InterPrep
//
//  Created by Наталья Захарова on 26/4/2026.
//

public protocol VacancyServicing: Actor {
    func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy]
    func toggleFavorite(id: String) async throws -> Bool
}
