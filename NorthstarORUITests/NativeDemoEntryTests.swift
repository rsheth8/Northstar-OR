import XCTest

final class NativeDemoEntryTests: XCTestCase {
    @MainActor func testNormalSampleLaunchCanOpenFormAndStartRecording() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-NorthstarResetStore"]
        app.launch()
        let form = app.descendants(matching: .any).matching(identifier: "workspace-setup-form").firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 15))
        let sample = app.buttons["setup-load-sample"]
        for _ in 0..<12 where !sample.exists || !sample.isHittable { form.swipeUp() }
        XCTAssertTrue(sample.exists)
        XCTAssertTrue(sample.isHittable)
        sample.tap()
        let create = app.buttons["planner-new-case"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        create.tap()
        XCTAssertTrue(app.buttons["case-form-save"].waitForExistence(timeout: 5))
        app.buttons["case-form-cancel"].tap()
        let row = app.descendants(matching: .any)["planner-case-proc-1"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        let start = app.buttons["planner-start-recording"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        if !start.isHittable { app.swipeUp() }
        start.tap()
        XCTAssertTrue(app.buttons["record-confirmation"].waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Native demo normal start — iPad landscape"
        screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
