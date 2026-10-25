import Foundation

/// Form state and form-to-model mapping for workspace setup, settings and contacts.
/// Pure value logic: nothing here touches AppModel, persistence or the network.
enum WorkspaceForms {
    static func newID(_ prefix: String) -> String { "\(prefix)-\(UUID().uuidString.lowercased())" }

    /// US zones first (workspace is a US exercise), then every other identifier.
    static let preferredTimeZones = [
        "America/New_York", "America/Chicago", "America/Denver", "America/Phoenix",
        "America/Los_Angeles", "America/Anchorage", "Pacific/Honolulu",
    ]

    static func timeZoneChoices(including current: String? = nil) -> [String] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        let preferred = preferredTimeZones.filter { all.contains($0) }
        var result = preferred + all.filter { !preferred.contains($0) }
        if let current, !current.isEmpty, !result.contains(current) { result.insert(current, at: 0) }
        return result
    }

    static var defaultTimeZone: String {
        let local = TimeZone.current.identifier
        return TimeZone(identifier: local) != nil ? local : "America/Chicago"
    }

    static let participantRoles: [ParticipantRole] = ParticipantRole.allCases
    static let contactRoles: [ParticipantRole] = [.technicalRep, .clinicalSpecialist]

    static func label(for role: ParticipantRole) -> String {
        switch role {
        case .coordinator: return "Coordinator"
        case .orTeam: return "OR team"
        case .technicalRep: return "Technical rep"
        case .clinicalSpecialist: return "Clinical specialist"
        }
    }

    /// Short, calm, field-oriented text for a failed save. Never blames the person.
    static func message(for error: Error) -> String {
        guard let error = error as? WorkspaceContractError else { return error.localizedDescription }
        switch error {
        case .required(let field): return "\(fieldName(field)) is required."
        case .unsupportedConfigurationVersion: return "This workspace configuration version is not supported."
        case .duplicateID: return "Two entries share the same identifier. Remove one and try again."
        case .foreignWorkspace: return "An entry belongs to a different workspace."
        case .invalidTimeZone: return "Choose a valid time zone for each site."
        case .invalidRooms: return "Room labels must be unique and not blank."
        case .invalidCoordinates: return "Enter both latitude (−90 to 90) and longitude (−180 to 180), or leave both blank. Use decimal degrees."
        case .invalidContactRole: return "Contacts must be a technical rep or a clinical specialist."
        case .invalidTravel: return "Drive minutes must be whole numbers of zero or more for sites in this workspace."
        case .unknownSite: return "That site is not part of this workspace."
        case .duplicateCaseTitle, .duplicateCaseReference, .invalidDuration, .invalidSchedule,
             .unsupportedTemplate, .immutableCaseIdentity:
            return "The workspace could not be saved."
        }
    }

    private static func fieldName(_ field: String) -> String {
        switch field {
        case "workspace.name": return "Workspace name"
        case "workspace.sites": return "At least one site"
        case "site.name": return "Site name"
        case "site.location": return "Site town"
        case "participant.displayName": return "Your name"
        case "contact.name": return "Contact name"
        case "contact.capabilities": return "Each skill"
        case "contact.homeBase": return "Home base"
        default: return "A required field"
        }
    }

    static func trimmed(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines) }
}

struct SiteDraft: Identifiable, Hashable {
    var id: String
    var name: String
    var town: String
    var timeZoneIdentifier: String
    var latitudeText = ""
    var longitudeText = ""

    init(id: String = WorkspaceForms.newID("site"), name: String = "", town: String = "",
         timeZoneIdentifier: String = WorkspaceForms.defaultTimeZone) {
        self.id = id; self.name = name; self.town = town; self.timeZoneIdentifier = timeZoneIdentifier
    }

    init(_ site: Hospital) {
        self.init(id: site.id, name: site.name, town: site.town,
                  timeZoneIdentifier: site.timeZoneIdentifier ?? WorkspaceForms.defaultTimeZone)
        latitudeText = site.latitude.map { String($0) } ?? ""
        longitudeText = site.longitude.map { String($0) } ?? ""
    }

    /// Keeps fields the form does not edit (such as rooms) from the previous value.
    func hospital(workspaceID: String, previous: Hospital?) throws -> Hospital {
        var site = previous ?? Hospital(id: id, name: "", town: "")
        site.name = WorkspaceForms.trimmed(name)
        site.town = WorkspaceForms.trimmed(town)
        site.workspaceID = workspaceID
        site.timeZoneIdentifier = timeZoneIdentifier
        let latitude = WorkspaceForms.trimmed(latitudeText)
        let longitude = WorkspaceForms.trimmed(longitudeText)
        if latitude.isEmpty && longitude.isEmpty {
            site.latitude = nil
            site.longitude = nil
        } else {
            guard let lat = Double(latitude), let lon = Double(longitude),
                  lat.isFinite, lon.isFinite, (-90...90).contains(lat), (-180...180).contains(lon) else {
                throw WorkspaceContractError.invalidCoordinates
            }
            site.latitude = lat
            site.longitude = lon
        }
        return site
    }
}

