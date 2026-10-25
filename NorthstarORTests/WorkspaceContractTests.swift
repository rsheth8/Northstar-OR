import XCTest
@testable import NorthstarOR

final class WorkspaceContractTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)
    private var catalog: [CoordinationTemplate] { [FictionalCoordinationTemplate.template] }

    func testIndependentCasesUseConfiguredSiteAndPinnedContentWithoutContacts() throws {
        let workspace = configuration()
        let first = try input().makeProcedure(in: workspace, existingCases: [], templates: catalog)
        var secondInput = input()
        secondInput.id = "case-b"
        secondInput.reference = "B-2"
        secondInput.title = "Another fictional case"
        let second = try secondInput.makeProcedure(in: workspace, existingCases: [first], templates: catalog)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(first.workspaceID, workspace.id)
        XCTAssertEqual(first.hospitalID, workspace.sites[0].id)
        XCTAssertEqual(first.templateReference, catalog[0].reference)
        XCTAssertEqual(first.steps, catalog[0].steps)
        XCTAssertEqual(first.scheduledAt, time)
        XCTAssertTrue(FictionalCoordinationTemplate.supports(first))
        XCTAssertTrue(workspace.contacts.isEmpty)
    }

    func testRenamingConfigurationRetainsAllIdentitiesAndCaseMembership() throws {
        var workspace = configuration(withContact: true)
        let created = try input().makeProcedure(in: workspace, existingCases: [], templates: catalog)
        let old = workspace
        workspace.name = "Renamed fictional workspace"
        workspace.sites[0].name = "Renamed fictional facility"
        workspace.contacts[0].name = "Renamed fictional contact"
        workspace.localParticipant.displayName = "Renamed fictional participant"
        try workspace.validate()
        XCTAssertEqual(workspace.id, old.id)
        XCTAssertEqual(workspace.sites[0].id, old.sites[0].id)
        XCTAssertEqual(workspace.contacts[0].id, old.contacts[0].id)
        XCTAssertEqual(workspace.localParticipant.id, old.localParticipant.id)
        XCTAssertEqual(created.hospitalID, workspace.sites[0].id)
        XCTAssertEqual(created.workspaceID, workspace.id)
    }

    func testWorkspaceRejectsMissingFieldsForeignMembersAndInvalidTimeZone() {
        var workspace = configuration()
        workspace.name = " \n "
        expect(.required("workspace.name")) { try workspace.validate() }
        workspace = configuration()
        workspace.sites[0].workspaceID = "foreign-workspace"
        expect(.foreignWorkspace("site-a")) { try workspace.validate() }
        workspace = configuration()
        workspace.sites[0].timeZoneIdentifier = "invalid/timezone"
        expect(.invalidTimeZone("site-a")) { try workspace.validate() }
        workspace = configuration()
        workspace.sites[0].roomLabels = ["Room A", " room a "]
        expect(.invalidRooms("site-a")) { try workspace.validate() }
        workspace = configuration()
        workspace.sites.append(workspace.sites[0])
        expect(.duplicateID("site-a")) { try workspace.validate() }
    }

    func testStatedTechnicalAndClinicalRolesAreDistinctAndTravelMayBeUnknown() throws {
        var workspace = configuration(withContact: true)
        XCTAssertEqual(workspace.contacts[0].statedRole, .technicalRep)
        XCTAssertNil(workspace.contacts[0].driveMinutes["site-a"])
        XCTAssertNil(workspace.contacts[0].travelAsOf)
        workspace.contacts[0].isAvailable = false
        try workspace.validate()
        workspace.contacts[0].statedRole = .clinicalSpecialist
        try workspace.validate()
        workspace.contacts[0].statedRole = .coordinator
        expect(.invalidContactRole("contact-a")) { try workspace.validate() }
        workspace.contacts[0].statedRole = .technicalRep
        workspace.contacts[0].driveMinutes = ["site-a": 20]
        expect(.invalidTravel("contact-a")) { try workspace.validate() }
        workspace.contacts[0].travelAsOf = time
        try workspace.validate()
        workspace.contacts[0].driveMinutes = ["foreign-site": 20]
        expect(.invalidTravel("contact-a")) { try workspace.validate() }
        workspace.contacts[0].driveMinutes = ["site-a": -1]
        expect(.invalidTravel("contact-a")) { try workspace.validate() }
    }

    func testCaseRejectsBlankTitleReferenceAndForeignOrUnknownSite() {
        let workspace = configuration()
        var candidate = input()
        candidate.title = " \n "
        expect(.required("case.title")) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
        candidate = input()
        candidate.reference = " "
        expect(.required("case.reference")) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
        candidate = input()
        candidate.workspaceID = "other-workspace"
        expect(.foreignWorkspace(candidate.id)) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
        candidate = input()
        candidate.siteID = "missing-site"
        expect(.unknownSite("missing-site")) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
    }

    func testDurationBoundsAreInclusiveAndInvalidDateIsRejected() throws {
        let workspace = configuration()
        for duration in [1, 1440] {
            var candidate = input()
            candidate.durationMinutes = duration
            let created = try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog)
            XCTAssertEqual(created.durationMinutes, duration)
        }
        for duration in [-1, 0, 1441, Int.max] {
            var candidate = input()
            candidate.durationMinutes = duration
            expect(.invalidDuration) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
        }
        var candidate = input()
        candidate.scheduledAt = Date(timeIntervalSince1970: .infinity)
        expect(.invalidSchedule) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
    }

    func testDuplicatesNormalizeWhitespaceAndCaseWithinWorkspace() throws {
        let workspace = configuration()
        let original = try input().makeProcedure(in: workspace, existingCases: [], templates: catalog)
        var candidate = input()
        candidate.id = "case-b"
        candidate.reference = "B-2"
        candidate.title = "  FICTIONAL CASE A \n"
        expect(.duplicateCaseTitle) { try candidate.makeProcedure(in: workspace, existingCases: [original], templates: catalog) }
        candidate.title = "Distinct title"
        candidate.reference = "  a-1 \n"
        expect(.duplicateCaseReference) { try candidate.makeProcedure(in: workspace, existingCases: [original], templates: catalog) }
        var foreign = original
        foreign.workspaceID = "other-workspace"
        XCTAssertNoThrow(try candidate.makeProcedure(in: workspace, existingCases: [foreign], templates: catalog))
    }

    func testMissingUnsupportedOrMismatchedTemplateCannotCreateOrRecord() throws {
        let workspace = configuration()
        for reference in [nil, CoordinationTemplateReference(id: "unknown", version: 1),
                          CoordinationTemplateReference(id: FictionalCoordinationTemplate.id, version: FictionalCoordinationTemplate.version + 1)] {
            var candidate = input()
            candidate.templateReference = reference
            expect(.unsupportedTemplate) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
        }
        var candidate = input()
        candidate.deviceFamily = "icd"
        expect(.unsupportedTemplate) { try candidate.makeProcedure(in: workspace, existingCases: [], templates: catalog) }
        let unavailable = descriptor(availability: .unavailable)
        expect(.unsupportedTemplate) { try input().makeProcedure(in: workspace, existingCases: [], templates: [unavailable]) }
        let empty = descriptor(steps: [])
        expect(.unsupportedTemplate) { try input().makeProcedure(in: workspace, existingCases: [], templates: [empty]) }
        expect(.unsupportedTemplate) { try input().makeProcedure(in: workspace, existingCases: [], templates: catalog + catalog) }
        var created = try input().makeProcedure(in: workspace, existingCases: [], templates: catalog)
        created.templateReference = CoordinationTemplateReference(id: FictionalCoordinationTemplate.id, version: FictionalCoordinationTemplate.version + 1)
        XCTAssertFalse(FictionalCoordinationTemplate.supports(created))
        created.templateReference = nil
        XCTAssertFalse(FictionalCoordinationTemplate.supports(created))
    }

    func testPlanningEditReturnsNewValueAndPreservesPinnedContentAndOldSnapshot() throws {
        let workspace = configuration()
        let old = try input().makeProcedure(in: workspace, existingCases: [], templates: catalog)
        var edit = input()
        edit.title = "Renamed fictional case"
        edit.scheduledAt = time.addingTimeInterval(3600)
        let updated = try edit.updating(old, in: workspace, existingCases: [old], templates: catalog)
        XCTAssertEqual(updated.id, old.id)
        XCTAssertEqual(updated.steps, old.steps)
        XCTAssertEqual(updated.templateReference, old.templateReference)
        XCTAssertNotEqual(updated.scheduledAt, old.scheduledAt)
        XCTAssertEqual(old.name, "Fictional case A")
        edit.templateReference = CoordinationTemplateReference(id: "other", version: 1)
        expect(.unsupportedTemplate) { try edit.updating(old, in: workspace, existingCases: [old], templates: catalog) }
        edit = input()
        edit.id = "replacement-id"
        expect(.immutableCaseIdentity) { try edit.updating(old, in: workspace, existingCases: [old], templates: catalog) }
    }

    func testCodableRoundTripsConfigurationCaseAndCatalog() throws {
        let workspace = configuration(withContact: true)
        let created = try input().makeProcedure(in: workspace, existingCases: [], templates: catalog)
        XCTAssertEqual(try roundTrip(workspace), workspace)
        XCTAssertEqual(try roundTrip(created), created)
        XCTAssertEqual(try roundTrip(catalog[0]), catalog[0])
        try roundTrip(workspace).validate()
        XCTAssertTrue(FictionalCoordinationTemplate.supports(try roundTrip(created)))
    }

    func testUnsupportedConfigurationVersionAndMissingVersionFailDecode() throws {
        let data = try JSONEncoder().encode(configuration())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["configurationVersion"] = 2
        let future = try JSONSerialization.data(withJSONObject: json)
        expect(.unsupportedConfigurationVersion(2)) { try JSONDecoder().decode(WorkspaceConfiguration.self, from: future) }
        json.removeValue(forKey: "configurationVersion")
        let unversioned = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try JSONDecoder().decode(WorkspaceConfiguration.self, from: unversioned))
    }

    func testLegacyDecodeLeavesUnknownFieldsUnpinnedAndUnavailable() throws {
        let original = FictionalCoordinationTemplate.makeProcedure(id: "legacy", name: "Fictional legacy case", hospitalID: "legacy-site",
                                                                 scheduledAt: time, durationMinutes: 60)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        ["workspaceID", "reference", "templateReference"].forEach { json.removeValue(forKey: $0) }
        let legacy = try JSONDecoder().decode(Procedure.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(legacy.workspaceID)
        XCTAssertNil(legacy.reference)
        XCTAssertNil(legacy.templateReference)
        XCTAssertFalse(FictionalCoordinationTemplate.supports(legacy))
        let session = CoPilotSession(procedure: legacy)
        apply(session, .recordConfirmation)
        XCTAssertTrue(session.log.isEmpty)
        var siteJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(configuration().sites[0])) as? [String: Any])
        ["workspaceID", "timeZoneIdentifier", "roomLabels"].forEach { siteJSON.removeValue(forKey: $0) }
        let site = try JSONDecoder().decode(Hospital.self, from: JSONSerialization.data(withJSONObject: siteJSON))
        XCTAssertNil(site.workspaceID)
        XCTAssertNil(site.timeZoneIdentifier)
        let legacyContact = DeviceRep(id: "legacy-contact", name: "Fictional legacy contact", homeBase: "Example", skills: [], driveMinutes: [:], isAvailable: false, canSupportRemotely: false)
        let decodedContact = try roundTrip(legacyContact)
        XCTAssertNil(decodedContact.statedRole)
        XCTAssertNil(decodedContact.travelAsOf)
    }

    func testUnknownTemplateVersionRoundTripsWithoutBecomingSupported() throws {
        var created = try input().makeProcedure(in: configuration(), existingCases: [], templates: catalog)
        created.templateReference = CoordinationTemplateReference(id: FictionalCoordinationTemplate.id, version: 99)
        let decoded = try roundTrip(created)
        XCTAssertEqual(decoded.templateReference?.version, 99)
        XCTAssertFalse(FictionalCoordinationTemplate.supports(decoded))
    }

    func testForecastAbsoluteClosureRequiresKnownAsOf() throws {
        var forecast = StormForecast(summary: "Fictional forecast", roadClosureInHours: 2, snowfallInches: 1)
        XCTAssertNil(forecast.roadClosureAt)
        forecast.asOf = time
        XCTAssertEqual(try roundTrip(forecast).roadClosureAt, time.addingTimeInterval(7200))
    }

    func testOptionalSeedStampsKnownPlanningInputsWithoutInventingWorkspaceMembership() {
        let seed = SampleData.make(clock: { self.time }, makeID: { "new-\($0.rawValue)" })
        XCTAssertTrue(seed.reps.allSatisfy { $0.travelAsOf == time && $0.statedRole == .technicalRep && $0.workspaceID == nil })
        XCTAssertTrue(seed.forecasts.values.allSatisfy { $0.asOf == time })
        for (siteID, forecast) in seed.forecasts {
            XCTAssertEqual(forecast.roadClosureAt, seed.roadClosureAt(hospitalID: siteID))
        }
    }

    private func configuration(withContact: Bool = false) -> WorkspaceConfiguration {
        let site = Hospital(id: "site-a", name: "Fictional facility", town: "Example town", workspaceID: "workspace-a",
                            timeZoneIdentifier: "America/Chicago", roomLabels: ["Room A"])
        let contact = DeviceRep(id: "contact-a", name: "Fictional contact", homeBase: "Example town", skills: ["pacemaker"],
                                driveMinutes: [:], isAvailable: true, canSupportRemotely: true, workspaceID: "workspace-a", statedRole: .technicalRep)
        return WorkspaceConfiguration(id: "workspace-a", name: "Fictional workspace", sites: [site], contacts: withContact ? [contact] : [],
            localParticipant: LocalParticipant(id: "participant-a", workspaceID: "workspace-a", displayName: "Fictional coordinator", statedRole: .coordinator))
    }

    private func input() -> CaseInput {
        CaseInput(id: "case-a", workspaceID: "workspace-a", reference: "A-1", title: " Fictional case A ", siteID: "site-a",
                  scheduledAt: time, durationMinutes: 60, deviceFamily: "pacemaker", templateReference: FictionalCoordinationTemplate.reference)
    }

    private func descriptor(availability: CoordinationTemplate.Availability = .supportedFictional, steps: [ProcedureStep] = FictionalCoordinationTemplate.steps) -> CoordinationTemplate {
        let template = catalog[0]
        return CoordinationTemplate(reference: template.reference, name: template.name, deviceFamily: template.deviceFamily,
                                    applicability: template.applicability, source: template.source, availability: availability, steps: steps)
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }

    private func expect<T>(_ expected: WorkspaceContractError, file: StaticString = #filePath, line: UInt = #line, _ action: () throws -> T) {
        XCTAssertThrowsError(try action(), file: file, line: line) { error in
            XCTAssertEqual(error as? WorkspaceContractError, expected, file: file, line: line)
        }
    }
    private func apply(_ session: CoPilotSession, _ action: SessionCommandAction, target: String? = nil, at time: Date = .now) {
        guard let command = session.makeCommand(action, targetItemID: target, at: time) else { return }
        do { try session.apply(command) } catch { XCTFail("Command rejected: \(error)") }
    }

}
