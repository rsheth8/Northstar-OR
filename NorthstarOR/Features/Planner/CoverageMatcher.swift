import Foundation

/// The "intersect" engine: crosses rep availability, road conditions, and device skill
/// to recommend how each at-risk procedure should be covered.
/// Rule-based on purpose (explainable to judges); swap in a smarter model later.
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

    struct Recommendation {
        var procedure: Procedure
        var risk: RiskLevel
        /// Best option first.
        var options: [Option]
        /// Plain-language reasons shown when the planner taps a procedure.
        var reasons: [String]
        /// True when the co-pilot should start in reduced-support mode.
        var reducedSupport: Bool { if case .inPersonRep? = options.first { return false } else { return true } }
    }

    /// Minutes a rep needs on site before the case starts.
    var setupBufferMinutes = 45

    func recommend(for procedure: Procedure,
                   reps: [DeviceRep],
                   forecast: StormForecast?,
                   now: Date = .now) -> Recommendation {
        let minutesUntilStart = Int(procedure.scheduledAt.timeIntervalSince(now) / 60)
        let closureMinutes = forecast?.roadClosureInHours.map { Int($0 * 60) }
        var reasons: [String] = []
        if let forecast { reasons.append(forecast.summary) }

        let qualified = reps.filter { $0.skills.contains(procedure.deviceFamily) }
        if qualified.isEmpty { reasons.append("No rep is certified for \(procedure.deviceFamily).") }

        // In person: rep is free, arrives with setup buffer before the case, and before roads close.
        let inPerson: [Option] = qualified
            .filter(\.isAvailable)
            .compactMap { rep -> (DeviceRep, Int)? in
                guard let drive = rep.driveMinutes[procedure.hospitalID] else { return nil }
                guard drive + setupBufferMinutes <= minutesUntilStart else { return nil }
                if let closure = closureMinutes, drive >= closure { return nil }
                return (rep, drive)
            }
            .sorted { $0.1 < $1.1 }
            .map { Option.inPersonRep($0.0, arrivalMinutes: $0.1) }

        let remote: [Option] = qualified
            .filter(\.canSupportRemotely)
            .map(Option.remoteRep)

        // Roads close before the case would end.
        let closesDuringWindow = closureMinutes.map { $0 < minutesUntilStart + procedure.durationMinutes } ?? false

        let risk: RiskLevel
        if inPerson.isEmpty && (closesDuringWindow || qualified.allSatisfy { !$0.isAvailable }) {
            risk = .high
            reasons.append("No certified rep can reach \(procedure.hospitalID) before roads close.")
        } else if closesDuringWindow {
            risk = .elevated
            reasons.append("Roads close during the case window, so the rep must leave soon.")
        } else {
            risk = .low
        }

        var options = inPerson + remote
        if risk == .high { options.append(.reschedule(reason: "Storm closes roads before the case ends.")) }
        if options.isEmpty { options = [.reschedule(reason: "No coverage available.")] }

        return Recommendation(procedure: procedure, risk: risk, options: options, reasons: reasons)
    }
}
