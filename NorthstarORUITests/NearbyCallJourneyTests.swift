import XCTest

/// Opt-in integration journey: run with RepPage/server.mjs and a joined laptop
/// browser. CI without the signaling server skips this physical-media boundary.
final class NearbyCallJourneyTests: XCTestCase {
    @MainActor func testCallReplyUsesSavedSupportAndLeavesWarningDeferred() async throws {
        let url = URL(string: "http://localhost:8080")!
        var request = URLRequest(url: url); request.timeoutInterval = 2
        let available = try? await URLSession.shared.data(for: request)
        try XCTSkipUnless(available != nil, "Requires the local rep server and a joined browser")
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.buttons["defer-item"].waitForExistence(timeout: 15))
        app.buttons["defer-item"].tap()
        let draft = app.textViews["focus-support-draft"]
        draft.tap(); draft.typeText("Where is the fictional call reference?")
        app.buttons["Hide keyboard"].tap()
        app.buttons["focus-support-send"].tap()
        app.buttons["open-call"].tap()
        let address = app.textFields["call-signaling-url"]
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        address.tap()
        address.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (address.value as? String)?.count ?? 60))
        address.typeText("ws://127.0.0.1:8080")
        if app.buttons["Hide keyboard"].exists { app.buttons["Hide keyboard"].tap() }
        app.buttons["start-call"].tap()
        let permission = addUIInterruptionMonitor(withDescription: "Microphone") { alert in
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }
            if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
            return false
        }
        defer { removeUIInterruptionMonitor(permission) }
        XCTAssertTrue(app.staticTexts["In call"].waitForExistence(timeout: 35))
        let mute = app.buttons["call-mute"]
        mute.tap()
        XCTAssertTrue(app.staticTexts["Microphone muted for this call"].exists)
        XCTAssertEqual(mute.label, "Unmute microphone")
        mute.tap()
        XCTAssertEqual(mute.label, "Mute microphone")
        let saved = app.scrollViews["rep-call-content"].buttons["Send this saved question"]
        var attempts = 0
        while !saved.isHittable && attempts < 8 {
            app.scrollViews["rep-call-content"].swipeUp(); attempts += 1
        }
        XCTAssertTrue(saved.waitForExistence(timeout: 5)); saved.tap()
        XCTAssertTrue(app.staticTexts["See the fictional call training packet."].firstMatch.waitForExistence(timeout: 30))
        capture("call-reply-retained")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["acknowledge-deferral"].exists)
        XCTAssertTrue(app.staticTexts["See the fictional call training packet."].firstMatch.exists)
        capture("focus-call-reply-warning")
        app.buttons["open-call"].tap()
        app.buttons["End call"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["acknowledge-deferral"].exists)
        XCTAssertTrue(app.staticTexts["See the fictional call training packet."].firstMatch.exists)
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
