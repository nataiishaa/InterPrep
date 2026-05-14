import ArchitectureCore
@testable import OnboardingFeature
import XCTest

private final class SpyOnboardingStorageService: OnboardingStorageServicing {
    private(set) var markCompletedCallCount = 0
    private var completed = false

    func markOnboardingCompleted() {
        markCompletedCallCount += 1
        completed = true
    }

    func isOnboardingCompleted() -> Bool {
        completed
    }
}

@MainActor
final class OnboardingStoreTests: XCTestCase {
    private var storageService: SpyOnboardingStorageService!
    private var store: OnboardingStore!

    override func setUp() {
        super.setUp()
        storageService = SpyOnboardingStorageService()
        store = OnboardingStore(
            state: OnboardingState(),
            effectHandler: OnboardingEffectHandler(storageService: storageService)
        )
    }

    override func tearDown() {
        store = nil
        storageService = nil
        super.tearDown()
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        await Task.yield()
    }

    func test_nextPageTapped_onFirstPage_incrementsPage() {
        XCTAssertEqual(store.state.currentPage, 0)

        store.send(.nextPageTapped)

        XCTAssertEqual(store.state.currentPage, 1)
        XCTAssertFalse(store.state.isCompleted)
    }

    func test_nextPageTapped_onLastPage_completesOnboarding() async {
        store.send(.pageChanged(store.state.pages.count - 1))

        store.send(.nextPageTapped)

        await waitForEffects()

        XCTAssertTrue(store.state.isCompleted)
        XCTAssertFalse(store.state.shouldOpenRegistration)
        XCTAssertEqual(storageService.markCompletedCallCount, 1)
    }

    func test_previousPageTapped_decrementsPage() {
        store.send(.nextPageTapped)
        XCTAssertEqual(store.state.currentPage, 1)

        store.send(.previousPageTapped)

        XCTAssertEqual(store.state.currentPage, 0)
    }

    func test_previousPageTapped_onFirstPage_doesNothing() {
        XCTAssertEqual(store.state.currentPage, 0)

        store.send(.previousPageTapped)

        XCTAssertEqual(store.state.currentPage, 0)
    }

    func test_skipTapped_completesOnboarding() async {
        store.send(.skipTapped)

        await waitForEffects()

        XCTAssertTrue(store.state.isCompleted)
        XCTAssertFalse(store.state.shouldOpenRegistration)
        XCTAssertEqual(storageService.markCompletedCallCount, 1)
    }

    func test_getStartedTapped_completesOnboarding() async {
        store.send(.getStartedTapped)

        await waitForEffects()

        XCTAssertTrue(store.state.isCompleted)
        XCTAssertFalse(store.state.shouldOpenRegistration)
        XCTAssertEqual(storageService.markCompletedCallCount, 1)
    }

    func test_registerTapped_completesOnboardingWithRegistration() async {
        store.send(.registerTapped)

        await waitForEffects()

        XCTAssertTrue(store.state.isCompleted)
        XCTAssertTrue(store.state.shouldOpenRegistration)
        XCTAssertEqual(storageService.markCompletedCallCount, 1)
    }

    func test_pageChanged_updatesCurrentPage() {
        store.send(.pageChanged(2))

        XCTAssertEqual(store.state.currentPage, 2)
    }
}
