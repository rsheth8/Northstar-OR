import Foundation

/// Content metadata only. F24 owns the canonical persisted template reference.
/// This fictional coordination exercise has no clinical validation or instructions.
enum FictionalCoordinationTemplate {
    static let id = "fictional-pacemaker-coordination"
    static let version = 1
    static let name = "Fictional pacemaker coordination"
    static let deviceFamily = "pacemaker"
    static let source = "Northstar OR fictional coordination exercise, version 1"
    static let applicability = "Recording team-reported coordination for fictional pacemaker cases only. Does not verify clinical work or outcomes."
    static let technicalSupportReplies = [
        "Which technical support question would you like to discuss?",
        "Please share the fictional model reference relevant to your question.",
        "I can discuss technical documentation; the team retains clinical decisions.",
    ]

    // Retain starter item IDs so existing records/tests keep their identity. The content
    // describes reports to record, rather than instructions to perform clinical work.
    static let steps: [ProcedureStep] = [
        ProcedureStep(id: "timeout", title: "Team brief confirmation", detail: "Record the team's statement that its own briefing was completed. This app does not conduct or verify the briefing.", isRequired: true, normallyCoveredByRep: false),
        ProcedureStep(id: "device-check", title: "Fictional device details confirmation", detail: "Record the team's statement that the fictional device details were reviewed. This records a report, not device suitability.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "programmer", title: "Technical support tools confirmation", detail: "Record the team's report about access to its technical support tools. Defer if no confirmation has been provided.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "lead-placement", title: "Team checkpoint report", detail: "Record that the team reported its own checkpoint. This app does not assess technique or determine the next clinical action.", isRequired: true, normallyCoveredByRep: false),
        ProcedureStep(id: "thresholds", title: "Technical information report", detail: "Record the team's statement that its technical information was documented in its own record. No measurements or clinical interpretation are collected here.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "connect-device", title: "Support question review", detail: "Record the team's report that outstanding technical support questions were reviewed. A reply or acknowledgment alone does not resolve an item.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "final-interrogation", title: "Technical report handoff", detail: "Record the team's statement that its technical report handoff was documented. This app does not verify the report or device function.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "closure", title: "Coordination record review", detail: "Record that the team reviewed this coordination record and any unresolved items. Recording does not certify procedure completion or outcome.", isRequired: true, normallyCoveredByRep: false),
    ]

    /// Creates an ordinary case from this content, with no sample identity dependency.
    static func makeProcedure(id: String, name: String, hospitalID: String,
                              scheduledAt: Date, durationMinutes: Int) -> Procedure {
        Procedure(id: id, name: name, deviceFamily: deviceFamily, hospitalID: hospitalID,
                  scheduledAt: scheduledAt, durationMinutes: durationMinutes, steps: steps)
    }

    /// Temporary compiling adapter until F24 pins template ID/version on each case.
    /// Matching IDs or names alone cannot authorize different or incompatible content.
    static func supports(_ procedure: Procedure) -> Bool {
        procedure.deviceFamily == deviceFamily && procedure.steps == steps && !steps.isEmpty
    }
}
