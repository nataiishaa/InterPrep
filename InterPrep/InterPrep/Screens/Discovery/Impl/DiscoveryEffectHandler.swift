import AnalyticsService
import ArchitectureCore
import CacheService
import Foundation
import NetworkMonitorService
import NetworkService

public actor DiscoveryEffectHandler: EffectHandler {
    public typealias StateType = DiscoveryState

    private let resumeService: ResumeServicing
    private let vacancyService: VacancyServicing
    private let cacheManager = CacheManager.shared

    public init(
        resumeService: ResumeServicing,
        vacancyService: VacancyServicing
    ) {
        self.resumeService = resumeService
        self.vacancyService = vacancyService
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .checkResume:
            let hasResume = await resumeService.hasResume()
            return .resumeCheckCompleted(hasResume: hasResume)

        case let .loadVacancies(filter, searchQuery):
            if !searchQuery.isEmpty {
                var filterParams: [String: String] = [:]
                filterParams["filter"] = String(describing: filter)
                await trackEvent(.vacancySearched(query: searchQuery, filters: filterParams))
            }
            let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
            if !isConnected {
                if let cached = try? await cacheManager.load(
                    forKey: CacheKey.discoveryVacancies,
                    as: [DiscoveryState.Vacancy].self
                ) {
                    return .vacanciesLoadedFromCache(cached)
                }
                return .loadingFailed("Нет интернета. Проверьте подключение и попробуйте снова")
            }

            var lastError: Error?
            for attempt in 0..<2 {
                if attempt > 0 {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                }
                do {
                    let vacancies = try await vacancyService.fetchVacancies(filter: filter, searchQuery: searchQuery)
                    try? await cacheManager.save(vacancies, forKey: CacheKey.discoveryVacancies)
                    return .vacanciesLoaded(vacancies)
                } catch {
                    lastError = error
                    if let ne = error as? NetworkError, ne.isConnectionError, attempt == 0 {
                        continue
                    }
                    break
                }
            }
            let finalError = lastError!
            if let cached = try? await cacheManager.load(
                forKey: CacheKey.discoveryVacancies,
                as: [DiscoveryState.Vacancy].self
            ) {
                return .vacanciesLoadedFromCache(cached)
            }
            if let ne = finalError as? NetworkError, ne.isConnectionError {
                let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
                return .loadingFailed(isConnected
                    ? "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
                    : "Нет интернета. Проверьте подключение и попробуйте снова")
            }
            if let api = (finalError as? NetworkError)?.asAPIError {
                return .loadingFailed(api.userMessage)
            }
            return .loadingFailed("Не удалось загрузить вакансии")

        case let .toggleFavorite(id):
            do {
                let isFavorite = try await vacancyService.toggleFavorite(id: id)
                if isFavorite {
                    await trackEvent(.vacancyFavorited(vacancyId: id))
                } else {
                    await trackEvent(.vacancyUnfavorited(vacancyId: id))
                }
                return .favoriteToggled(id, isFavorite)
            } catch {
                if let ne = error as? NetworkError, ne.isConnectionError {
                    let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
                    return .loadingFailed(isConnected
                        ? "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
                        : "Нет интернета. Проверьте подключение и попробуйте снова")
                }
                return .loadingFailed("Не удалось обновить избранное")
            }

        case .navigateToResumeUpload:
            return nil

        case let .navigateToVacancyDetail(vacancy):
            await trackEvent(.vacancyViewed(vacancyId: vacancy.id, company: vacancy.company))
            return nil
        }
    }

    @MainActor
    private func trackEvent(_ event: AnalyticsEvent) {
        AnalyticsManager.shared.track(event)
    }
}

#if DEBUG

public final actor ResumeServiceMock: ResumeServicing {
    public init() {}

    public func hasResume() async -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return true
    }

    public func invalidateCache() async {
    }
}

public final actor VacancyServiceMock: VacancyServicing {
    public init() {}

    public func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy] {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
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
        var filteredVacancies = allVacancies
        if !searchQuery.isEmpty {
            let lowercasedQuery = searchQuery.lowercased()
            filteredVacancies = allVacancies.filter { vacancy in
                vacancy.title.lowercased().contains(lowercasedQuery) ||
                vacancy.company.lowercased().contains(lowercasedQuery) ||
                vacancy.description.lowercased().contains(lowercasedQuery)
            }
        }
        switch filter {
        case .all:
            return filteredVacancies
        case .favorites:
            return filteredVacancies.filter { $0.isFavorite }
        }
    }

    public func toggleFavorite(id: String) async throws -> Bool {
        return true
    }
}

#endif
