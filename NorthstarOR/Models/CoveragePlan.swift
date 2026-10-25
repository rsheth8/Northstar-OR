import Foundation

/// A coordination request, never a booking or proof of clinical readiness.
struct CoveragePlan: Codable, Hashable, Identifiable {
    enum Mode: String, Codable, CaseIterable { case inPerson, remote, reschedule }
    struct Response: Codable, Hashable {
        var planID: String
        var revision: Int
        var mode: Mode
        var actor: LocalParticipant
        var accepted: Bool
        var at: Date
        var delivery: SupportDelivery = .onThisDevice
        var messageID: String { "plan:\(planID):\(revision):response" }
    }
    var id: String
    var revision: Int
    var workspaceID: String
    var caseID: String
    var caseReference: String
    var caseName: String
    var siteName: String
    var deviceFamily: String
    var mode: Mode
    var recipient: DeviceRep?
    var requester: LocalParticipant
    var requestedAt: Date
    var response: Response?
    var delivery: SupportDelivery = .onThisDevice
    /// Local receipt metadata; never grants identity or changes the request.
    var receivedOnThisDevice: Bool? = nil
    var recordID: String { "\(id):\(revision)" }
    var messageID: String { "plan:\(recordID)" }
    var origin: SupportOrigin { .init(workspaceID: workspaceID, caseID: caseID, sessionID: "coverage-plan") }
    var modeLabel: String {
        switch mode { case .inPerson: "In-person support"; case .remote: "Remote support"; case .reschedule: "Reschedule intention" }
    }
    var statusLabel: String {
        if mode == .reschedule { return "Reschedule intention recorded; no booking changed" }
        if let response { return response.accepted ? "Acceptance recorded by \(response.actor.displayName)" : "Declined by \(response.actor.displayName)" }
        return "Awaiting response"
    }
    func validate() throws {
        let values = [id, workspaceID, caseID, caseReference, caseName, siteName, deviceFamily, requester.id, requester.displayName]
        guard values.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }), revision > 0,
              requester.workspaceID == workspaceID, requestedAt.timeIntervalSince1970.isFinite else { throw CoveragePlanError.invalid }
        if mode == .reschedule {
            guard recipient == nil, response == nil else { throw CoveragePlanError.invalid }
        } else {
            guard let recipient, recipient.statedRole == .technicalRep, recipient.skills.contains(deviceFamily),
                  !recipient.id.isEmpty, !recipient.name.isEmpty else { throw CoveragePlanError.invalid }
        }
        if let response {
            guard response.planID == id, response.revision == revision, response.mode == mode,
                  response.actor.statedRole == .technicalRep,
                  [response.actor.id, response.actor.workspaceID, response.actor.displayName].allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                  response.at.timeIntervalSince1970.isFinite else { throw CoveragePlanError.invalid }
        }
    }
    func applying(_ response: Response) throws -> CoveragePlan {
        if var existing = self.response {
            var incoming = response
            existing.delivery = .onThisDevice; incoming.delivery = .onThisDevice
            guard existing == incoming else { throw CoveragePlanError.alreadyAnswered }
        }
        var copy = self; copy.response = response
        try copy.validate()
        return copy
    }
    var envelope: SupportEnvelope {
        var request = self; request.response = nil; request.delivery = .onThisDevice; request.receivedOnThisDevice = nil
        return .init(id: messageID, kind: .coveragePlan, sentAt: requestedAt, origin: origin,
                     questionID: messageID, coveragePlan: request)
    }
    func responseEnvelope(_ response: Response) -> SupportEnvelope {
        .init(id: response.messageID, kind: .coveragePlanResponse, sentAt: response.at,
              origin: origin, questionID: messageID, coveragePlanResponse: response)
    }
}

enum CoveragePlanError: Error, LocalizedError {
    case invalid, changed, ineligible, alreadyAnswered, wrongDevice
    var errorDescription: String? {
        switch self {
        case .invalid: "This coverage plan is invalid. Nothing was changed."
        case .changed: "The current plan changed. Review the latest revision before responding."
        case .ineligible: "This contact is not currently offered for the requested support mode."
        case .alreadyAnswered: "A response is already recorded for this revision."
        case .wrongDevice: "Use the room device to request coverage and the rep device to respond."
        }
    }
}
