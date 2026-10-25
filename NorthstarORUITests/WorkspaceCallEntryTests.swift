import XCTest

final class WorkspaceCallEntryTests: XCTestCase {
    @MainActor func testHelpOffersCallWithoutLosingQuestionOrDeferredWarning() {
        verifyHelp(enlarged: false)
    }
    @MainActor func testHelpCallEntryWithEnlargedText() {
        verifyHelp(enlarged: true)
    }
    @MainActor private func verifyHelp(enlarged: Bool) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        if enlarged { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        let deferItem = app.buttons["defer-item"].firstMatch
        XCTAssertTrue(deferItem.waitForExistence(timeout: 15))
        deferItem.tap()
        let acknowledgment = app.buttons["acknowledge-deferral"].firstMatch
        XCTAssertTrue(acknowledgment.waitForExistence(timeout: 5), "Defer must record a deferral and pin its acknowledgment")
        XCTAssertFalse(app.buttons["record-confirmation"].exists, "Deferral must not activate confirmation")
        let deferred = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        deferred.name = enlarged ? "recording-deferral-largest-text" : "recording-deferral-default"
        deferred.lifetime = .keepAlways; add(deferred)
        let request = app.buttons["request-support"].firstMatch
        // XCTest scrolls this unique accessibility target into view before activation.
        // Large manual swipes can skip over it in the short enlarged-text viewport.
        request.tap()
        let requestForm = app.descendants(matching: .any).matching(identifier: "support-request-form").firstMatch
        XCTAssertTrue(requestForm.waitForExistence(timeout: 5), "Request support must open its composer")
        let draft = app.textViews["support-question-draft"]
        for _ in 0..<5 where !draft.exists || !draft.isHittable { requestForm.swipeUp() }
        XCTAssertTrue(draft.exists)
        XCTAssertTrue(draft.isHittable, "The question must remain editable at enlarged text")
        draft.tap(); draft.typeText("Fictional technical support question")
        // Dismiss the keyboard while preserving the saved question.
        app.buttons["Done typing"].tap()
        let form = app.descendants(matching: .any).matching(identifier: "support-request-form").firstMatch
        let call = form.buttons["request-call"].firstMatch
        // A disabled call control is intentionally not an activation target.
        // Reveal its accessibility element without scrolling past it while
        // waiting for a hit point that a disabled control need not provide.
        for _ in 0..<5 where !call.exists { form.swipeUp() }
        XCTAssertTrue(call.exists)
        XCTAssertFalse(call.isEnabled, "An unpaired device must not claim it can call")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = enlarged ? "Help-call-accessibility5-disconnected" : "Help-call-landscape-disconnected"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["acknowledge-deferral"].firstMatch.exists)
        XCTAssertFalse(app.buttons["record-confirmation"].exists)
        let support = app.buttons["request-support"].firstMatch
        support.tap()
        XCTAssertEqual(app.textViews["support-question-draft"].value as? String, "Fictional technical support question")
        if !enlarged {
            let requestForm = app.descendants(matching: .any).matching(identifier: "support-request-form").firstMatch
            let topic = requestForm.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "support-topic-")).firstMatch
            for _ in 0..<8 where !topic.isHittable { requestForm.swipeUp() }
            XCTAssertTrue(topic.isHittable)
            topic.tap()
            let input = app.textViews["support-question-draft"]
            for _ in 0..<8 where !input.exists { requestForm.swipeDown() }
            let question = input.value as? String ?? ""
            XCTAssertTrue(question.contains("Fictional technical support question"))
            XCTAssertTrue(question.contains("Question about"))
            if app.buttons["Done typing"].exists { app.buttons["Done typing"].tap() }
            let send = requestForm.buttons["support-question-send"]
            for _ in 0..<8 where !send.isHittable { requestForm.swipeDown() }
            XCTAssertTrue(send.isEnabled)
            send.tap()
            XCTAssertTrue(app.buttons["acknowledge-deferral"].firstMatch.waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["record-confirmation"].exists)
        }
    }
}
