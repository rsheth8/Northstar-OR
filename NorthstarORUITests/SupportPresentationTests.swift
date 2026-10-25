import XCTest

final class SupportPresentationTests: XCTestCase {
    @MainActor func testLocalDraftNavigationAndMessage() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-NorthstarSampleWorkspace"]
        app.launch()
        XCTAssertTrue(app.buttons["Remote Support"].firstMatch.waitForExistence(timeout: 15))
        app.buttons["Remote Support"].firstMatch.tap()
        // SwiftUI Menu labels reject the AX scroll-to-visible action XCUITest
        // uses before tapping; the control is on screen, so tap its center.
        app.buttons["Suggested text"].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let prompt = "Which technical support question would you like to discuss?"
        app.buttons[prompt].firstMatch.tap()
        let draft = app.descendants(matching: .any)["support-draft"].firstMatch
        XCTAssertTrue(draft.exists)
        app.buttons["Planner"].firstMatch.tap()
        app.buttons["Remote Support"].firstMatch.tap()
        XCTAssertEqual(draft.value as? String, prompt)
        draft.tap()
        capture("Remote-support-keyboard-draft")
        XCTAssertTrue(app.buttons["support-send"].isHittable)
        app.buttons["support-send"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", prompt)).firstMatch.waitForExistence(timeout: 5))
        capture("Remote-support-local-message")
    }

    @MainActor func testEnlargedTextBrief() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-NorthstarSampleWorkspace"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["Remote Support"].firstMatch.waitForExistence(timeout: 15))
        app.buttons["Remote Support"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["support-draft"].firstMatch.waitForExistence(timeout: 5))
        capture("Remote-support-accessibility5")
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
