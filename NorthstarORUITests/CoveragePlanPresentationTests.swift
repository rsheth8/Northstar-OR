import XCTest

final class CoveragePlanPresentationTests: XCTestCase {
    @MainActor func testRequestAndExplicitReplacement() { verify(enlarged: false) }
    @MainActor func testRequestAndReplacementAtLargestText() { verify(enlarged: true) }

    @MainActor func testRepCoverageInboxHasAnHonestEmptyState() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        app.launch()
        XCTAssertTrue(app.buttons["Remote Support"].firstMatch.waitForExistence(timeout: 15))
        if app.buttons["nearby-role"].exists {
            app.buttons["nearby-role"].tap()
            app.buttons["Rep device"].tap()
            if app.buttons["Change role and disconnect"].waitForExistence(timeout: 2) {
                app.buttons["Change role and disconnect"].tap()
            }
        } else { app.buttons["Rep"].firstMatch.tap() }
        app.buttons["Remote Support"].firstMatch.tap()
        let inbox = app.buttons["open-coverage-requests"]
        XCTAssertTrue(inbox.waitForExistence(timeout: 5)); inbox.tap()
        XCTAssertTrue(app.staticTexts["No coverage requests received"].waitForExistence(timeout: 5))
        capture("coverage-rep-inbox-empty-disconnected")
    }

    @MainActor private func verify(enlarged: Bool) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarSampleWorkspace"]
        if enlarged { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["Planner"].firstMatch.waitForExistence(timeout: 15))
        app.buttons["Planner"].firstMatch.tap()
        let row = app.descendants(matching: .any)["planner-case-proc-1"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        let detail = app.scrollViews["planner-case-detail-scroll"]
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        let request = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "coverage-request-remote-")).firstMatch
        reveal(request, scrolling: detail, up: true)
        request.tap()
        let revision = app.staticTexts["Remote support · Revision 1"]
        reveal(revision, scrolling: detail, up: false)
        XCTAssertTrue(app.staticTexts["Awaiting response"].exists)
        capture(enlarged ? "coverage-request-largest-text" : "coverage-request-default")
        let reschedule = app.buttons["coverage-request-reschedule-none"]
        reveal(reschedule, scrolling: detail, up: true)
        reschedule.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        app.alerts.buttons["Keep current plan"].tap()
        reveal(reschedule, scrolling: detail, up: true)
        reschedule.tap()
        app.alerts.buttons["Replace plan"].tap()
        let replaced = app.staticTexts["Reschedule intention · Revision 2"]
        reveal(replaced, scrolling: detail, up: false)
        XCTAssertTrue(app.staticTexts["Reschedule intention recorded; no booking changed"].exists)
        capture(enlarged ? "coverage-replaced-largest-text" : "coverage-replaced-default")
    }
    @MainActor private func reveal(_ element: XCUIElement, scrolling scroll: XCUIElement, up: Bool) {
        for _ in 0..<20 where !element.exists || !element.isHittable {
            // The split-view scroll container's accessibility frame can include its sidebar.
            // Drag inside the visible detail pane rather than its geometric center.
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: up ? 0.85 : 0.25))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: up ? 0.25 : 0.85))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        if !element.exists || !element.isHittable {
            let debug = XCTAttachment(string: XCUIApplication().debugDescription)
            debug.name = "Coverage controls hierarchy"; debug.lifetime = .keepAlways; add(debug)
            capture("coverage-controls-unreachable")
        }
        XCTAssertTrue(element.exists)
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func capture(_ name: String) {
        let item = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        item.name = name; item.lifetime = .keepAlways; add(item)
    }
}
