//
//  AuthStateTests.swift
//  AuthFeatureTests
//
//  Unit tests for AuthState reducer (Store state logic)
//

import ArchitectureCore
@testable import AuthFeature
import XCTest

@MainActor
final class AuthStateTests: XCTestCase {

    func testShowLogin_setsFlowAndClearsError() {
        var state = AuthState()
        state.authFlow = .registration
        state.errorMessage = "Error"

        _ = AuthState.reduce(state: &state, with: .input(.showLogin))

        XCTAssertEqual(state.authFlow, .login)
        XCTAssertNil(state.errorMessage)
    }

    func testLoginEmailChanged_updatesFieldAndClearsError() {
        var state = AuthState()
        state.errorMessage = "Error"

        _ = AuthState.reduce(state: &state, with: .input(.loginEmailChanged("a@b.com")))

        XCTAssertEqual(state.loginEmail, "a@b.com")
        XCTAssertNil(state.errorMessage)
    }

    func testLoginTapped_whenFieldsEmpty_setsErrorMessage() {
        var state = AuthState()
        state.loginEmail = ""
        state.loginPassword = ""

        let effect = AuthState.reduce(state: &state, with: .input(.loginTapped))

        XCTAssertNil(effect)
        XCTAssertEqual(state.errorMessage, "Заполните все поля")
    }

    func testLoginTapped_whenFieldsFilled_returnsPerformLogin() {
        var state = AuthState()
        state.loginEmail = "user@test.com"
        state.loginPassword = "secret"
        state.errorMessage = "Previous"

        let effect = AuthState.reduce(state: &state, with: .input(.loginTapped))

        XCTAssertTrue(state.isLoading)
        XCTAssertNil(state.errorMessage)
        guard case .performLogin(let email, let password) = effect else {
            XCTFail("Expected performLogin")
            return
        }
        XCTAssertEqual(email, "user@test.com")
        XCTAssertEqual(password, "secret")
    }

    func testRegistrationContinueTapped_whenNamesEmpty_setsError() {
        var state = AuthState()
        state.authFlow = .registration
        state.registrationFirstName = ""
        state.registrationLastName = ""

        let effect = AuthState.reduce(state: &state, with: .input(.registrationContinueTapped))

        XCTAssertNil(effect)
        XCTAssertEqual(state.errorMessage, "Заполните все поля")
    }

    func testRegistrationContinueTapped_whenNamesFilled_goesToDetails() {
        var state = AuthState()
        state.registrationFirstName = "Иван"
        state.registrationLastName = "Иванов"

        _ = AuthState.reduce(state: &state, with: .input(.registrationContinueTapped))

        XCTAssertEqual(state.authFlow, .registrationDetails)
    }

    func testRegistrationSubmitTapped_whenPasswordsMismatch_setsError() {
        var state = AuthState()
        state.authFlow = .registrationDetails
        state.registrationEmail = "a@b.com"
        state.registrationPassword = "123456"
        state.registrationPasswordConfirm = "654321"

        let effect = AuthState.reduce(state: &state, with: .input(.registrationSubmitTapped))

        XCTAssertNil(effect)
        XCTAssertEqual(state.errorMessage, "Пароли не совпадают")
    }

    func testRegistrationSubmitTapped_whenValid_returnsPerformRegistration() {
        var state = AuthState()
        state.registrationFirstName = "Иван"
        state.registrationLastName = "Иванов"
        state.registrationEmail = "a@b.com"
        state.registrationPassword = "123456"
        state.registrationPasswordConfirm = "123456"

        let effect = AuthState.reduce(state: &state, with: .input(.registrationSubmitTapped))

        XCTAssertTrue(state.isLoading)
        guard case .performRegistration(let fn, let ln, let email, let pw) = effect else {
            XCTFail("Expected performRegistration")
            return
        }
        XCTAssertEqual(fn, "Иван")
        XCTAssertEqual(ln, "Иванов")
        XCTAssertEqual(email, "a@b.com")
        XCTAssertEqual(pw, "123456")
    }

    func testBackTapped_fromRegistrationDetails_goesToRegistration() {
        var state = AuthState()
        state.authFlow = .registrationDetails

        _ = AuthState.reduce(state: &state, with: .input(.backTapped))

        XCTAssertEqual(state.authFlow, .registration)
    }

    func testFeedback_loginSuccess_setsAuthenticated() {
        var state = AuthState()
        state.isLoading = true

        _ = AuthState.reduce(state: &state, with: .feedback(.loginSuccess))

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.isAuthenticated)
    }

    func testFeedback_resetCodeSent_setsOtpEmailAndFlow() {
        var state = AuthState()
        state.resetEmail = "otp@test.com"
        state.isLoading = true

        _ = AuthState.reduce(state: &state, with: .feedback(.resetCodeSent))

        XCTAssertEqual(state.otpEmail, "otp@test.com")
        XCTAssertEqual(state.authFlow, .otpVerification)
        XCTAssertFalse(state.isLoading)
    }

    func testResumeSkipTapped_setsAuthenticated() {
        var state = AuthState()
        state.authFlow = .resumeUpload

        _ = AuthState.reduce(state: &state, with: .input(.resumeSkipTapped))

        XCTAssertTrue(state.isAuthenticated)
    }
}
