import Foundation

/// The "intersect" engine: crosses rep availability, simulated travel, and device skill
/// to rank how each procedure could be covered, for a coordinator to review.
/// Rule-based on purpose (explainable to judges). It ranks; it never commits a plan.
///
/// Boundary policy, in whole minutes from `now`:
/// - Arriving with exactly the setup buffer left before the start is on time.
/// - Arriving exactly when simulated roads close is too late.
/// - A closure exactly at the case's scheduled end is outside the case window.
/// - A start at or before `now` has passed; in-person arrival is no longer possible.
struct CoverageMatcher {

    enum Option: Hashable {
        case inPersonRep(DeviceRep, arrivalMinutes: Int)
        case remoteRep(DeviceRep)
        case reschedule(reason: String)

        var title: String {
            switch self {
            case .inPersonRep(let rep, let mins): return "\(rep.name) drives in (\(mins / 60)h \(mins % 60)m)"
            case .remoteRep(let rep): return "\(rep.name) on Remote Support Link"
            case .reschedule: return "Reschedule"
            }
        }
    }

    /// The first rule that rules out in-person attendance, checked in declaration order.
    enum Constraint: Hashable {
        case technicalRoleRequired
        case notQualified
        case unavailable
        case driveTimeUnknown
        case startHasPassed
        case arrivesAfterSetupDeadline(driveMinutes: Int, minutesUntilSetupDeadline: Int)
        case arrivesAfterRoadClosure(driveMinutes: Int, minutesUntilClosure: Int)
    }

    struct RepAssessment: Hashable {
        var rep: DeviceRep
        /// nil when the rep can attend in person.
        var inPersonBlocker: Constraint?
        /// Qualified, available and able to join remotely. Separate from attending in person.
        var canSupportRemotely: Bool
        /// Plain-language explanation naming the actual constraint.
        var reason: String
    }

    struct Recommendation {
        var procedure: Procedure
        var risk: RiskLevel
        /// Ranked for review: in person by drive time, then remote, then Reschedule when no one
        /// can attend in person. Order is a suggestion, not a decision.
        var options: [Option]
        /// Plain-language reasons shown when the planner taps a procedure.
        var reasons: [String]
        /// Every rep considered, sorted by name then ID, including those not offered.
        var assessments: [RepAssessment]
        /// Minutes from `now` until simulated road closure; nil when none is recorded.
        var roadClosureMinutes: Int?
        /// True when no rep can attend in person, independent of which option is ranked first.
        var reducedSupport: Bool { !options.contains { if case .inPersonRep = $0 { return true } else { return false } } }
    }

    /// Minutes a rep needs on site before the case starts.
    var setupBufferMinutes = 45

    func recommend(for procedure: Procedure,
                   reps: [DeviceRep],
                   forecast: StormForecast?,
                   now: Date = .now) -> Recommendation {
        let minutesUntilStart = Self.minutes(from: now, to: procedure.scheduledAt)
        let closureMinutes = Self.closureMinutes(forecast, now: now)

        var reasons: [String] = []
        if let forecast {
            reasons.append(forecast.summary)
            if closureMinutes == nil { reasons.append("Forecast records no road closure.") }
        } else {
            reasons.append("No forecast recorded; road closure unknown.")
        }

        let assessments = reps
            .sorted { ($0.name, $0.id) < ($1.name, $1.id) }
            .map { assess($0, for: procedure, minutesUntilStart: minutesUntilStart, closureMinutes: closureMinutes) }
        reasons += assessments.map(\.reason)

        let inPerson: [Option] = assessments
            .compactMap { a -> (DeviceRep, Int)? in
                guard a.inPersonBlocker == nil, let drive = a.rep.driveMinutes[procedure.hospitalID] else { return nil }
                return (a.rep, drive)
            }
            .sorted { ($0.1, $0.0.name, $0.0.id) < ($1.1, $1.0.name, $1.0.id) }
            .map { Option.inPersonRep($0.0, arrivalMinutes: $0.1) }

        let remote: [Option] = assessments.filter(\.canSupportRemotely).map { .remoteRep($0.rep) }

        let caseEndMinutes = minutesUntilStart + procedure.durationMinutes
        let closesDuringWindow = closureMinutes.map { $0 < caseEndMinutes } ?? false

        let risk: RiskLevel
        var options = inPerson + remote
        if inPerson.isEmpty {
            risk = .high
            let summary = remote.isEmpty
                ? "No rep can attend in person or support remotely."
                : "No rep can attend in person."
            reasons.append(summary)
            options.append(.reschedule(reason: summary))
        } else if closesDuringWindow {
            risk = .elevated
            reasons.append("Simulated roads close during the case window, so the rep may need to leave early.")
        } else {
            risk = .low
        }

        return Recommendation(procedure: procedure, risk: risk, options: options, reasons: reasons,
                              assessments: assessments, roadClosureMinutes: closureMinutes)
    }

