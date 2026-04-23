//
//  ProfileStateTests.swift
//  InterPrepTests
//
//  Unit tests for ProfileState reducer (Store state logic)
//

import ArchitectureCore
@testable import ProfileFeature
import XCTest

@MainActor
final class ProfileStateTests: XCTestCase {

    func testOnAppear_returnsLoadUser() {
        var state = ProfileState()

        let effect = ProfileState.reduce(state: &state, with: .input(.onAppear))

        XCTAssertTrue(state.isLoading)
        XCTAssertTrue(state.isLoadingInterviews)
        guard case .loadUser = effect else {
            XCTFail("Expected loadUser")
            return
        }
    }

    func testStartEditingProfile_setsFieldsFromUser() {
        var state = ProfileState()
        state.user = ProfileState.User(
            id: "1",
            firstName: "Иван",
            lastName: "Иванов",
            email: "i@test.com"
        )

        _ = ProfileState.reduce(state: &state, with: .input(.startEditingProfile))

        XCTAssertTrue(state.isEditingProfile)
        XCTAssertEqual(state.editedFirstName, "Иван")
        XCTAssertEqual(state.editedLastName, "Иванов")
    }

    func testCancelEditingProfile_resetsEditing() {
        var state = ProfileState()
        state.isEditingProfile = true
        state.errorMessage = "Err"

        _ = ProfileState.reduce(state: &state, with: .input(.cancelEditingProfile))

        XCTAssertFalse(state.isEditingProfile)
        XCTAssertNil(state.errorMessage)
    }

    func testFirstNameChanged_updatesAndClearsError() {
        var state = ProfileState()
        state.errorMessage = "Old"

        _ = ProfileState.reduce(state: &state, with: .input(.firstNameChanged("Петр")))

        XCTAssertEqual(state.editedFirstName, "Петр")
        XCTAssertNil(state.errorMessage)
    }

    func testSaveProfile_whenNamesEmpty_setsError() {
        var state = ProfileState()
        state.user = ProfileState.User(id: "1", firstName: "A", lastName: "B", email: "a@b.com")
        state.editedFirstName = ""
        state.editedLastName = ""

        let effect = ProfileState.reduce(state: &state, with: .input(.saveProfile))

        XCTAssertNil(effect)
        XCTAssertEqual(state.errorMessage, "Заполните имя и фамилию")
    }

    func testSaveProfile_whenValid_returnsUpdateProfile() {
        var state = ProfileState()
        state.user = ProfileState.User(id: "1", firstName: "Old", lastName: "Name", email: "e@mail.com")
        state.editedFirstName = "New"
        state.editedLastName = "Surname"

        let effect = ProfileState.reduce(state: &state, with: .input(.saveProfile))

        XCTAssertTrue(state.isLoading)
        guard case .updateProfile(let user) = effect else {
            XCTFail("Expected updateProfile")
            return
        }
        XCTAssertEqual(user.firstName, "New")
        XCTAssertEqual(user.lastName, "Surname")
        XCTAssertEqual(user.email, "e@mail.com")
    }

    func testNotificationsToggled_updatesStateAndReturnsSaveSettings() {
        var state = ProfileState()
        state.settings.notificationsEnabled = true

        let effect = ProfileState.reduce(state: &state, with: .input(.notificationsToggled(false)))

        XCTAssertFalse(state.settings.notificationsEnabled)
        guard case .saveSettings(let settings) = effect else {
            XCTFail("Expected saveSettings")
            return
        }
        XCTAssertFalse(settings.notificationsEnabled)
    }

    func testLogout_returnsPerformLogout() {
        var state = ProfileState()

        let effect = ProfileState.reduce(state: &state, with: .input(.logout))

        guard case .performLogout = effect else {
            XCTFail("Expected performLogout")
            return
        }
    }

    func testChangeResume_returnsNavigateToResumeUpload() {
        var state = ProfileState()

        let effect = ProfileState.reduce(state: &state, with: .input(.changeResume))

        guard case .navigateToResumeUpload = effect else {
            XCTFail("Expected navigateToResumeUpload")
            return
        }
    }

    func testInterviewTabChanged_updatesTab() {
        var state = ProfileState()
        state.selectedInterviewTab = .upcoming

        _ = ProfileState.reduce(state: &state, with: .input(.interviewTabChanged(.completed)))

        XCTAssertEqual(state.selectedInterviewTab, .completed)
    }

    func testFeedback_profileLoaded_updatesState() {
        var state = ProfileState()
        state.isLoading = true
        let user = ProfileState.User(id: "1", firstName: "A", lastName: "B", email: "a@b.com")
        let stats = ProfileState.Statistics(totalInterviews: 5)

        _ = ProfileState.reduce(state: &state, with: .feedback(.profileLoaded(user: user, statistics: stats, profilePhotoURL: nil)))

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.user?.id, "1")
        XCTAssertEqual(state.statistics.totalInterviews, 5)
    }

    func testFeedback_logoutCompleted_clearsUserAndSetsAuthRequired() {
        var state = ProfileState()
        state.user = ProfileState.User(id: "1", firstName: "A", lastName: "B", email: "a@b.com")

        _ = ProfileState.reduce(state: &state, with: .feedback(.logoutCompleted))

        XCTAssertNil(state.user)
        XCTAssertTrue(state.authRequired)
    }

    func testFeedback_loadingFailed_setsErrorMessage() {
        var state = ProfileState()
        state.isLoading = true

        _ = ProfileState.reduce(state: &state, with: .feedback(.loadingFailed("Error")))

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.errorMessage, "Error")
    }
}
