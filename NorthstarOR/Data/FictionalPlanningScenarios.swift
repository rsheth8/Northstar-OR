import Foundation

/// Fictional, simulated hourly weather and road-closure evidence for the optional sample
/// workspace. Not a forecast and not from any weather service. Values are plausible for a
/// Minnesota winter so the demo reads realistically, and every total matches the sample's
/// summary forecast so the matcher, graph and reports agree.
enum FictionalPlanningScenarios {
    static let source = "Northstar fictional weather scenario (simulated, not a forecast)"
    /// Hours before and after the sample's baseline covered by the hourly samples.
    static let firstHour = -1
    static let lastHour = 36

    struct SiteScenario {
        let scenario: String
        let summary: String
        /// Hours after the baseline when the simulated road closes; nil records no closure.
        let closureHour: Double?
        /// Snowfall in inches recorded during the hour starting at each offset; missing hours are zero.
        let snowfall: [Int: Double]
        let temperature: (Int) -> Double
        let wind: (Int) -> Double
    }

    /// North Shore blizzard: heavy synoptic snow with strong wind off Lake Superior.
    /// 14 in total, peaking near 1.8 in/h, sustained wind in the mid-30s mph at the peak.
    static let northShoreBlizzard = SiteScenario(
        scenario: "North Shore blizzard (fictional)",
        summary: "Simulated blizzard warning for the North Shore: 14 in of snow and whiteout gusts. Simulated shoreline highway closure expected.",
        closureHour: 1.5,
        snowfall: [-1: 0.2, 0: 0.5, 1: 1.0, 2: 1.5, 3: 1.8, 4: 1.8, 5: 1.6, 6: 1.4, 7: 1.2, 8: 1.0, 9: 0.8, 10: 0.6, 11: 0.3, 12: 0.3],
        temperature: { hour in hour <= 12 ? 18 - Double(max(hour, 0)) * 0.8 : 6 },
        wind: { hour in
            switch hour {
            case ..<1: 22
            case 1...8: 36
            case 9...14: 26
            default: 14
            }
        })

    /// Bemidji: light snow tomorrow, roads open.
    static let lakesLightSnow = SiteScenario(
        scenario: "Lakes region light snow (fictional)",
        summary: "Simulated light snow near Bemidji: 2 in, roads open.",
        closureHour: nil,
        snowfall: [20: 0.2, 21: 0.3, 22: 0.3, 23: 0.3, 24: 0.3, 25: 0.3, 26: 0.2, 27: 0.1],
        temperature: { hour in 14 + 6 * sin(Double(hour) / 24 * 2 * .pi) },
        wind: { hour in (20...27).contains(hour) ? 12 : 8 })

    /// Worthington: ice storm watch with temperatures near freezing; little snow.
    static let prairieIceStorm = SiteScenario(
        scenario: "Southwest Minnesota ice storm watch (fictional)",
        summary: "Simulated ice storm watch for southwest Minnesota. Simulated road closure possible tomorrow.",
        closureHour: 18,
        snowfall: [16: 0.1, 17: 0.2, 18: 0.3, 19: 0.2, 20: 0.1, 21: 0.1],
        temperature: { hour in hour < 14 ? 36 - Double(max(hour, 0)) * 0.3 : 31 },
        wind: { hour in (14...24).contains(hour) ? 22 : 12 })

    /// Builds revision-0 sample evidence for each site. Revision 0 marks the sample's own
    /// starting scenario; the first edit through the app saves revision 1.
    static func evidence(asOf: Date, northShoreID: String, lakesID: String, prairieID: String) -> [PlanningEvidence] {
        [(northShoreID, northShoreBlizzard), (lakesID, lakesLightSnow), (prairieID, prairieIceStorm)]
            .map { make(siteID: $0.0, scenario: $0.1, asOf: asOf) }
    }

    static func make(siteID: String, scenario: SiteScenario, asOf: Date) -> PlanningEvidence {
        func at(_ hours: Double) -> Date { asOf.addingTimeInterval(hours * 3600) }
        let samples = (firstHour...lastHour).map { hour in
            PlanningEvidence.WeatherSample(timestamp: at(Double(hour)),
                                           snowfallInches: scenario.snowfall[hour] ?? 0,
                                           temperatureFahrenheit: (scenario.temperature(hour) * 10).rounded() / 10,
                                           windMPH: scenario.wind(hour))
        }
        return PlanningEvidence(id: "sample-evidence-\(siteID)", siteID: siteID, revision: 0,
                                source: source, scenario: scenario.scenario,
                                recordedAt: asOf, issuedAt: asOf,
                                validFrom: at(Double(firstHour)), validUntil: at(Double(lastHour)),
                                summary: scenario.summary,
                                closure: scenario.closureHour.map { .at(at($0)) } ?? .noneRecorded,
                                samples: samples)
    }
}
