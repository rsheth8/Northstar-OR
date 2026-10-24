import XCTest

final class PlannerPresentationTests: XCTestCase {
    @MainActor func testBrowseAndFilterWithoutSwitchingRecording() {
        let app = launch()
        app.buttons["Planner"].firstMatch.tap()
        let row = app.descendants(matching: .any)["planner-case-proc-3"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.staticTexts["Fictional pacemaker case B"].waitForExistence(timeout: 5))
        capture("Planner-selected-case-default")
        app.buttons["Co-pilot"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["proc-1"].waitForExistence(timeout: 5))
        app.buttons["Planner"].firstMatch.tap()
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
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.staticTexts["Selected case"].waitForExistence(timeout: 5))
        capture("Planner-selected-case-accessibility5")
    }

    @MainActor private func launch(enlarged: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
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
