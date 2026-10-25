import Foundation

/// Fictional logistical evidence. The newest saved revision is authoritative for a site.
/// Old summary forecasts remain a projection with unknown issue times, never a new forecast.
struct PlanningEvidence: Codable, Hashable, Identifiable {
    enum Closure: Codable, Hashable {
        case unknown, noneRecorded, at(Date)
    }
    struct WeatherSample: Codable, Hashable, Identifiable {
        var timestamp: Date
        /// Snowfall in this recorded interval, not an inferred cumulative total.
        var snowfallInches: Double
        var temperatureFahrenheit: Double? = nil
        var windMPH: Double? = nil
        var id: Date { timestamp }
    }
    var id: String = UUID().uuidString
    var siteID: String
    var revision: Int = 1
    var source: String
    var scenario: String
    var recordedAt: Date? = .now
    var issuedAt: Date?
    var validFrom: Date?
    var validUntil: Date?
    var summary: String
    var closure: Closure = .unknown
    var samples: [WeatherSample] = []
    /// Legacy summaries do not establish hourly measurements.
    var summarySnowfallInches: Double? = nil

    enum ValidationError: Error, LocalizedError {
        case invalid(String)
        var errorDescription: String? { if case .invalid(let message) = self { message } else { nil } }
    }

    func validate() throws {
        func require(_ condition: Bool, _ message: String) throws {
            if !condition { throw ValidationError.invalid(message) }
        }
        try require(!id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !siteID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && revision >= 0, "Planning evidence identity is invalid.")
        try require(!source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !scenario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Enter a source, scenario and summary.")
        if let amount = summarySnowfallInches { try require(amount.isFinite && amount >= 0, "Snowfall summary must be zero or more.") }
        for date in [recordedAt, issuedAt, validFrom, validUntil].compactMap({ $0 }) {
            try require(date.timeIntervalSince1970.isFinite, "Planning dates must be valid.")
        }
        if let from = validFrom, let until = validUntil { try require(until > from, "The forecast end must be after its start.") }
        if case .at(let date) = closure { try require(date.timeIntervalSince1970.isFinite, "The road closure time must be valid.") }
        try require(Set(samples.map(\.timestamp)).count == samples.count, "Each weather sample needs a different time.")
        for sample in samples {
            try require(sample.timestamp.timeIntervalSince1970.isFinite && sample.snowfallInches.isFinite && sample.snowfallInches >= 0, "Snowfall must be zero or more at a valid time.")
            if let temperature = sample.temperatureFahrenheit { try require(temperature.isFinite, "Temperature must be a number.") }
            if let wind = sample.windMPH { try require(wind.isFinite && wind >= 0, "Wind speed must be zero or more.") }
            if let from = validFrom { try require(sample.timestamp >= from, "Weather samples must be inside the valid period.") }
            if let until = validUntil { try require(sample.timestamp <= until, "Weather samples must be inside the valid period.") }
        }
    }

    var orderedSamples: [WeatherSample] { samples.sorted { $0.timestamp < $1.timestamp } }
    var closureAt: Date? { if case .at(let date) = closure { date } else { nil } }
    func isStale(at date: Date) -> Bool {
        if let until = validUntil, date > until { return true }
        guard let issuedAt else { return true }
        return date.timeIntervalSince(issuedAt) > 6 * 3600
    }

    /// Matcher and graph receive the same revision. A known absolute closure is preserved,
    /// even if its issue time is unknown; recordedAt is only a mathematical reference here.
    var forecast: StormForecast {
        return StormForecast(summary: summary,
            roadClosureInHours: issuedAt.flatMap { baseline in closureAt.map { $0.timeIntervalSince(baseline) / 3600 } },
            snowfallInches: samples.isEmpty ? (summarySnowfallInches ?? 0) : samples.reduce(0) { $0 + $1.snowfallInches },
            asOf: issuedAt, closureIsUnknown: closure == .unknown, recordedClosureAt: closureAt)
    }

    static func legacy(siteID: String, forecast: StormForecast) -> PlanningEvidence {
        PlanningEvidence(id: "legacy-\(siteID)", siteID: siteID, revision: 0,
            source: "Legacy fictional summary", scenario: "Retained summary",
            recordedAt: forecast.asOf, issuedAt: forecast.asOf,
            summary: forecast.summary,
            closure: forecast.roadClosureAt.map(Closure.at) ?? (forecast.roadClosureInHours == nil ? .noneRecorded : .unknown),
            summarySnowfallInches: forecast.snowfallInches)
    }
}
