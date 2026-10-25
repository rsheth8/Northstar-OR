import XCTest

final class NearbySupportJourneyTests: XCTestCase {
    @MainActor func testLocalSupportDuringPinnedWarningKeepsDeferredItem() {
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.buttons["defer-item"].waitForExistence(timeout: 15))
        app.buttons["defer-item"].tap()
        app.buttons["request-support"].tap()
        let draft = app.textViews["support-question-draft"]
        XCTAssertTrue(draft.waitForExistence(timeout: 5))
        draft.tap(); draft.typeText("Where is the fictional reference?")
        app.buttons["Hide keyboard"].tap()
        reveal(app.buttons["support-question-send"], app); app.buttons["support-question-send"].tap()
        XCTAssertTrue(app.buttons["acknowledge-deferral"].waitForExistence(timeout: 5))
        app.buttons["Remote Support"].firstMatch.tap()
        XCTAssertTrue(app.buttons["acknowledge-question"].waitForExistence(timeout: 5))
        app.buttons["acknowledge-question"].tap()
        let reply = app.textViews["support-reply-draft"]
        reveal(reply, app); reply.tap(); reply.typeText("See the fictional training packet.")
        let send = app.buttons["support-reply-send"]
        app.buttons["Hide keyboard"].tap()
        reveal(send, app)
        send.tap()
        app.buttons["Co-pilot"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["See the fictional training packet."].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["acknowledge-deferral"].exists)
        XCUIDevice.shared.orientation = .landscapeRight
        capture(app, "nearby-local-reply-warning")
        app.buttons["acknowledge-deferral"].tap()
        XCTAssertFalse(app.buttons["record-confirmation"].exists)
    }
    @MainActor private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
        var n = 0; while !element.isHittable && n < 12 { app.swipeUp(); n += 1 }; XCTAssertTrue(element.isHittable)
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
