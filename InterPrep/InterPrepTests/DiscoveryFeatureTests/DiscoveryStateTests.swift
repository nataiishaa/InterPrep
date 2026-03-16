//
//  DiscoveryStateTests.swift
//  DiscoveryModuleTests
//
//  Unit tests for DiscoveryState reducer (Store state logic)
//

import XCTest
import ArchitectureCore
@testable import DiscoveryModule

@MainActor
final class DiscoveryStateTests: XCTestCase {

    func testOnAppear_returnsCheckResume() {
        var state = DiscoveryState()

        let effect = DiscoveryState.reduce(state: &state, with: .input(.onAppear))

        XCTAssertTrue(state.isLoading)
        guard case .checkResume = effect else {
            XCTFail("Expected checkResume")
            return
        }
    }

    func testFilterChanged_updatesFilterAndReturnsLoadVacancies() {
        var state = DiscoveryState()
        state.searchQuery = "dev"

        let effect = DiscoveryState.reduce(state: &state, with: .input(.filterChanged(.favorites)))

        XCTAssertEqual(state.selectedFilter, .favorites)
        XCTAssertTrue(state.isLoading)
        guard case .loadVacancies(.favorites, let query) = effect else {
            XCTFail("Expected loadVacancies")
            return
        }
        XCTAssertEqual(query, "dev")
    }

    func testSearchQueryChanged_updatesQuery() {
        var state = DiscoveryState()

        _ = DiscoveryState.reduce(state: &state, with: .input(.searchQueryChanged("iOS")))

        XCTAssertEqual(state.searchQuery, "iOS")
    }

    func testSearchSubmitted_returnsLoadVacancies() {
        var state = DiscoveryState()
        state.selectedFilter = .all
        state.searchQuery = "Swift"

        let effect = DiscoveryState.reduce(state: &state, with: .input(.searchSubmitted))

        XCTAssertTrue(state.isLoading)
        guard case .loadVacancies(.all, "Swift") = effect else {
            XCTFail("Expected loadVacancies(all, Swift)")
            return
        }
    }

    func testUploadResumeTapped_returnsNavigateToResumeUpload() {
        var state = DiscoveryState()

        let effect = DiscoveryState.reduce(state: &state, with: .input(.uploadResumeTapped))

        guard case .navigateToResumeUpload = effect else {
            XCTFail("Expected navigateToResumeUpload")
            return
        }
    }

    func testVacancyTapped_setsSelectedAndReturnsNavigate() {
        var state = DiscoveryState()
        let vacancy = DiscoveryState.Vacancy(
            id: "1",
            title: "Dev",
            company: "Co",
            description: "D",
            isFavorite: false
        )

        let effect = DiscoveryState.reduce(state: &state, with: .input(.vacancyTapped(vacancy)))

        XCTAssertEqual(state.selectedVacancy?.id, "1")
        guard case .navigateToVacancyDetail(let v) = effect else {
            XCTFail("Expected navigateToVacancyDetail")
            return
        }
        XCTAssertEqual(v.id, "1")
    }

    func testToggleFavorite_returnsEffect() {
        var state = DiscoveryState()

        let effect = DiscoveryState.reduce(state: &state, with: .input(.toggleFavorite("v1")))

        guard case .toggleFavorite("v1") = effect else {
            XCTFail("Expected toggleFavorite")
            return
        }
    }

    func testFeedback_vacanciesLoaded_updatesState() {
        var state = DiscoveryState()
        state.isLoading = true
        let vacancies = [
            DiscoveryState.Vacancy(id: "1", title: "A", company: "C", description: "D", isFavorite: false)
        ]

        _ = DiscoveryState.reduce(state: &state, with: .feedback(.vacanciesLoaded(vacancies)))

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.vacancies.count, 1)
        XCTAssertEqual(state.vacancies[0].id, "1")
    }

    func testFeedback_resumeCheckCompleted_returnsLoadVacancies() {
        var state = DiscoveryState()
        state.selectedFilter = .all
        state.searchQuery = ""

        let effect = DiscoveryState.reduce(state: &state, with: .feedback(.resumeCheckCompleted(hasResume: true)))

        XCTAssertTrue(state.hasResume)
        XCTAssertTrue(state.isLoading)
        guard case .loadVacancies = effect else {
            XCTFail("Expected loadVacancies")
            return
        }
    }
}
