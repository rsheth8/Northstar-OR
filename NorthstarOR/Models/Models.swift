import Foundation

// All data in Northstar OR is simulated. Nothing here is real patient data.

struct Hospital: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var town: String
    var latitude: Double? = nil
    var longitude: Double? = nil
    /// nil on legacy records; membership must be supplied explicitly for normal setup.
    var workspaceID: String? = nil
    var timeZoneIdentifier: String? = nil
    var roomLabels: [String]? = nil
}

struct DeviceRep: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var homeBase: String
    /// Stated device-family capabilities, not verified credentials.
    var skills: Set<String>
    /// Drive time to each hospital in minutes, keyed by Hospital.id. Simulated.
    var driveMinutes: [String: Int]
    var isAvailable: Bool
    /// True if the rep can join remotely (Remote Support Link) instead of driving in.
    var canSupportRemotely: Bool
    var workspaceID: String? = nil
    /// Legacy records have no stated role; technical and clinical support stay distinct.
    var statedRole: ParticipantRole? = nil
    /// nil means the age of the simulated travel inputs is unknown.
    var travelAsOf: Date? = nil
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
    /// Hours from asOf until simulated closure. Legacy nil asOf has no known baseline.
    var roadClosureInHours: Double?
    var snowfallInches: Double
    var asOf: Date? = nil

    var roadClosureAt: Date? {
        guard let asOf, let hours = roadClosureInHours, hours.isFinite else { return nil }
        return asOf.addingTimeInterval(hours * 3600)
    }
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
    /// Additive optional fields decode absent legacy keys as nil. No template is inferred.
    var workspaceID: String? = nil
    var reference: String? = nil
    var templateReference: CoordinationTemplateReference? = nil
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
