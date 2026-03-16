//
//  OnboardingStateTests.swift
//  OnboardingFeatureTests
//
//  Unit tests for OnboardingState reducer (Store state logic)
//

import XCTest
import ArchitectureCore
@testable import OnboardingFeature

@MainActor
final class OnboardingStateTests: XCTestCase {

    func testNextPageTapped_onFirstPage_incrementsPageAndReturnsLogPageView() {
        var state = OnboardingState()
        state.currentPage = 0

        let effect = OnboardingState.reduce(state: &state, with: .input(.nextPageTapped))

        XCTAssertEqual(state.currentPage, 1)
        guard case .logPageView(1) = effect else {
            XCTFail("Expected logPageView(1)")
            return
        }
    }

    func testNextPageTapped_onLastPage_returnsCompleteOnboarding() {
        var state = OnboardingState()
        state.currentPage = state.pages.count - 1

        let effect = OnboardingState.reduce(state: &state, with: .input(.nextPageTapped))

        guard case .completeOnboarding = effect else {
            XCTFail("Expected completeOnboarding")
            return
        }
    }

    func testPreviousPageTapped_decrementsPage() {
        var state = OnboardingState()
        state.currentPage = 1

        let effect = OnboardingState.reduce(state: &state, with: .input(.previousPageTapped))

        XCTAssertEqual(state.currentPage, 0)
        guard case .logPageView(0) = effect else {
            XCTFail("Expected logPageView(0)")
            return
        }
    }

    func testPreviousPageTapped_onFirstPage_doesNothing() {
        var state = OnboardingState()
        state.currentPage = 0

        let effect = OnboardingState.reduce(state: &state, with: .input(.previousPageTapped))

        XCTAssertEqual(state.currentPage, 0)
        XCTAssertNil(effect)
    }

    func testPageChanged_setsCurrentPage() {
        var state = OnboardingState()

        let effect = OnboardingState.reduce(state: &state, with: .input(.pageChanged(2)))

        XCTAssertEqual(state.currentPage, 2)
        guard case .logPageView(2) = effect else {
            XCTFail("Expected logPageView(2)")
            return
        }
    }

    func testSkipTapped_returnsCompleteOnboarding() {
        var state = OnboardingState()

        let effect = OnboardingState.reduce(state: &state, with: .input(.skipTapped))

        guard case .completeOnboarding = effect else {
            XCTFail("Expected completeOnboarding")
            return
        }
    }

    func testGetStartedTapped_returnsCompleteOnboarding() {
        var state = OnboardingState()

        let effect = OnboardingState.reduce(state: &state, with: .input(.getStartedTapped))

        guard case .completeOnboarding = effect else {
            XCTFail("Expected completeOnboarding")
            return
        }
    }

    func testFeedback_onboardingCompleted_setsCompleted() {
        var state = OnboardingState()

        _ = OnboardingState.reduce(state: &state, with: .feedback(.onboardingCompleted))

        XCTAssertTrue(state.isCompleted)
    }
}
