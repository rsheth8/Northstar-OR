import XCTest
@testable import NorthstarOR

final class PlannerScopeTests: XCTestCase {
    func testSiteLocalDayAndIndependentRetainedStatus() {
        let formatter = ISO8601DateFormatter()
        let time = formatter.date(from: "2026-11-01T05:30:00Z")!
        let procedure = Procedure(id: "independent", name: "Coordination", deviceFamily: "Fictional", hospitalID: "site", scheduledAt: time, durationMinutes: 60, steps: [])
        let scope = PlannerScope(recording: .retained, day: formatter.date(from: "2026-10-31T18:00:00Z")!)
        XCTAssertTrue(scope.includes(procedure, timeZone: TimeZone(identifier: "America/Los_Angeles")!, hasSession: true, isActive: false))
        XCTAssertFalse(scope.includes(procedure, timeZone: TimeZone(identifier: "America/Chicago")!, hasSession: true, isActive: false))
        XCTAssertFalse(scope.includes(procedure, timeZone: TimeZone(identifier: "America/Los_Angeles")!, hasSession: true, isActive: true))
    }
    func testCoordinatesRejectMissingNonfiniteAndOutOfRange() {
        XCTAssertFalse(PlannerScope.validCoordinate(latitude: nil, longitude: -93))
        XCTAssertFalse(PlannerScope.validCoordinate(latitude: .nan, longitude: -93))
        XCTAssertFalse(PlannerScope.validCoordinate(latitude: 91, longitude: -93))
        XCTAssertTrue(PlannerScope.validCoordinate(latitude: 0, longitude: 0))
    }
}
