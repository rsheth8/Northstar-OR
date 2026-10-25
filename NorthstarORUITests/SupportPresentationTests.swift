import XCTest

final class SupportPresentationTests: XCTestCase {
    @MainActor func testLocalDraftNavigationAndMessage() {
        continueAfterFailure = false
        let app = launch()
        app.buttons["request-support"].tap()
        let question = app.textViews["support-question-draft"]
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap(); question.typeText("Where is the fictional reference?")
        app.buttons["Hide keyboard"].tap()
        let send = app.buttons["support-question-send"]
        scrollTo(send, app)
        send.tap()
        app.buttons["Remote Support"].firstMatch.tap()
        let draft = app.textViews["support-reply-draft"]
        XCTAssertTrue(draft.waitForExistence(timeout: 5))
        scrollTo(draft, app); draft.tap(); draft.typeText("See the fictional training packet.")
        app.buttons["Hide keyboard"].tap()
        app.buttons["Planner"].firstMatch.tap(); app.buttons["Remote Support"].firstMatch.tap()
        XCTAssertEqual(draft.value as? String, "See the fictional training packet.")
        capture("Remote-support-keyboard-draft")
        let reply = app.buttons["support-reply-send"]; scrollTo(reply, app); reply.tap()
        XCTAssertTrue(app.staticTexts["See the fictional training packet."].firstMatch.waitForExistence(timeout: 5))
        capture("Remote-support-local-message")
    }
    @MainActor func testEnlargedTextBrief() {
        continueAfterFailure = false
        let app = launch(enlarged: true)
        app.buttons["Remote Support"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No question from the team yet"].waitForExistence(timeout: 5))
        capture("Remote-support-accessibility5-empty")
        app.buttons["Co-pilot"].firstMatch.tap()
        let request = app.buttons["request-support"]; scrollTo(request, app); request.tap()
        let question = app.textViews["support-question-draft"]
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap(); question.typeText("Fictional enlarged-text question")
        app.buttons["Hide keyboard"].tap()
        let send = app.buttons["support-question-send"]; scrollTo(send, app)
        XCTAssertTrue(send.isEnabled)
        capture("Support-request-accessibility5")
        send.tap()
        app.buttons["Remote Support"].firstMatch.tap()
        let ack = app.buttons["acknowledge-question"]
        XCTAssertTrue(ack.waitForExistence(timeout: 5)); scrollTo(ack, app)
        capture("Support-brief-accessibility5")
    }
    @MainActor private func launch(enlarged: Bool = false) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchArguments = ["-NorthstarSampleWorkspace"]
        if enlarged { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch(); XCTAssertTrue(app.buttons["request-support"].waitForExistence(timeout: 15)); return app
    }
    @MainActor private func scrollTo(_ element: XCUIElement, _ app: XCUIApplication) {
        var count = 0
        while !element.isHittable && count < 12 {
            if app.navigationBars["Request support"].exists { app.collectionViews.firstMatch.swipeUp() }
            else if app.scrollViews["copilot-current-scroll"].exists { app.scrollViews["copilot-current-scroll"].swipeUp() }
            else { app.scrollViews.firstMatch.swipeUp() }
            count += 1
        }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