    private func assess(_ rep: DeviceRep, for procedure: Procedure,
                        minutesUntilStart: Int, closureMinutes: Int?) -> RepAssessment {
        let technicalRole = rep.statedRole == .technicalRep
        let qualified = technicalRole && rep.skills.contains(procedure.deviceFamily)
        let remote = qualified && rep.isAvailable && rep.canSupportRemotely
        let drive = rep.driveMinutes[procedure.hospitalID]

        let blocker: Constraint?
        if !technicalRole {
            blocker = .technicalRoleRequired
        } else if !qualified {
            blocker = .notQualified
        } else if !rep.isAvailable {
            blocker = .unavailable
        } else if drive == nil {
            blocker = .driveTimeUnknown
        } else if minutesUntilStart <= 0 {
            blocker = .startHasPassed
        } else if let drive, drive > minutesUntilStart - setupBufferMinutes {
            blocker = .arrivesAfterSetupDeadline(driveMinutes: drive,
                                                 minutesUntilSetupDeadline: minutesUntilStart - setupBufferMinutes)
        } else if let drive, let closure = closureMinutes, drive >= closure {
            blocker = .arrivesAfterRoadClosure(driveMinutes: drive, minutesUntilClosure: closure)
        } else {
            blocker = nil
        }

        var reason = "\(rep.name): " + describe(blocker, procedure: procedure, drive: drive)
        if blocker != nil && remote { reason += " Can support remotely." }
        return RepAssessment(rep: rep, inPersonBlocker: blocker, canSupportRemotely: remote, reason: reason)
    }

    private func describe(_ blocker: Constraint?, procedure: Procedure, drive: Int?) -> String {
        switch blocker {
        case nil:
            return "can attend in person (\(drive ?? 0) min simulated drive)."
        case .technicalRoleRequired:
            return "technical-rep role is not stated; technical coverage is not inferred."
        case .notQualified:
            return "\(procedure.deviceFamily) is not a stated skill."
        case .unavailable:
            return "marked unavailable."
        case .driveTimeUnknown:
            return "drive time to this site not recorded."
        case .startHasPassed:
            return "scheduled start has passed."
        case .arrivesAfterSetupDeadline(let d, let deadline):
            return "\(d) min simulated drive plus \(setupBufferMinutes) min setup does not fit the \(deadline + setupBufferMinutes) min before start."
        case .arrivesAfterRoadClosure(let d, let closure):
            return closure <= 0
                ? "simulated roads are already closed."
                : "\(d) min simulated drive arrives after the simulated road closure in \(closure) min."
        }
    }

    /// Whole minutes, rounded, so fractional fixture hours do not shift boundaries.
    private static func minutes(from start: Date, to end: Date) -> Int {
        Int((end.timeIntervalSince(start) / 60).rounded())
    }

    /// Prefers the forecast's absolute closure time; legacy forecasts without `asOf` count from `now`.
    private static func closureMinutes(_ forecast: StormForecast?, now: Date) -> Int? {
        guard let forecast else { return nil }
        if let at = forecast.roadClosureAt { return minutes(from: now, to: at) }
        guard let hours = forecast.roadClosureInHours, hours.isFinite else { return nil }
        return Int((hours * 60).rounded())
    }
}
