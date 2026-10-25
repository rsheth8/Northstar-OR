import XCTest
@testable import NorthstarOR

final class WorkspaceFormsTests: XCTestCase {
    private func setup() -> WorkspaceSetupDraft {
        var d = WorkspaceSetupDraft()
        d.workspaceName = "  Fictional team "
        d.site = SiteDraft(id: "x", name: "Fictional General", town: "Exampleville", timeZoneIdentifier: "America/Chicago")
        d.participantName = "Sam Sample"
        d.role = .orTeam
        return d
    }

    func testSetupBuildsValidWorkspaceWithConsistentMembership() throws {
        let config = try setup().build()
        XCTAssertEqual(config.name, "Fictional team")
        XCTAssertEqual(config.sites.count, 1)
        XCTAssertEqual(config.sites[0].workspaceID, config.id)
        XCTAssertEqual(config.localParticipant.workspaceID, config.id)
        XCTAssertEqual(config.localParticipant.statedRole, .orTeam)
        XCTAssertTrue(config.contacts.isEmpty)
        XCTAssertNoThrow(try config.validate())
    }

    func testSetupFailuresSurfaceCalmMessages() {
        var d = setup(); d.workspaceName = " "
        XCTAssertThrowsError(try d.build()) {
            XCTAssertEqual(WorkspaceForms.message(for: $0), "Workspace name is required.")
        }
        d = setup(); d.site.town = ""
        XCTAssertThrowsError(try d.build()) {
            XCTAssertEqual(WorkspaceForms.message(for: $0), "Site town is required.")
        }
        d = setup(); d.site.timeZoneIdentifier = "Nowhere/Land"
        XCTAssertThrowsError(try d.build()) {
            XCTAssertEqual(WorkspaceForms.message(for: $0), "Choose a valid time zone for each site.")
        }
    }

    func testSettingsEditKeepsContactsAndPrunesRemovedSiteTravel() throws {
        let base = WorkspacePreviewData.workspace
        var draft = WorkspaceSettingsDraft(base)
        draft.name = "Renamed"
        draft.sites.append(SiteDraft(id: "site-b", name: "Second", town: "Town", timeZoneIdentifier: "America/New_York"))
        let two = try draft.applying(to: base)
        XCTAssertEqual(two.sites.map(\.id), ["site-a", "site-b"])
        XCTAssertEqual(two.contacts, base.contacts)
        draft.sites.removeAll { $0.id == "site-a" }
        let one = try draft.applying(to: two)
        XCTAssertTrue(one.contacts[0].driveMinutes.isEmpty)
    }

    func testSettingsRejectsEmptySiteList() {
        var draft = WorkspaceSettingsDraft(WorkspacePreviewData.workspace)
        draft.sites = []
        XCTAssertThrowsError(try draft.applying(to: WorkspacePreviewData.workspace))
    }

    func testContactAddAndEditMapping() throws {
        let base = WorkspacePreviewData.workspace
        var draft = ContactDraft(id: "contact-new")
        draft.name = " Riley Rep "; draft.homeBase = "Town"
        draft.canSupportRemotely = true
        draft.driveText = ["site-a": "40"]
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let added = try draft.applying(to: base, now: now)
        let rep = try XCTUnwrap(added.contacts.first { $0.id == "contact-new" })
        XCTAssertEqual(rep.name, "Riley Rep")
        XCTAssertEqual(rep.skills, [FictionalCoordinationTemplate.deviceFamily])
        XCTAssertEqual(rep.driveMinutes, ["site-a": 40])
        XCTAssertEqual(rep.travelAsOf, now)
        XCTAssertEqual(rep.workspaceID, base.id)

        var edit = ContactDraft(rep)
        edit.supportsTemplateFamily = false
        edit.isAvailable = false
        let edited = try edit.applying(to: added, now: now)
        XCTAssertEqual(edited.contacts.count, 2)
        XCTAssertTrue(edited.contacts.first { $0.id == "contact-new" }!.skills.isEmpty)
        XCTAssertFalse(edited.contacts.first { $0.id == "contact-new" }!.isAvailable)
    }

    func testContactInvalidInputsAreRejectedWithMessages() {
        let base = WorkspacePreviewData.workspace
        var draft = ContactDraft(id: "c2")
        draft.name = "Pat"; draft.homeBase = "Town"
        draft.driveText = ["site-a": "abc"]
        XCTAssertThrowsError(try draft.applying(to: base)) {
            XCTAssertEqual(WorkspaceForms.message(for: $0),
                           "Drive minutes must be whole numbers of zero or more for sites in this workspace.")
        }
        draft.driveText = ["site-a": "-5"]
        XCTAssertThrowsError(try draft.applying(to: base))
        draft.driveText = [:]; draft.name = ""
        XCTAssertThrowsError(try draft.applying(to: base)) {
            XCTAssertEqual(WorkspaceForms.message(for: $0), "Contact name is required.")
        }
        draft.name = "Pat"; draft.role = .technicalRep; draft.homeBase = " "
        XCTAssertThrowsError(try draft.applying(to: base))
    }

    func testSiteCoordinatesParseRetainAndClearThroughNormalForms() throws {
        var setupDraft = setup()
        setupDraft.site.latitudeText = " 46.5 "
        setupDraft.site.longitudeText = " -91.25 "
        let workspace = try setupDraft.build()
        XCTAssertEqual(workspace.sites[0].latitude, 46.5)
        XCTAssertEqual(workspace.sites[0].longitude, -91.25)
        var settings = WorkspaceSettingsDraft(workspace)
        XCTAssertEqual(try settings.applying(to: workspace).sites, workspace.sites)
        settings.sites[0].latitudeText = ""
        settings.sites[0].longitudeText = " "
        let cleared = try settings.applying(to: workspace)
        XCTAssertNil(cleared.sites[0].latitude)
        XCTAssertNil(cleared.sites[0].longitude)
    }

    func testSiteCoordinatesRejectPartialMalformedNonfiniteAndOutOfRangePairs() {
        for (latitude, longitude) in [("45", ""), ("", "-90"), ("north", "-90"),
                                       ("nan", "0"), ("0", "inf"), ("91", "0"), ("0", "-181")] {
            var draft = setup()
            draft.site.latitudeText = latitude
            draft.site.longitudeText = longitude
            XCTAssertThrowsError(try draft.build()) { error in
                XCTAssertEqual(error as? WorkspaceContractError, .invalidCoordinates)
            }
        }
    }

    func testTimeZoneChoicesListUSZonesFirstAndKeepCurrent() {
        let list = WorkspaceForms.timeZoneChoices(including: "Custom/Zone")
        XCTAssertEqual(list.first, "Custom/Zone")
        let plain = WorkspaceForms.timeZoneChoices()
        XCTAssertEqual(plain.first, "America/New_York")
        XCTAssertTrue(plain.contains("Europe/London"))
        XCTAssertEqual(Set(plain).count, plain.count)
    }
}
