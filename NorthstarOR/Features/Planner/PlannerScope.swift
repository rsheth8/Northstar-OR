import Foundation

struct PlannerScope {
    enum Recording: String, CaseIterable, Identifiable {
        case all = "All recordings", notStarted = "Not started", retained = "Retained recording", active = "Active recording"
        var id: String { rawValue }
    }
    var recording: Recording = .all
    var day: Date?

    func includes(_ procedure: Procedure, timeZone: TimeZone, hasSession: Bool, isActive: Bool) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if let day, !calendar.isDate(procedure.scheduledAt, inSameDayAs: day) { return false }
        switch recording {
        case .all: return true
        case .notStarted: return !hasSession
        case .retained: return hasSession && !isActive
        case .active: return isActive
        }
    }
    static func validCoordinate(latitude: Double?, longitude: Double?) -> Bool {
        guard let latitude, let longitude else { return false }
        return latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
}
