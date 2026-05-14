import XCTest

final class InterPrepUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingLeadsToRegistration() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.buttons["Зарегистрироваться"].waitForExistence(timeout: 10))
        app.buttons["Зарегистрироваться"].tap()

        XCTAssertTrue(app.textFields["Имя"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.textFields["Фамилия"].exists)
    }
}
