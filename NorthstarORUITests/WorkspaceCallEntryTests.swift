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
        let request = app.buttons["request-support"].firstMatch
        for _ in 0..<5 where !request.isHittable { app.scrollViews["copilot-current-scroll"].swipeUp() }
        XCTAssertTrue(request.isHittable)
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
        for _ in 0..<5 where !call.isHittable { form.swipeUp() }
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
        for _ in 0..<5 where !support.isHittable { app.scrollViews["copilot-current-scroll"].swipeUp() }
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
