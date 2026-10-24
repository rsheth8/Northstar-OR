import Foundation

/// "Pull, don't call": when something deviates, the remote rep gets an auto-built
/// summary instead of a cold video call where the team has to explain everything.
struct ContextPackage {
    var procedureName: String
    var hospital: String
    var currentStep: String
    var reducedSupport: Bool
    var deviations: [String]
    var recentLog: [LogEntry]

    init(session: CoPilotSession, hospital: Hospital?, logLimit: Int = 8) {
        procedureName = session.procedure.name
        self.hospital = hospital.map { "\($0.name), \($0.town)" } ?? "Unknown hospital"
        currentStep = session.currentStep?.title ?? "Procedure complete"
        reducedSupport = session.reducedSupport
        deviations = session.procedure.steps
            .filter { session.status(of: $0) == .skipped }
            .map { "Skipped: \($0.title)" }
        recentLog = Array(session.log.suffix(logLimit))
    }

    /// True when the remote rep should be pulled in.
    var needsEscalation: Bool { !deviations.isEmpty }
}
