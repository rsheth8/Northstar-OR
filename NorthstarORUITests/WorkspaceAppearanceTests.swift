import XCTest

/// Native rendering evidence. Attachments are retained for visual inspection;
/// these captures are not a substitute for physical-device accessibility checks.
final class WorkspaceAppearanceTests: XCTestCase {
    @MainActor
    func testDefaultWorkspaceScreens() {
        captureWorkspace(enlarged: false)
    }

    @MainActor
    func testEnlargedWorkspaceScreens() {
        captureWorkspace(enlarged: true)
    }

    @MainActor
    private func captureWorkspace(enlarged: Bool) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-NorthstarSampleWorkspace"]
        if enlarged {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["Planner"].firstMatch.waitForExistence(timeout: 15))
        capture("Co-pilot", enlarged: enlarged)
        app.buttons["Planner"].firstMatch.tap()
        capture("Planner", enlarged: enlarged)
        app.buttons["Remote Support"].firstMatch.tap()
        capture("Remote Support", enlarged: enlarged)
    }

    @MainActor
    private func capture(_ name: String, enlarged: Bool) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(name)-\(enlarged ? "accessibility5" : "default")-landscape"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
