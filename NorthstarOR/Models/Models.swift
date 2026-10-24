import Foundation

// All data in Northstar OR is simulated. Nothing here is real patient data.

struct Hospital: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var town: String
    var latitude: Double
    var longitude: Double
}

struct DeviceRep: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var homeBase: String
    /// Device families this rep is certified to support, e.g. "pacemaker".
    var skills: Set<String>
    /// Drive time to each hospital in minutes, keyed by Hospital.id. Simulated.
    var driveMinutes: [String: Int]
    var isAvailable: Bool
    /// True if the rep can join remotely (Remote Support Link) instead of driving in.
    var canSupportRemotely: Bool
}

enum RiskLevel: String, Codable, Comparable, CaseIterable {
    case low, elevated, high

    static func < (a: RiskLevel, b: RiskLevel) -> Bool {
        let order: [RiskLevel] = [.low, .elevated, .high]
        return order.firstIndex(of: a)! < order.firstIndex(of: b)!
    }
}

struct StormForecast: Hashable, Codable {
    var summary: String
    /// Hours from now until roads near the hospital are expected to close. nil = no closure expected.
    var roadClosureInHours: Double?
    var snowfallInches: Double
}

struct ProcedureStep: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var detail: String
    /// Required steps raise an alert when skipped.
    var isRequired: Bool
    /// Steps the device rep would normally cover in person.
    var normallyCoveredByRep: Bool
}

struct Procedure: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var deviceFamily: String
    var hospitalID: String
    var scheduledAt: Date
    var durationMinutes: Int
    var steps: [ProcedureStep]
}

enum StepStatus: String, Codable {
    case upcoming, current, completed, skipped
}

struct LogEntry: Identifiable, Hashable, Codable {
    enum Kind: String, Codable { case stepCompleted, stepSkipped, alert, note, remoteMessage, modeChange }
    let id: UUID
    var timestamp: Date
    var kind: Kind
    var message: String

    init(_ kind: Kind, _ message: String, at timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
        self.kind = kind
        self.message = message
    }
}
