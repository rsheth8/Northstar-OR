import XCTest
@testable import NorthstarOR

final class CoPilotSessionTests: XCTestCase {
    func testSkippingRequiredStepRaisesAlertUntilAcknowledged() {
        let session = CoPilotSession(procedure: SampleData.procedures[0])
        session.completeCurrentStep()
        session.skipCurrentStep()
        XCTAssertEqual(session.pendingAlert?.id, "device-check")
        XCTAssertEqual(session.currentStep?.id, "programmer")
        session.acknowledgeAlert()
        XCTAssertNil(session.pendingAlert)
    }

    func testPlannerFlagReachesCoPilotThroughSync() {
        let model = AppModel(sync: LocalSyncService())
        let id = model.activeSession.procedure.id
        model.sync.send(.reducedSupportChanged(procedureID: id, on: true))
        XCTAssertTrue(model.activeSession.reducedSupport)
    }

    func testVoiceCommandParsing() {
        XCTAssertEqual(VoiceCommand.parse("Step complete"), .complete)
        XCTAssertEqual(VoiceCommand.parse("skip this one"), .skip)
        XCTAssertEqual(VoiceCommand.parse("confirm"), .confirm)
        XCTAssertNil(VoiceCommand.parse("hand me the clamp"))
    }
}
