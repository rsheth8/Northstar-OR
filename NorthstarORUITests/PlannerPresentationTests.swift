import XCTest

final class PlannerPresentationTests: XCTestCase {
    @MainActor func testBrowseAndFilterWithoutSwitchingRecording() {
        let app = launch()
        app.buttons["Planner"].firstMatch.tap()
        let row = app.descendants(matching: .any)["planner-case-proc-3"].firstMatch
        reveal(row, in: app)
        row.tap()
        XCTAssertTrue(app.staticTexts["Fictional pacemaker case B"].waitForExistence(timeout: 5))
        // Browsing proc-3 must not move the recording, which stays on proc-1.
        let notActive = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Not active on this device")).firstMatch
        XCTAssertTrue(notActive.exists)
        capture("Planner-selected-case-default")
        app.buttons["Co-pilot"].firstMatch.tap()
        app.buttons["Planner"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Fictional pacemaker case B"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        if search.isHittable {
            search.tap()
            search.typeText("No matching fictional case")
            XCTAssertTrue(app.staticTexts["No matching cases"].waitForExistence(timeout: 5))
            capture("Planner-filter-empty")
        }
    }

    @MainActor func testSelectedCaseAtEnlargedText() {
        let app = launch(enlarged: true)
        app.buttons["Planner"].firstMatch.tap()
        let row = app.descendants(matching: .any)["planner-case-proc-1"].firstMatch
        reveal(row, in: app)
        row.tap()
        XCTAssertTrue(app.staticTexts["Selected case"].waitForExistence(timeout: 5))
        capture("Planner-selected-case-accessibility5")
    }

    @MainActor private func reveal(_ row: XCUIElement, in app: XCUIApplication) {
        let list = app.descendants(matching: .any).matching(identifier: "planner-worklist").firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        for _ in 0..<10 where !row.exists || !row.isHittable { list.swipeUp() }
        XCTAssertTrue(row.exists)
        XCTAssertTrue(row.isHittable, "A case must remain reachable below the enlarged filter controls")
    }

    @MainActor private func launch(enlarged: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-NorthstarSampleWorkspace"]
        if enlarged { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["Planner"].firstMatch.waitForExistence(timeout: 15))
        return app
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
