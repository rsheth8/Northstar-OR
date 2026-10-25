import XCTest

final class AdaptiveShellFormsTests: XCTestCase {
    @MainActor func testRoleChangeRequiresConfirmationAndCancelKeepsRoom() {
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        app.launch()
        XCTAssertTrue(app.buttons["nearby-role"].waitForExistence(timeout: 15))
        app.buttons["nearby-role"].tap()
        app.buttons["Rep device"].tap()
        XCTAssertTrue(app.buttons["Change role and disconnect"].waitForExistence(timeout: 5))
        capture("shell-explicit-role-change-warning")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["nearby-role"].label.contains("Room"))
    }

    @MainActor func testUnsavedSettingsRequireDiscard() {
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        app.launch()
        app.buttons["header-workspace-settings"].tap()
        let name = app.textFields["settings-workspace-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(" changed")
        app.buttons["settings-done"].tap()
        XCTAssertTrue(app.buttons["Keep editing"].waitForExistence(timeout: 5))
        capture("settings-unsaved-changes-warning")
        app.buttons["Keep editing"].tap()
        XCTAssertTrue(name.exists)
        app.buttons["settings-done"].tap()
        app.buttons["Discard changes"].tap()
        XCTAssertTrue(app.buttons["header-workspace-settings"].waitForExistence(timeout: 5))
    }
    @MainActor private func capture(_ name: String) {
        let item = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        item.name = name; item.lifetime = .keepAlways; add(item)
    }

}
