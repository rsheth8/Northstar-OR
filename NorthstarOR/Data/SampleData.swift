import Foundation

/// Optional, fictional seed content. Every person, facility and input is made up.
/// Creating a seed creates ordinary model records, never progress or support acceptance.
/// F07/F25 will replace the starter's automatic startup use with explicit sample loading.
enum SampleData {
    enum Record: String, CaseIterable {
        case northShoreSite = "grand-marais"
        case lakesSite = "bemidji"
        case prairieSite = "worthington"
        case anaContact = "rep-ana"
        case marcusContact = "rep-marcus"
        case priyaContact = "rep-priya"
        case northShoreCase = "proc-1"
        case unsupportedCase = "proc-2"
        case lakesCase = "proc-3"
    }

    /// A content bundle using existing public model types, not a persistence schema.
    struct Seed {
        /// Baseline for all simulated forecast and travel inputs in this bundle.
        let asOf: Date
        let hospitals: [Hospital]
        let reps: [DeviceRep]
        let forecasts: [String: StormForecast]
        let procedures: [Procedure]

        static func empty(asOf: Date) -> Seed {
            Seed(asOf: asOf, hospitals: [], reps: [], forecasts: [:], procedures: [])
        }

        /// Absolute closure time preserves the meaning of the relative fixture input.
        func roadClosureAt(hospitalID: String) -> Date? {
            forecasts[hospitalID]?.roadClosureInHours.map { asOf.addingTimeInterval($0 * 3600) }
        }
    }

    /// Invoke explicitly for a fresh sample. The clock is read once and every record ID
    /// is generated once so references remain coherent even with UUID-based generators.
    static func make(clock: () -> Date = Date.init,
                     makeID: (Record) -> String = { $0.rawValue }) -> Seed {
        let asOf = clock()
        let ids = Dictionary(uniqueKeysWithValues: Record.allCases.map { ($0, makeID($0)) })
        // Every enum case was populated above; avoid consulting the generator twice.
        func id(_ record: Record) -> String { ids[record]! }
        let northShore = id(.northShoreSite)
        let lakes = id(.lakesSite)
        let prairie = id(.prairieSite)
        let hospitals = [
            Hospital(id: northShore, name: "North Shore Community Hospital", town: "Grand Marais", latitude: 47.75, longitude: -90.33),
            Hospital(id: lakes, name: "Lakes Regional Medical Center", town: "Bemidji", latitude: 47.47, longitude: -94.88),
            Hospital(id: prairie, name: "Prairie Valley Hospital", town: "Worthington", latitude: 43.62, longitude: -95.60),
        ]
        let reps = [
            DeviceRep(id: id(.anaContact), name: "Ana Lindqvist", homeBase: "Duluth",
                      skills: ["pacemaker", "icd"],
                      driveMinutes: [northShore: 110, lakes: 200, prairie: 390],
                      isAvailable: true, canSupportRemotely: true, statedRole: .technicalRep, travelAsOf: asOf),
            DeviceRep(id: id(.marcusContact), name: "Marcus Bell", homeBase: "Minneapolis",
                      skills: ["pacemaker", "neurostim"],
                      driveMinutes: [northShore: 270, lakes: 225, prairie: 180],
                      isAvailable: true, canSupportRemotely: true, statedRole: .technicalRep, travelAsOf: asOf),
            DeviceRep(id: id(.priyaContact), name: "Priya Raman", homeBase: "St. Cloud",
                      skills: ["icd", "insulin-pump"],
                      driveMinutes: [northShore: 300, lakes: 150, prairie: 210],
                      isAvailable: false, canSupportRemotely: true, statedRole: .technicalRep, travelAsOf: asOf),
        ]
        let forecasts = [
            northShore: StormForecast(summary: "Simulated blizzard warning, 14 in of snow", roadClosureInHours: 1.5, snowfallInches: 14, asOf: asOf),
            lakes: StormForecast(summary: "Simulated light snow", roadClosureInHours: nil, snowfallInches: 2, asOf: asOf),
            prairie: StormForecast(summary: "Simulated ice storm watch", roadClosureInHours: 18, snowfallInches: 1, asOf: asOf),
        ]
        let procedures = [
            FictionalCoordinationTemplate.makeProcedure(id: id(.northShoreCase), name: "Fictional pacemaker case A", hospitalID: northShore,
                scheduledAt: asOf.addingTimeInterval(8 * 3600), durationMinutes: 90),
            // No reviewed ICD coordination content exists. Never reuse pacemaker items.
            Procedure(id: id(.unsupportedCase), name: "Fictional ICD case — recording unavailable", deviceFamily: "icd", hospitalID: prairie,
                scheduledAt: asOf.addingTimeInterval(26 * 3600), durationMinutes: 60, steps: []),
            FictionalCoordinationTemplate.makeProcedure(id: id(.lakesCase), name: "Fictional pacemaker case B", hospitalID: lakes,
                scheduledAt: asOf.addingTimeInterval(30 * 3600), durationMinutes: 90),
        ]
        return Seed(asOf: asOf, hospitals: hospitals, reps: reps, forecasts: forecasts, procedures: procedures)
    }

    // Compatibility for starter consumers. Full blank setup/bootstrap is F07/F25.
    private static let starterSeed = make()
    static var hospitals: [Hospital] { starterSeed.hospitals }
    static var reps: [DeviceRep] { starterSeed.reps }
    static var forecasts: [String: StormForecast] { starterSeed.forecasts }
    static var procedures: [Procedure] { starterSeed.procedures }
    static var pacemakerSteps: [ProcedureStep] { FictionalCoordinationTemplate.steps }
}
