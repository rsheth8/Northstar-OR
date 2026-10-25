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
        finishEntry(town, expected: "Exampleville", in: app)
        let participant = app.textFields["setup-participant-name"]
        revealSetupControl(participant, in: app)
        participant.tap()
        participant.typeText("Sample Coordinator")
        finishEntry(participant, expected: "Sample Coordinator", in: app)


        let create = app.buttons["setup-create"]
        revealSetupControl(create, in: app)
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

    /// Reveal below-fold fields before activation. XCTest's automatic scroll during
    /// tap can leave a field visible without focusing it when a keyboard is open.
    @MainActor
    private func revealSetupControl(_ control: XCUIElement, in app: XCUIApplication) {
        let form = app.descendants(matching: .any).matching(identifier: "workspace-setup-form").firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5))
        for _ in 0..<12 {
            let window = app.windows.firstMatch.frame
            let keyboard = app.keyboards.firstMatch
            let bottom = keyboard.exists && keyboard.frame.height > 100
                ? min(window.maxY, keyboard.frame.minY) : window.maxY
            let top = max(window.minY, app.navigationBars.firstMatch.frame.maxY)
            if control.exists && control.frame.minY >= top + 12 && control.frame.maxY < bottom - 12 {
                XCTAssertTrue(control.isHittable)
                return
            }
            // Keep the gesture inside the visible form, above the keyboard.
            let origin = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            let start = origin.withOffset(CGVector(dx: 0, dy: top + (bottom - top) * 0.8))
            let end = origin.withOffset(CGVector(dx: 0, dy: top + (bottom - top) * 0.3))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Setup control must be visible above the keyboard before activation: \(control.identifier)")
    }

    @MainActor
    private func finishEntry(_ field: XCUIElement, expected: String, in app: XCUIApplication) {
        // Submit through the focused field, without relying on remote keyboard
        // coordinates while the iPad is in landscape.
        field.typeText("\n")
        XCTAssertEqual(field.value as? String, expected)
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.keyboards.firstMatch)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed, "Finish text entry before activating a lower setup field")
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
