//
//  DiscoveryStoreTests.swift
//  DiscoveryFeatureTests
//
//  Integration tests for DiscoveryStore (State + EffectHandler full cycle)
//

import ArchitectureCore
import CacheService
@testable import DiscoveryModule
import XCTest

// MARK: - Spies

private actor SpyResumeService: ResumeServicing {
    var hasResumeResult: Bool = true
    var hasResumeCallCount = 0
    var invalidateCacheCallCount = 0

    func hasResume() async -> Bool {
        hasResumeCallCount += 1
        return hasResumeResult
    }

    func invalidateCache() async {
        invalidateCacheCallCount += 1
    }

    func setHasResumeResult(_ value: Bool) { hasResumeResult = value }
}

private actor SpyVacancyService: VacancyServicing {
    var fetchVacanciesResult: Result<[DiscoveryState.Vacancy], Error> = .success([])
    var toggleFavoriteResult: Result<Bool, Error> = .success(true)

    var fetchVacanciesCallCount = 0
    var toggleFavoriteCallCount = 0
    var lastToggleFavoriteId: String?
    var lastFetchFilter: DiscoveryState.FilterType?
    var lastFetchSearchQuery: String?

    func fetchVacancies(filter: DiscoveryState.FilterType, searchQuery: String) async throws -> [DiscoveryState.Vacancy] {
        fetchVacanciesCallCount += 1
        lastFetchFilter = filter
        lastFetchSearchQuery = searchQuery
        switch fetchVacanciesResult {
        case .success(let vacancies): return vacancies
        case .failure(let error): throw error
        }
    }

    func toggleFavorite(id: String) async throws -> Bool {
        toggleFavoriteCallCount += 1
        lastToggleFavoriteId = id
        switch toggleFavoriteResult {
        case .success(let isFavorite): return isFavorite
        case .failure(let error): throw error
        }
    }

    func setFetchVacanciesResult(_ result: Result<[DiscoveryState.Vacancy], Error>) { fetchVacanciesResult = result }
    func setToggleFavoriteResult(_ result: Result<Bool, Error>) { toggleFavoriteResult = result }
}

private enum TestError: LocalizedError {
    case network
    var errorDescription: String? { "Network error" }
}

// MARK: - Helpers

private let sampleVacancies: [DiscoveryState.Vacancy] = [
    .init(id: "1", title: "iOS Developer", company: "Яндекс", description: "SwiftUI", isFavorite: false),
    .init(id: "2", title: "Backend Developer", company: "Сбер", description: "Go", isFavorite: true)
]

// MARK: - Tests

@MainActor
final class DiscoveryStoreTests: XCTestCase {
    private var resumeService: SpyResumeService!
    private var vacancyService: SpyVacancyService!
    private var store: DiscoveryStore!

    override func setUp() async throws {
        try await super.setUp()
        try? await CacheManager.shared.clearAll()
        resumeService = SpyResumeService()
        vacancyService = SpyVacancyService()
        store = DiscoveryStore(
            state: DiscoveryState(),
            effectHandler: DiscoveryEffectHandler(
                resumeService: resumeService,
                vacancyService: vacancyService
            )
        )
    }

    override func tearDown() {
        store = nil
        vacancyService = nil
        resumeService = nil
        super.tearDown()
    }

