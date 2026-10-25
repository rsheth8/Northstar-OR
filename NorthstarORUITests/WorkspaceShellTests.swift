import XCTest

/// Setup gate and workspace header/settings wiring. Screenshots are retained for review.
final class WorkspaceShellTests: XCTestCase {
    @MainActor
    func testCleanStartShowsSetupThenCreatedWorkspaceOpensTabs() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-NorthstarResetStore"]
        app.launch()

        let name = app.textFields["setup-workspace-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        capture("Setup")
        name.tap()
        name.typeText("Fictional Test Workspace")

        let siteName = app.textFields["Site name"]
        XCTAssertTrue(siteName.exists, "site name field")
        siteName.tap()
        siteName.typeText("Fictional General")
        let town = app.textFields["Town"]
        town.tap()
        town.typeText("Exampleville")
        let participant = app.textFields["setup-participant-name"]
        participant.tap()
        participant.typeText("Sample Coordinator")

        let create = app.buttons["setup-create"]
        create.tap()
        XCTAssertTrue(app.buttons["Planner"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Fictional Test Workspace"].firstMatch.exists)
        capture("Created workspace")
    }

    @MainActor
    func testSettingsRenameShowsInHeader() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-NorthstarSampleWorkspace"]
        app.launch()

        let open = app.buttons["header-workspace-settings"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()
        let name = app.textFields["settings-workspace-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.clearAndTypeText("Renamed Fictional Workspace")
        capture("Settings edited")
        if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
        let save = app.buttons["settings-save"]
        var swipes = 0
        while !(save.exists && save.isHittable) && swipes < 8 {
            (app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch).swipeUp()
            swipes += 1
        }
        XCTAssertTrue(save.isHittable, "save button reachable")
        save.tap()
        XCTAssertTrue(app.staticTexts["settings-saved"].waitForExistence(timeout: 5))
        capture("Settings saved")
        app.buttons["settings-done"].tap()
        XCTAssertTrue(app.staticTexts["Renamed Fictional Workspace"].firstMatch.waitForExistence(timeout: 5))
        capture("Header renamed")
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(name)-landscape"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let current = value as? String, !current.isEmpty else { typeText(text); return }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        typeText(text)
    }
}
