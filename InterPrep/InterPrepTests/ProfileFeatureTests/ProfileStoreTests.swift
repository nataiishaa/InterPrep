import ArchitectureCore
@testable import ProfileFeature
import XCTest

private actor SpySessionService: ProfileSessionServicing {
    var clearTokensCallCount = 0
    var deleteAccountCallCount = 0
    var deleteAccountResult: Result<Void, ProfileSessionError> = .success(())

    func clearTokens() async {
        clearTokensCallCount += 1
    }

    func deleteAccount(password: String) async -> Result<Void, ProfileSessionError> {
        deleteAccountCallCount += 1
        return deleteAccountResult
    }

    func setDeleteAccountResult(_ result: Result<Void, ProfileSessionError>) { deleteAccountResult = result }
}

private extension ProfileState {
    static func withUser(_ user: ProfileState.User = .stub) -> ProfileState {
        var state = ProfileState()
        state.user = user
        return state
    }
}

private extension ProfileState.User {
    static let stub = ProfileState.User(
        id: "1",
        firstName: "Иван",
        lastName: "Иванов",
        email: "i@test.com"
    )
}

@MainActor
final class ProfileStoreTests: XCTestCase {
    private var sessionService: SpySessionService!
    private var store: ProfileStore!

    override func setUp() {
        super.setUp()
        sessionService = SpySessionService()
    }

    override func tearDown() {
        store = nil
        sessionService = nil
        super.tearDown()
    }

    private func makeStore(state: ProfileState = ProfileState()) {
        store = ProfileStore(
            state: state,
            effectHandler: ProfileEffectHandler(sessionService: sessionService)
        )
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        await Task.yield()
    }

    func test_onAppear_setsLoading() {
        makeStore()

        store.send(.onAppear)

        XCTAssertTrue(store.state.isLoading)
        XCTAssertTrue(store.state.isLoadingInterviews)
    }

    func test_startEditingProfile_setsFieldsFromUser() {
        makeStore(state: .withUser())

        store.send(.startEditingProfile)

        XCTAssertTrue(store.state.isEditingProfile)
        XCTAssertEqual(store.state.editedFirstName, "Иван")
        XCTAssertEqual(store.state.editedLastName, "Иванов")
    }

    func test_cancelEditingProfile_resetsEditing() {
        makeStore(state: .withUser())
        store.send(.startEditingProfile)
        XCTAssertTrue(store.state.isEditingProfile)

        store.send(.cancelEditingProfile)

        XCTAssertFalse(store.state.isEditingProfile)
        XCTAssertNil(store.state.errorMessage)
    }

    func test_firstNameChanged_updatesName() {
        makeStore()

        store.send(.firstNameChanged("Петр"))

        XCTAssertEqual(store.state.editedFirstName, "Петр")
        XCTAssertNil(store.state.errorMessage)
    }

    func test_lastNameChanged_updatesName() {
        makeStore()

        store.send(.lastNameChanged("Сидоров"))

        XCTAssertEqual(store.state.editedLastName, "Сидоров")
    }

    func test_saveProfile_emptyNames_showsError() {
        makeStore(state: .withUser())
        store.send(.startEditingProfile)
        store.send(.firstNameChanged(""))
        store.send(.lastNameChanged(""))

        store.send(.saveProfile)

        XCTAssertEqual(store.state.errorMessage, "Заполните имя и фамилию")
        XCTAssertFalse(store.state.isLoading)
    }

    func test_saveProfile_validNames_setsLoading() {
        makeStore(state: .withUser())
        store.send(.startEditingProfile)
        store.send(.firstNameChanged("Петр"))
        store.send(.lastNameChanged("Сидоров"))

        store.send(.saveProfile)

        XCTAssertTrue(store.state.isLoading)
    }

    func test_notificationsToggled_updatesSettings() {
        makeStore()
        XCTAssertTrue(store.state.settings.notificationsEnabled)

        store.send(.notificationsToggled(false))

        XCTAssertFalse(store.state.settings.notificationsEnabled)
    }

    func test_themeChanged_updatesSettings() {
        makeStore()

        store.send(.themeChanged(.dark))

        XCTAssertEqual(store.state.settings.theme, .dark)
    }

    func test_analyticsToggled_updatesSettings() {
        makeStore()

        store.send(.analyticsToggled(false))

        XCTAssertFalse(store.state.settings.analyticsEnabled)
    }

    func test_crashReportsToggled_updatesSettings() {
        makeStore()

        store.send(.crashReportsToggled(false))

        XCTAssertFalse(store.state.settings.crashReportsEnabled)
    }

    func test_interviewTabChanged_updatesTab() {
        makeStore()
        XCTAssertEqual(store.state.selectedInterviewTab, .upcoming)

        store.send(.interviewTabChanged(.completed))

        XCTAssertEqual(store.state.selectedInterviewTab, .completed)
    }

    func test_viewResume_setsDownloading() {
        makeStore()

        store.send(.viewResume)

        XCTAssertTrue(store.state.isDownloadingResume)
        XCTAssertNil(store.state.errorMessage)
    }

    func test_logout_clearsUserAndSetsAuthRequired() async {
        makeStore(state: .withUser())
        XCTAssertNotNil(store.state.user)

        store.send(.logout)
        await waitForEffects()

        XCTAssertNil(store.state.user)
        XCTAssertTrue(store.state.authRequired)
        let callCount = await sessionService.clearTokensCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_deleteAccount_success_clearsState() async {
        makeStore(state: .withUser())

        store.send(.deleteAccount(password: "pass123"))
        await waitForEffects()

        XCTAssertNil(store.state.user)
        XCTAssertTrue(store.state.authRequired)
        let callCount = await sessionService.deleteAccountCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_deleteAccount_failure_showsError() async {
        await sessionService.setDeleteAccountResult(.failure(ProfileSessionError("Неверный пароль")))
        makeStore(state: .withUser())

        store.send(.deleteAccount(password: "wrong"))
        await waitForEffects()

        XCTAssertNotNil(store.state.user)
        XCTAssertEqual(store.state.deleteAccountError, "Неверный пароль")
    }

    func test_clearDeleteAccountError_clearsError() {
        var state = ProfileState()
        state.deleteAccountError = "Ошибка"
        makeStore(state: state)
        XCTAssertNotNil(store.state.deleteAccountError)

        store.send(.clearDeleteAccountError)

        XCTAssertNil(store.state.deleteAccountError)
    }

    func test_clearAuthRequired_clearsFlag() {
        var state = ProfileState()
        state.authRequired = true
        makeStore(state: state)
        XCTAssertTrue(store.state.authRequired)

        store.send(.clearAuthRequired)

        XCTAssertFalse(store.state.authRequired)
    }
}
