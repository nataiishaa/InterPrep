import ArchitectureCore
@testable import AuthFeature
import ResumeUploadFeature
import XCTest

private actor SpyAuthService: AuthServicing {
    var loginCallCount = 0
    var registerCallCount = 0
    var sendResetCodeCallCount = 0
    var verifyOTPCallCount = 0
    var changePasswordCallCount = 0
    var uploadResumeCallCount = 0

    var loginResult: Result<Void, Error> = .success(())
    var registerResult: Result<Void, Error> = .success(())
    var sendResetCodeResult: Result<Void, Error> = .success(())
    var verifyOTPResult: Result<Void, Error> = .success(())
    var changePasswordResult: Result<Void, Error> = .success(())
    var uploadResumeResult: Result<Void, Error> = .success(())

    func login(email: String, password: String) async throws {
        loginCallCount += 1
        if case .failure(let error) = loginResult { throw error }
    }

    func register(firstName: String, lastName: String, email: String, password: String) async throws {
        registerCallCount += 1
        if case .failure(let error) = registerResult { throw error }
    }

    func sendPasswordResetCode(email: String) async throws {
        sendResetCodeCallCount += 1
        if case .failure(let error) = sendResetCodeResult { throw error }
    }

    func verifyOTP(email: String, code: String) async throws {
        verifyOTPCallCount += 1
        if case .failure(let error) = verifyOTPResult { throw error }
    }

    func uploadResume() async throws {
        uploadResumeCallCount += 1
        if case .failure(let error) = uploadResumeResult { throw error }
    }

    func changePassword(email: String, code: String, newPassword: String) async throws {
        changePasswordCallCount += 1
        if case .failure(let error) = changePasswordResult { throw error }
    }

    func setLoginResult(_ result: Result<Void, Error>) { loginResult = result }
    func setRegisterResult(_ result: Result<Void, Error>) { registerResult = result }
    func setSendResetCodeResult(_ result: Result<Void, Error>) { sendResetCodeResult = result }
    func setVerifyOTPResult(_ result: Result<Void, Error>) { verifyOTPResult = result }
    func setChangePasswordResult(_ result: Result<Void, Error>) { changePasswordResult = result }
}

private enum TestError: LocalizedError {
    case generic
    var errorDescription: String? { "Test error" }
}

@MainActor
final class AuthStoreTests: XCTestCase {
    private var authService: SpyAuthService!
    private var store: AuthStore!

    override func setUp() {
        super.setUp()
        authService = SpyAuthService()
        store = AuthStore(
            state: AuthState(),
            effectHandler: AuthEffectHandler(authService: authService)
        )
    }

    override func tearDown() {
        store = nil
        authService = nil
        super.tearDown()
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        await Task.yield()
    }

    func test_emptyFields_loginTapped_showsValidationError() {
        store.send(.loginEmailChanged(""))
        store.send(.loginPasswordChanged(""))

        store.send(.loginTapped)

        XCTAssertEqual(store.state.errorMessage, "Заполните все поля")
        XCTAssertFalse(store.state.isLoading)
    }

    func test_filledFields_loginTapped_success_setsAuthenticated() async {
        store.send(.loginEmailChanged("user@test.com"))
        store.send(.loginPasswordChanged("secret123"))

        store.send(.loginTapped)

        XCTAssertTrue(store.state.isLoading)
        XCTAssertNil(store.state.errorMessage)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertTrue(store.state.isAuthenticated)
        let callCount = await authService.loginCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_filledFields_loginTapped_failure_showsError() async {
        await authService.setLoginResult(.failure(TestError.generic))

        store.send(.loginEmailChanged("user@test.com"))
        store.send(.loginPasswordChanged("secret123"))
        store.send(.loginTapped)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertFalse(store.state.isAuthenticated)
        XCTAssertNotNil(store.state.errorMessage)
    }

    func test_emailChanged_clearsError() {
        store.send(.loginTapped)
        XCTAssertNotNil(store.state.errorMessage)

        store.send(.loginEmailChanged("a@b.com"))

        XCTAssertNil(store.state.errorMessage)
        XCTAssertEqual(store.state.loginEmail, "a@b.com")
    }

    func test_emptyNames_registrationContinue_showsError() {
        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged(""))
        store.send(.registrationLastNameChanged(""))

        store.send(.registrationContinueTapped)

        XCTAssertEqual(store.state.errorMessage, "Заполните все поля")
        XCTAssertEqual(store.state.authFlow, .registration)
    }

    func test_filledNames_registrationContinue_goesToDetails() {
        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("Иван"))
        store.send(.registrationLastNameChanged("Иванов"))

        store.send(.registrationContinueTapped)

