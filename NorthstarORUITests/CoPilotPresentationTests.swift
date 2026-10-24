import XCTest

final class CoPilotPresentationTests: XCTestCase {
    @MainActor func testDeferralAcknowledgmentAndCorrection() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        let deferButton = app.buttons["defer-item"].firstMatch
        XCTAssertTrue(deferButton.waitForExistence(timeout: 15))
        deferButton.tap()
        let acknowledgment = app.buttons["acknowledge-deferral"].firstMatch
        XCTAssertTrue(acknowledgment.waitForExistence(timeout: 5))
        capture("Co-pilot-required-deferral")
        acknowledgment.tap()
        XCTAssertFalse(app.buttons["record-confirmation"].exists)
        XCTAssertTrue(app.buttons["Correct record"].firstMatch.exists)
        capture("Co-pilot-acknowledged-still-deferred")
        app.buttons["Correct record"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Save correction"].waitForExistence(timeout: 5))
        capture("Co-pilot-correction-sheet")
        app.buttons["Save correction"].tap()
        XCTAssertTrue(app.buttons["record-confirmation"].waitForExistence(timeout: 5))
    }

    @MainActor func testPortraitWorkspace() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["record-confirmation"].waitForExistence(timeout: 15))
        capture("Co-pilot-portrait")
    }

    @MainActor func testEnlargedTextWorkspace() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["record-confirmation"].waitForExistence(timeout: 15))
        capture("Co-pilot-accessibility5")
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
