import XCTest

/// Task walkthrough evidence, not a claim of representative-user usability validation.
final class UXAuditJourneyTests: XCTestCase {
    @MainActor func testWholeProductWalkthrough() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarResetStore"]
        app.launch()
        XCTAssertTrue(app.buttons["setup-load-sample"].waitForExistence(timeout: 15))
        capture("01-setup", app)
        app.buttons["setup-load-sample"].tap()
        XCTAssertTrue(app.buttons["planner-new-case"].waitForExistence(timeout: 10))
        capture("02-planner-empty-selection", app)
        let row = app.descendants(matching: .any)["planner-case-proc-1"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        capture("03-planner-detail", app)
        app.buttons["planner-new-case"].tap()
        XCTAssertTrue(app.buttons["case-form-save"].waitForExistence(timeout: 5))
        capture("04-new-case", app)
        app.buttons["case-form-save"].tap()
        capture("05-case-validation", app)
        app.buttons["case-form-cancel"].tap()
        app.buttons["Co-pilot"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No active case"].waitForExistence(timeout: 5))
        capture("06-copilot-no-case", app)
        app.buttons["Planner"].firstMatch.tap()
        row.tap()
        app.buttons["planner-start-recording"].tap()
        XCTAssertTrue(app.buttons["record-confirmation"].waitForExistence(timeout: 5))
        capture("07-copilot", app)
        app.buttons["defer-item"].tap()
        XCTAssertTrue(app.buttons["acknowledge-deferral"].waitForExistence(timeout: 5))
        capture("08-required-deferral", app)
        app.buttons["Activity"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Recorded activity"].waitForExistence(timeout: 5))
        capture("09-record-review", app)
        app.buttons["Done"].firstMatch.tap()
        app.buttons["acknowledge-deferral"].tap()
        app.buttons["Correct record"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Save correction"].waitForExistence(timeout: 5))
        capture("10-correction", app)
        app.buttons["Cancel"].firstMatch.tap()
        app.buttons["Remote Support"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No question from the team yet"].waitForExistence(timeout: 5))
        capture("11-support-empty", app)
        app.buttons["Connect devices"].tap()
        XCTAssertTrue(app.buttons["Find Northstar devices"].waitForExistence(timeout: 5))
        capture("12-connect", app)
        app.buttons["Done"].firstMatch.tap()
        app.buttons["header-workspace-settings"].tap()
        XCTAssertTrue(app.textFields["settings-workspace-name"].waitForExistence(timeout: 5))
        capture("13-settings", app)
        let contacts = app.buttons["settings-contacts"]
        reveal(contacts, app)
        contacts.tap()
        XCTAssertTrue(app.buttons["contacts-add"].waitForExistence(timeout: 5))
        capture("14-contacts", app)
        app.buttons["contacts-add"].tap()
        XCTAssertTrue(app.textFields["contact-name"].waitForExistence(timeout: 5))
        capture("15-new-contact", app)
    }

    @MainActor func testLargestTextRoomAndRep() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["record-confirmation"].waitForExistence(timeout: 15))
        capture("16-copilot-accessibility5", app)
        let confirm = app.buttons["record-confirmation"]
        let scroll = app.scrollViews["copilot-current-scroll"]
        var count = 0
        while !confirm.isHittable && count < 10 { scroll.swipeUp(); count += 1 }
        XCTAssertTrue(confirm.isHittable)
        capture("17-record-action-accessibility5", app)
        app.buttons["Remote Support"].firstMatch.tap()
        capture("18-support-accessibility5", app)
        app.segmentedControls["nearby-role"].buttons["Rep"].tap()
        XCTAssertTrue(app.staticTexts["No question from the team yet"].waitForExistence(timeout: 5))
        capture("19-rep-empty-accessibility5", app)
    }

    @MainActor func testSettingsSavePreservesContactEdit() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        app.launch()
        XCTAssertTrue(app.buttons["header-workspace-settings"].waitForExistence(timeout: 15))
        app.buttons["header-workspace-settings"].tap()
        let contacts = app.buttons["settings-contacts"]
        reveal(contacts, app); contacts.tap()
        app.buttons["contact-rep-ana"].tap()
        let name = app.textFields["contact-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (name.value as? String ?? "").count))
        name.typeText("Ana Lindqvist updated")
        if app.buttons["Hide keyboard"].exists { app.buttons["Hide keyboard"].tap() }
        let saveContact = app.buttons["contact-save"]
        reveal(saveContact, app); saveContact.tap()
        XCTAssertTrue(app.staticTexts["Ana Lindqvist updated"].waitForExistence(timeout: 5))
        app.navigationBars["Contacts"].buttons.firstMatch.tap()
        let saveSettings = app.buttons["settings-save"]
        reveal(saveSettings, app); saveSettings.tap()
        app.buttons["settings-done"].tap()
        app.buttons["header-workspace-settings"].tap()
        reveal(contacts, app); contacts.tap()
        capture("20-contact-after-settings-save", app)
        XCTAssertTrue(app.staticTexts["Ana Lindqvist updated"].waitForExistence(timeout: 5), "Saving workspace settings must preserve a contact saved in the same sheet")
    }

    @MainActor private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
        var count = 0
        while !element.isHittable && count < 8 {
            app.collectionViews.firstMatch.swipeUp(); count += 1
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = name; screenshot.lifetime = .keepAlways; add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = name + "-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
    }
}
