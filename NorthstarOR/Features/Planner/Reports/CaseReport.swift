import Foundation

/// Value snapshot: review/export never reads a changing live session.
struct CaseReport: Identifiable {
    struct Item: Identifiable {
        let id: String
        let title: String
        let status: RecordedItemStatus
    }
    let id = UUID()
    let procedure: Procedure
    let site: Hospital?
    let capturedAt: Date
    let state: SessionRecordingState?
    let items: [Item]
    let events: [SessionEvent]
    let questions: [SupportQuestion]
    let notes: [SessionNote]
    let forecast: StormForecast?
    let planningEvidence: PlanningEvidence?
    let coveragePlan: CoveragePlan?

    init(procedure: Procedure, site: Hospital?, state: SessionRecordingState?, events: [SessionEvent], questions: [SupportQuestion], notes: [SessionNote] = [], forecast: StormForecast?, capturedAt: Date, planningEvidence: PlanningEvidence? = nil, coveragePlan: CoveragePlan? = nil) {
        self.procedure = procedure; self.site = site; self.capturedAt = capturedAt
        self.coveragePlan = coveragePlan?.caseID == procedure.id && coveragePlan?.workspaceID == procedure.workspaceID ? coveragePlan : nil
        let matching = state?.identity.caseID == procedure.id && state?.identity.workspaceID == procedure.workspaceID ? state : nil
        self.state = matching
        self.items = procedure.steps.map { Item(id: $0.id, title: $0.title, status: matching?.itemStatuses[$0.id] ?? .unrecorded) }
            .sorted { ($0.status == .teamConfirmed ? 1 : 0, $0.id) < ($1.status == .teamConfirmed ? 1 : 0, $1.id) }
        self.events = events.filter { $0.identity == matching?.identity }.sorted { $0.acceptedVersion < $1.acceptedVersion }
        self.questions = questions.filter { $0.caseID == procedure.id && $0.workspaceID == procedure.workspaceID && $0.sessionID == matching?.identity.sessionID }.sorted { ($0.sentAt, $0.id) < ($1.sentAt, $1.id) }
        self.notes = notes.filter { $0.caseID == procedure.id && $0.workspaceID == procedure.workspaceID && $0.sessionID == matching?.identity.sessionID }
            .sorted { ($0.sentAt, $0.id) < ($1.sentAt, $1.id) }
        self.planningEvidence = planningEvidence?.siteID == procedure.hospitalID ? planningEvidence : nil
        self.forecast = self.planningEvidence?.forecast ?? forecast
    }
    func date(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = site?.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "MMM d, yyyy h:mm a zzz"
        return formatter.string(from: value)
    }
    static func status(_ value: RecordedItemStatus) -> String {
        switch value { case .unrecorded: "Unrecorded"; case .deferred: "Deferred"; case .teamConfirmed: "Team confirmed" }
    }
    var text: String {
        var lines = ["NORTHSTAR OR · SIMULATED CASE RECORD", "Case: \(procedure.reference ?? procedure.id)", procedure.name,
                     "Site: \(site?.name ?? "Not recorded")", "Scheduled: \(date(procedure.scheduledAt))", "Snapshot: \(date(capturedAt))",
                     "Time zone: \(site?.timeZoneIdentifier ?? "Unknown; UTC shown")", "Session: \(state?.identity.sessionID ?? "No recording")",
                     "Template: \(procedure.templateReference.map { "\($0.id) v\($0.version)" } ?? "Not recorded")",
                     "Support plan: \(coveragePlan.map { "\($0.modeLabel) · Revision \($0.revision) · \($0.statusLabel)" } ?? "Not recorded")"]
        if let coveragePlan {
            lines += ["Requested contact: \(coveragePlan.recipient?.name ?? "None; reschedule intention")",
                      "Requested by: \(coveragePlan.requester.displayName) at \(date(coveragePlan.requestedAt))",
                      "Plan request delivery: \(coveragePlan.delivery.label)"]
            if let response = coveragePlan.response {
                lines += ["Responding device participant: \(response.actor.displayName) at \(date(response.at))",
                          "Plan response delivery: \(response.delivery.label)"]
            }
            lines += ["Call connection is separate and is not captured in this report.", ""]
        }
        lines += ["", "RECORDED ITEMS · UNRESOLVED FIRST"]
        lines += items.map { "\(Self.status($0.status)): \($0.title)" }
        lines += ["", "RECORDING HISTORY · ACTOR / SOURCE / TIME"]
        lines += events.map { "\(date($0.occurredAt)) · \($0.actor.displayName) · \($0.source.label) · \($0.targetItemID): \(eventLabel($0.payload))" }
        if events.isEmpty { lines += ["No recorded events"] }
        lines += ["", "SUPPORT EXCHANGES"]
        for question in questions {
            lines += ["\(date(question.sentAt)) · \(question.sender.displayName) → \(question.recipientName): \(question.text)", "Delivery: \(question.delivery.rawValue)", "Acknowledgment: \(question.questionAcknowledgedBy ?? "Not recorded")"]
            if let reply = question.reply { lines += ["\(date(reply.at)) · \(reply.from): \(reply.text)"] }
        }
        if questions.isEmpty { lines += ["No support questions recorded for this session"] }
        lines += ["", "GENERAL SUPPORT MESSAGES · ACTOR / SOURCE / TIME"]
        lines += notes.map { "\(date($0.sentAt)) · \($0.actor.displayName) · General message: \($0.text)\nDelivery: \($0.delivery.rawValue)" }
        if notes.isEmpty { lines += ["No general support messages recorded for this session"] }
        lines += ["", "SIMULATED WEATHER", forecast?.summary ?? "No forecast recorded", "As of: \(forecast?.asOf.map(date) ?? "Unknown")", "Road closure: \(forecast?.roadClosureAt.map(date) ?? "Not recorded with an absolute time")", "", "Recorded coordination only. This report does not establish clinical readiness or outcome."]
        if let planningEvidence {
            lines += ["Evidence revision: \(planningEvidence.revision)", "Source: \(planningEvidence.source)", "Scenario: \(planningEvidence.scenario)",
                      "Recorded: \(planningEvidence.recordedAt.map(date) ?? "Unknown")"]
        }
        return lines.joined(separator: "\n")
    }
    private func eventLabel(_ payload: SessionEventPayload) -> String {
        switch payload {
        case .itemSelected: "Selected"
        case .confirmationRecorded: "Team confirmation recorded"
        case .itemDeferred: "Deferred"
        case .warningAcknowledged: "Warning acknowledged; item remains unresolved"
        case .recordCorrected(let original, let status, let reason, _, _): "Correction of \(original) → \(Self.status(status))\(reason.map { ": \($0)" } ?? "")"
        }
    }
}
