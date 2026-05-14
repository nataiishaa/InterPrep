import ArchitectureCore
@testable import ProfileFeature
import XCTest

final class MockProfileSessionService: ProfileSessionServicing, @unchecked Sendable {
    var clearTokensCallCount = 0
    var deleteAccountCallCount = 0
    var deleteAccountPassword: String?
    var deleteAccountResult: Result<Void, ProfileSessionError> = .success(())

    func clearTokens() async {
        clearTokensCallCount += 1
    }

    func deleteAccount(password: String) async -> Result<Void, ProfileSessionError> {
        deleteAccountCallCount += 1
        deleteAccountPassword = password
        return deleteAccountResult
    }
}

@MainActor
final class ProfileEffectHandlerTests: XCTestCase {
    var mockSessionService: MockProfileSessionService!
    var sut: ProfileEffectHandler!

    override func setUp() {
        super.setUp()
        mockSessionService = MockProfileSessionService()
        sut = ProfileEffectHandler(sessionService: mockSessionService)
    }

    override func tearDown() {
        mockSessionService = nil
        sut = nil
        super.tearDown()
    }

    func testPerformLogout_clearsTokens_returnsLogoutCompleted() async {
        let feedback = await sut.handle(effect: .performLogout)
        XCTAssertEqual(mockSessionService.clearTokensCallCount, 1)
        if case .logoutCompleted = feedback {} else {
            XCTFail("Expected logoutCompleted feedback")
        }
    }

    func testDeleteAccount_success_returnsAccountDeleted() async {
        mockSessionService.deleteAccountResult = .success(())
        let feedback = await sut.handle(effect: .performDeleteAccount(password: "password123"))
        XCTAssertEqual(mockSessionService.deleteAccountCallCount, 1)
        XCTAssertEqual(mockSessionService.deleteAccountPassword, "password123")
        if case .accountDeleted = feedback {} else {
            XCTFail("Expected accountDeleted feedback")
        }
    }

    func testDeleteAccount_failure_returnsDeleteAccountFailed() async {
        mockSessionService.deleteAccountResult = .failure(ProfileSessionError("Неверный пароль"))
        let feedback = await sut.handle(effect: .performDeleteAccount(password: "wrong"))
        XCTAssertEqual(mockSessionService.deleteAccountCallCount, 1)
        if case .deleteAccountFailed(let message) = feedback {
            XCTAssertEqual(message, "Неверный пароль")
        } else {
            XCTFail("Expected deleteAccountFailed feedback")
        }
    }

    func testDeleteAccount_noSessionService_returnsFailed() async {
        let handlerWithoutService = ProfileEffectHandler(sessionService: nil)
        let feedback = await handlerWithoutService.handle(effect: .performDeleteAccount(password: "password"))
        if case .deleteAccountFailed(let message) = feedback {
            XCTAssertTrue(message.contains("недоступен"))
        } else {
            XCTFail("Expected deleteAccountFailed feedback")
        }
    }

    func testNavigateToResumeUpload_returnsNil() async {
        let feedback = await sut.handle(effect: .navigateToResumeUpload)
        XCTAssertNil(feedback)
    }

    func testNavigateToInterview_returnsNil() async {
        let interview = ProfileState.Interview(
            id: "1",
            title: "iOS Developer Interview",
            company: "Яндекс",
            date: Date(),
            type: "technical",
            isCompleted: false
        )
        let feedback = await sut.handle(effect: .navigateToInterview(interview))
        XCTAssertNil(feedback)
    }

    func testUploadProfilePhoto_emptyData_returnsFailed() async {
        let feedback = await sut.handle(effect: .uploadProfilePhoto(userId: "user-1", data: Data()))
        if case .loadingFailed(let message) = feedback {
            XCTAssertTrue(message.contains("изображение"))
        } else {
            XCTFail("Expected loadingFailed feedback")
        }
    }
}