        XCTAssertEqual(store.state.authFlow, .registrationDetails)
        XCTAssertNil(store.state.errorMessage)
    }

    func test_passwordsMismatch_registrationSubmit_showsError() {
        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("Иван"))
        store.send(.registrationLastNameChanged("Иванов"))
        store.send(.registrationContinueTapped)

        store.send(.registrationEmailChanged("i@test.com"))
        store.send(.registrationPasswordChanged("123456"))
        store.send(.registrationPasswordConfirmChanged("654321"))
        store.send(.registrationSubmitTapped)

        XCTAssertEqual(store.state.errorMessage, "Пароли не совпадают")
        XCTAssertFalse(store.state.isLoading)
    }

    func test_shortPassword_registrationSubmit_showsError() {
        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("Иван"))
        store.send(.registrationLastNameChanged("Иванов"))
        store.send(.registrationContinueTapped)

        store.send(.registrationEmailChanged("i@test.com"))
        store.send(.registrationPasswordChanged("123"))
        store.send(.registrationPasswordConfirmChanged("123"))
        store.send(.registrationSubmitTapped)

        XCTAssertEqual(store.state.errorMessage, "Пароль должен содержать не менее 8 символов")
    }

    func test_validRegistration_success_goesToResumeUpload() async {
        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("Иван"))
        store.send(.registrationLastNameChanged("Иванов"))
        store.send(.registrationContinueTapped)

        store.send(.registrationEmailChanged("i@test.com"))
        store.send(.registrationPasswordChanged("12345678"))
        store.send(.registrationPasswordConfirmChanged("12345678"))
        store.send(.registrationSubmitTapped)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.authFlow, .resumeUpload)
        let callCount = await authService.registerCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_validRegistration_failure_showsError() async {
        await authService.setRegisterResult(.failure(TestError.generic))

        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("Иван"))
        store.send(.registrationLastNameChanged("Иванов"))
        store.send(.registrationContinueTapped)

        store.send(.registrationEmailChanged("i@test.com"))
        store.send(.registrationPasswordChanged("12345678"))
        store.send(.registrationPasswordConfirmChanged("12345678"))
        store.send(.registrationSubmitTapped)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.errorMessage)
    }

    func test_emptyEmail_sendResetCode_showsError() {
        store.send(.showPasswordReset)
        store.send(.resetEmailChanged(""))
        store.send(.sendResetCodeTapped)

        XCTAssertEqual(store.state.errorMessage, "Введите email")
    }

    func test_validEmail_sendResetCode_success_goesToOTP() async {
        store.send(.showPasswordReset)
        store.send(.resetEmailChanged("otp@test.com"))
        store.send(.sendResetCodeTapped)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.authFlow, .otpVerification)
        XCTAssertEqual(store.state.otpEmail, "otp@test.com")
    }

    func test_validEmail_sendResetCode_failure_showsError() async {
        await authService.setSendResetCodeResult(.failure(TestError.generic))

        store.send(.showPasswordReset)
        store.send(.resetEmailChanged("otp@test.com"))
        store.send(.sendResetCodeTapped)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.errorMessage)
    }

    func test_shortCode_otpSubmit_showsError() {
        store.send(.showPasswordReset)
        store.send(.resetEmailChanged("otp@test.com"))

        var state = store.state
        state.authFlow = .otpVerification
        state.otpEmail = "otp@test.com"

        store.send(.otpCodeChanged("123"))
        store.send(.otpSubmitTapped)

        XCTAssertEqual(store.state.errorMessage, "Введите код из 6 символов")
    }

    func test_validCode_otpSubmit_success_goesToNewPassword() async {
        store.send(.showPasswordReset)
        store.send(.resetEmailChanged("otp@test.com"))
        store.send(.sendResetCodeTapped)

        await waitForEffects()

        store.send(.otpCodeChanged("123456"))
        store.send(.otpSubmitTapped)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.authFlow, .newPassword)
    }

    func test_emptyPasswords_newPasswordSubmit_showsError() async {
        store.send(.showPasswordReset)
        store.send(.resetEmailChanged("otp@test.com"))
        store.send(.sendResetCodeTapped)
        await waitForEffects()

        store.send(.otpCodeChanged("123456"))
        store.send(.otpSubmitTapped)
        await waitForEffects()

        store.send(.newPasswordChanged(""))
        store.send(.newPasswordConfirmChanged(""))
        store.send(.newPasswordSubmitTapped)

        XCTAssertEqual(store.state.errorMessage, "Заполните все поля")
    }

    func test_validNewPassword_success_goesToLogin() async {
        store.send(.showPasswordReset)
        store.send(.resetEmailChanged("otp@test.com"))
        store.send(.sendResetCodeTapped)
        await waitForEffects()

        store.send(.otpCodeChanged("123456"))
        store.send(.otpSubmitTapped)
        await waitForEffects()

        store.send(.newPasswordChanged("newpass123"))
        store.send(.newPasswordConfirmChanged("newpass123"))
        store.send(.newPasswordSubmitTapped)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.authFlow, .login)
        let callCount = await authService.changePasswordCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_showRegistration_setsFlow() {
        store.send(.showRegistration)

        XCTAssertEqual(store.state.authFlow, .registration)
        XCTAssertNil(store.state.errorMessage)
    }

    func test_showLogin_setsFlow() {
        store.send(.showRegistration)
        store.send(.showLogin)

        XCTAssertEqual(store.state.authFlow, .login)
    }

    func test_backFromRegistrationDetails_goesToRegistration() {
        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("A"))
        store.send(.registrationLastNameChanged("B"))
        store.send(.registrationContinueTapped)

        XCTAssertEqual(store.state.authFlow, .registrationDetails)

        store.send(.backTapped)

        XCTAssertEqual(store.state.authFlow, .registration)
    }

    func test_resumeSkipTapped_setsAuthenticated() async {
        await authService.setRegisterResult(.success(()))

        store.send(.showRegistration)
        store.send(.registrationFirstNameChanged("Иван"))
        store.send(.registrationLastNameChanged("Иванов"))
        store.send(.registrationContinueTapped)
        store.send(.registrationEmailChanged("i@test.com"))
        store.send(.registrationPasswordChanged("12345678"))
        store.send(.registrationPasswordConfirmChanged("12345678"))
        store.send(.registrationSubmitTapped)

        await waitForEffects()

        XCTAssertEqual(store.state.authFlow, .resumeUpload)

        store.send(.resumeSkipTapped)

        XCTAssertTrue(store.state.isAuthenticated)
    }

    func test_forgotPasswordTapped_goesToPasswordReset() {
        store.send(.forgotPasswordTapped)

        XCTAssertEqual(store.state.authFlow, .passwordReset)
    }
}
