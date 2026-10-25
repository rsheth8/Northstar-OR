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

    func testTimeZoneChoicesListUSZonesFirstAndKeepCurrent() {
        let list = WorkspaceForms.timeZoneChoices(including: "Custom/Zone")
        XCTAssertEqual(list.first, "Custom/Zone")
        let plain = WorkspaceForms.timeZoneChoices()
        XCTAssertEqual(plain.first, "America/New_York")
        XCTAssertTrue(plain.contains("Europe/London"))
        XCTAssertEqual(Set(plain).count, plain.count)
    }
}