/// First-run setup: one site and the local participant.
struct WorkspaceSetupDraft: Equatable {
    var workspaceName = ""
    var site = SiteDraft(id: "site-primary")
    var participantName = ""
    var role: ParticipantRole = .coordinator

    func build(newID: (String) -> String = WorkspaceForms.newID) throws -> WorkspaceConfiguration {
        let workspaceID = newID("workspace")
        var site = site
        site.id = newID("site")
        let config = WorkspaceConfiguration(
            id: workspaceID,
            name: WorkspaceForms.trimmed(workspaceName),
            sites: [try site.hospital(workspaceID: workspaceID, previous: nil)],
            contacts: [],
            localParticipant: LocalParticipant(id: newID("participant"), workspaceID: workspaceID,
                                               displayName: WorkspaceForms.trimmed(participantName),
                                               statedRole: role))
        try config.validate()
        return config
    }
}


struct WorkspaceSettingsDraft: Equatable {
    var name: String
    var sites: [SiteDraft]
    var participantName: String
    var role: ParticipantRole

    init(_ workspace: WorkspaceConfiguration) {
        name = workspace.name
        sites = workspace.sites.map(SiteDraft.init)
        participantName = workspace.localParticipant.displayName
        role = workspace.localParticipant.statedRole
    }

    /// Returns the edited, validated workspace. Contacts keep their drive times only for
    /// sites that still exist.
    func applying(to workspace: WorkspaceConfiguration) throws -> WorkspaceConfiguration {
        var result = workspace
        result.name = WorkspaceForms.trimmed(name)
        let previous = Dictionary(uniqueKeysWithValues: workspace.sites.map { ($0.id, $0) })
        result.sites = try sites.map { try $0.hospital(workspaceID: workspace.id, previous: previous[$0.id]) }
        let kept = Set(result.sites.map(\.id))
        result.contacts = workspace.contacts.map { contact in
            var c = contact
            c.driveMinutes = contact.driveMinutes.filter { kept.contains($0.key) }
            return c
        }
        result.localParticipant.displayName = WorkspaceForms.trimmed(participantName)
        result.localParticipant.statedRole = role
        try result.validate()
        return result
    }
}

struct ContactDraft: Equatable {
    var id: String
    var name = ""
    var homeBase = ""
    var role: ParticipantRole = .technicalRep
    var supportsTemplateFamily = true
    /// Skills the form does not edit are preserved.
    var otherSkills: Set<String> = []
    var isAvailable = true
    var canSupportRemotely = false
    /// Drive minutes as typed, keyed by site ID. Blank means no figure.
    var driveText: [String: String] = [:]

    static var family: String { FictionalCoordinationTemplate.deviceFamily }

    init(id: String = WorkspaceForms.newID("contact")) { self.id = id }

    init(_ rep: DeviceRep) {
        id = rep.id
        name = rep.name
        homeBase = rep.homeBase
        role = rep.statedRole ?? .technicalRep
        supportsTemplateFamily = rep.skills.contains(Self.family)
        otherSkills = rep.skills.subtracting([Self.family])
        isAvailable = rep.isAvailable
        canSupportRemotely = rep.canSupportRemotely
        driveText = rep.driveMinutes.mapValues(String.init)
    }

    func build(workspaceID: String, siteIDs: [String], previous: DeviceRep? = nil,
               now: Date = Date()) throws -> DeviceRep {
        var minutes: [String: Int] = [:]
        for siteID in siteIDs {
            let text = WorkspaceForms.trimmed(driveText[siteID] ?? "")
            if text.isEmpty { continue }
            guard let value = Int(text), value >= 0 else { throw WorkspaceContractError.invalidTravel(id) }
            minutes[siteID] = value
        }
        var skills = otherSkills
        if supportsTemplateFamily { skills.insert(Self.family) }
        var rep = previous ?? DeviceRep(id: id, name: "", homeBase: "", skills: [], driveMinutes: [:],
                                        isAvailable: true, canSupportRemotely: false)
        rep.name = WorkspaceForms.trimmed(name)
        rep.homeBase = WorkspaceForms.trimmed(homeBase)
        rep.skills = skills
        rep.driveMinutes = minutes
        rep.isAvailable = isAvailable
        rep.canSupportRemotely = canSupportRemotely
        rep.workspaceID = workspaceID
        rep.statedRole = role
        if minutes != previous?.driveMinutes || rep.travelAsOf == nil {
            rep.travelAsOf = minutes.isEmpty ? nil : now
        }
        return rep
    }

    /// Adds or replaces the contact and validates the whole workspace.
    func applying(to workspace: WorkspaceConfiguration, now: Date = Date()) throws -> WorkspaceConfiguration {
        guard !WorkspaceForms.trimmed(homeBase).isEmpty else { throw WorkspaceContractError.required("contact.homeBase") }
        var result = workspace
        let previous = workspace.contacts.first { $0.id == id }
        let rep = try build(workspaceID: workspace.id, siteIDs: workspace.sites.map(\.id), previous: previous, now: now)
        if let index = result.contacts.firstIndex(where: { $0.id == id }) {
            result.contacts[index] = rep
        } else {
            result.contacts.append(rep)
        }
        try result.validate()
        return result
    }
}