    /// Longer sleep to accommodate effect chains (checkResume → loadVacancies).
    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 150_000_000)
        await Task.yield()
    }

    // MARK: - onAppear (effect chain: checkResume → loadVacancies)

    func test_onAppear_hasResume_loadsVacancies() async {
        await resumeService.setHasResumeResult(true)
        await vacancyService.setFetchVacanciesResult(.success(sampleVacancies))

        store.send(.onAppear)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()
        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertTrue(store.state.hasResume)
        XCTAssertEqual(store.state.vacancies.count, 2)
        XCTAssertEqual(store.state.vacancies.first?.title, "iOS Developer")

        let resumeCalls = await resumeService.hasResumeCallCount
        XCTAssertEqual(resumeCalls, 1)
        let fetchCalls = await vacancyService.fetchVacanciesCallCount
        XCTAssertEqual(fetchCalls, 1)
    }

    func test_onAppear_noResume_stopsAfterResumeCheck() async {
        await resumeService.setHasResumeResult(false)

        store.send(.onAppear)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertFalse(store.state.hasResume)
        XCTAssertTrue(store.state.vacancies.isEmpty)

        let fetchCalls = await vacancyService.fetchVacanciesCallCount
        XCTAssertEqual(fetchCalls, 0, "loadVacancies should not be called when hasResume is false")
    }

    func test_onAppear_vacancyLoadFailure_showsError() async {
        await resumeService.setHasResumeResult(true)
        await vacancyService.setFetchVacanciesResult(.failure(TestError.network))

        store.send(.onAppear)

        await waitForEffects()
        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.errorMessage)
    }

    // MARK: - filterChanged

    func test_filterChanged_updatesFilterAndLoadsVacancies() async {
        let favorites = [sampleVacancies[1]]
        await vacancyService.setFetchVacanciesResult(.success(favorites))

        store.send(.filterChanged(.favorites))

        XCTAssertEqual(store.state.selectedFilter, .favorites)
        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.vacancies.count, 1)
        XCTAssertEqual(store.state.vacancies.first?.id, "2")

        let lastFilter = await vacancyService.lastFetchFilter
        XCTAssertEqual(lastFilter, .favorites)
    }

    func test_filterChanged_failure_showsError() async {
        await vacancyService.setFetchVacanciesResult(.failure(TestError.network))

        store.send(.filterChanged(.favorites))

        try? await Task.sleep(nanoseconds: 4_000_000_000)
        await Task.yield()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.errorMessage)
    }

    // MARK: - searchQueryChanged (sync, no effect)

    func test_searchQueryChanged_updatesQuery() {
        store.send(.searchQueryChanged("Swift"))

        XCTAssertEqual(store.state.searchQuery, "Swift")
        XCTAssertFalse(store.state.isLoading)
    }

    func test_searchQueryChanged_doesNotTriggerLoad() async {
        store.send(.searchQueryChanged("iOS"))

        await waitForEffects()

        let fetchCalls = await vacancyService.fetchVacanciesCallCount
        XCTAssertEqual(fetchCalls, 0)
    }

    // MARK: - searchSubmitted

    func test_searchSubmitted_triggersLoadVacancies() async {
        await vacancyService.setFetchVacanciesResult(.success(sampleVacancies))

        store.send(.searchQueryChanged("iOS"))
        store.send(.searchSubmitted)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.vacancies.count, 2)

        let lastQuery = await vacancyService.lastFetchSearchQuery
        XCTAssertEqual(lastQuery, "iOS")
    }

    func test_searchSubmitted_failure_showsError() async {
        await vacancyService.setFetchVacanciesResult(.failure(TestError.network))

        store.send(.searchQueryChanged("Go"))
        store.send(.searchSubmitted)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.errorMessage)
    }

    // MARK: - vacancyTapped

    func test_vacancyTapped_setsSelectedVacancy() {
        let vacancy = sampleVacancies[0]

        store.send(.vacancyTapped(vacancy))

        XCTAssertEqual(store.state.selectedVacancy, vacancy)
    }

    func test_vacancyTapped_effectReturnsNil_stateUnchangedAfterWait() async {
        let vacancy = sampleVacancies[0]

        store.send(.vacancyTapped(vacancy))

        await waitForEffects()

        XCTAssertEqual(store.state.selectedVacancy, vacancy)
        XCTAssertFalse(store.state.isLoading)
    }

    // MARK: - toggleFavorite

    func test_toggleFavorite_success_updatesVacancy() async {
        await vacancyService.setFetchVacanciesResult(.success(sampleVacancies))
        store.send(.filterChanged(.all))
        await waitForEffects()

        XCTAssertFalse(store.state.vacancies[0].isFavorite)

        await vacancyService.setToggleFavoriteResult(.success(true))
        store.send(.toggleFavorite("1"))

        await waitForEffects()

        XCTAssertTrue(store.state.vacancies.first(where: { $0.id == "1" })!.isFavorite)

        let toggleCalls = await vacancyService.toggleFavoriteCallCount
        XCTAssertEqual(toggleCalls, 1)
        let lastId = await vacancyService.lastToggleFavoriteId
        XCTAssertEqual(lastId, "1")
    }

    func test_toggleFavorite_failure_showsError() async {
        await vacancyService.setFetchVacanciesResult(.success(sampleVacancies))
        store.send(.filterChanged(.all))
        await waitForEffects()

        await vacancyService.setToggleFavoriteResult(.failure(TestError.network))
        store.send(.toggleFavorite("1"))

        await waitForEffects()

        XCTAssertNotNil(store.state.errorMessage)
    }

    func test_toggleFavorite_unfavorite_updatesVacancy() async {
        let vacanciesWithFav = [
            DiscoveryState.Vacancy(id: "1", title: "iOS Dev", company: "Co", description: "D", isFavorite: true)
        ]
        await vacancyService.setFetchVacanciesResult(.success(vacanciesWithFav))
        store.send(.filterChanged(.all))
        await waitForEffects()

        XCTAssertTrue(store.state.vacancies[0].isFavorite)

        await vacancyService.setToggleFavoriteResult(.success(false))
        store.send(.toggleFavorite("1"))

        await waitForEffects()

        XCTAssertFalse(store.state.vacancies.first(where: { $0.id == "1" })!.isFavorite)
    }

    // MARK: - uploadResumeTapped (navigation, no feedback)

    func test_uploadResumeTapped_doesNotChangeLoadingState() async {
        store.send(.uploadResumeTapped)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNil(store.state.errorMessage)
    }

    // MARK: - retryTapped

    func test_retryTapped_clearsErrorAndReloads() async {
        await resumeService.setHasResumeResult(true)
        await vacancyService.setFetchVacanciesResult(.failure(TestError.network))

        store.send(.onAppear)
        await waitForEffects()
        await waitForEffects()

        XCTAssertNotNil(store.state.errorMessage)

        await vacancyService.setFetchVacanciesResult(.success(sampleVacancies))
        store.send(.retryTapped)

        XCTAssertNil(store.state.errorMessage)
        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()
        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.vacancies.count, 2)
    }

    // MARK: - Vacancies loaded clears error

    func test_vacanciesLoaded_clearsExistingError() async {
        await vacancyService.setFetchVacanciesResult(.failure(TestError.network))
        store.send(.filterChanged(.all))
        await waitForEffects()

        XCTAssertNotNil(store.state.errorMessage)

        await vacancyService.setFetchVacanciesResult(.success(sampleVacancies))
        store.send(.searchSubmitted)
        await waitForEffects()

        XCTAssertNil(store.state.errorMessage)
        XCTAssertEqual(store.state.vacancies.count, 2)
    }
}
