import Foundation

/// Hardcoded, fictional demo data. Every name and number here is made up.
enum SampleData {
    static let hospitals: [Hospital] = [
        Hospital(id: "grand-marais", name: "North Shore Community Hospital", town: "Grand Marais", latitude: 47.75, longitude: -90.33),
        Hospital(id: "bemidji", name: "Lakes Regional Medical Center", town: "Bemidji", latitude: 47.47, longitude: -94.88),
        Hospital(id: "worthington", name: "Prairie Valley Hospital", town: "Worthington", latitude: 43.62, longitude: -95.60),
    ]

    static let reps: [DeviceRep] = [
        DeviceRep(id: "rep-ana", name: "Ana Lindqvist", homeBase: "Duluth",
                  skills: ["pacemaker", "icd"],
                  driveMinutes: ["grand-marais": 110, "bemidji": 200, "worthington": 390],
                  isAvailable: true, canSupportRemotely: true),
        DeviceRep(id: "rep-marcus", name: "Marcus Bell", homeBase: "Minneapolis",
                  skills: ["pacemaker", "neurostim"],
                  driveMinutes: ["grand-marais": 270, "bemidji": 225, "worthington": 180],
                  isAvailable: true, canSupportRemotely: true),
        DeviceRep(id: "rep-priya", name: "Priya Raman", homeBase: "St. Cloud",
                  skills: ["icd", "insulin-pump"],
                  driveMinutes: ["grand-marais": 300, "bemidji": 150, "worthington": 210],
                  isAvailable: false, canSupportRemotely: true),
    ]

    static let forecasts: [String: StormForecast] = [
        "grand-marais": StormForecast(summary: "Blizzard warning, 14 in of snow", roadClosureInHours: 1.5, snowfallInches: 14),
        "bemidji": StormForecast(summary: "Light snow", roadClosureInHours: nil, snowfallInches: 2),
        "worthington": StormForecast(summary: "Ice storm watch", roadClosureInHours: 18, snowfallInches: 1),
    ]

    static let pacemakerSteps: [ProcedureStep] = [
        ProcedureStep(id: "timeout", title: "Surgical time-out", detail: "Confirm patient, procedure, and site with the whole team.", isRequired: true, normallyCoveredByRep: false),
        ProcedureStep(id: "device-check", title: "Verify device and leads", detail: "Match model and serial numbers to the implant record.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "programmer", title: "Connect programmer", detail: "Pair the programmer and confirm telemetry.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "lead-placement", title: "Lead placement", detail: "Team places leads per standard technique.", isRequired: true, normallyCoveredByRep: false),
        ProcedureStep(id: "thresholds", title: "Measure thresholds", detail: "Record sensing and pacing thresholds.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "connect-device", title: "Connect leads to device", detail: "Confirm secure connection and tighten set screws.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "final-interrogation", title: "Final interrogation", detail: "Interrogate the device and save the report.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "closure", title: "Closure and count", detail: "Close the pocket and complete the instrument count.", isRequired: true, normallyCoveredByRep: false),
    ]

    static let procedures: [Procedure] = {
        let now = Date()
        return [
            Procedure(id: "proc-1", name: "Dual-chamber pacemaker implant", deviceFamily: "pacemaker",
                      hospitalID: "grand-marais", scheduledAt: now.addingTimeInterval(8 * 3600), durationMinutes: 90, steps: pacemakerSteps),
            Procedure(id: "proc-2", name: "ICD generator change", deviceFamily: "icd",
                      hospitalID: "worthington", scheduledAt: now.addingTimeInterval(26 * 3600), durationMinutes: 60, steps: pacemakerSteps),
            Procedure(id: "proc-3", name: "Pacemaker implant", deviceFamily: "pacemaker",
                      hospitalID: "bemidji", scheduledAt: now.addingTimeInterval(30 * 3600), durationMinutes: 90, steps: pacemakerSteps),
        ]
    }()
}
