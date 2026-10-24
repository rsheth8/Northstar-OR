import Foundation

/// Local statements only: none of these roles establishes identity or credentials.
enum ParticipantRole: String, Codable, CaseIterable {
    case coordinator, orTeam, technicalRep, clinicalSpecialist
}

struct LocalParticipant: Identifiable, Hashable, Codable {
    let id: String
    let workspaceID: String
    var displayName: String
    var statedRole: ParticipantRole
}

/// Exact content identity. Unknown IDs/versions can be retained without authorizing recording.
struct CoordinationTemplateReference: Hashable, Codable {
    let id: String
    let version: Int
}

struct CoordinationTemplate: Hashable, Codable {
    enum Availability: String, Codable { case supportedFictional, unavailable }
    let reference: CoordinationTemplateReference
    let name: String
    let deviceFamily: String
    let applicability: String
    let source: String
    let availability: Availability
    let steps: [ProcedureStep]

    var isUsable: Bool {
        availability == .supportedFictional && reference.version > 0 &&
        [reference.id, name, deviceFamily, applicability, source].allSatisfy { !$0.trimmed.isEmpty } &&
        !steps.isEmpty && Set(steps.map(\.id)).count == steps.count &&
        steps.allSatisfy { !$0.id.trimmed.isEmpty && !$0.title.trimmed.isEmpty && !$0.detail.trimmed.isEmpty }
    }

    func supports(_ procedure: Procedure) -> Bool {
        isUsable && procedure.templateReference == reference &&
        procedure.deviceFamily == deviceFamily && procedure.steps == steps
    }
}

/// Field-oriented failures for forms/repositories. Validation does not modify its inputs.
enum WorkspaceContractError: Error, Equatable {
    case required(String)
    case unsupportedConfigurationVersion(Int)
    case duplicateID(String)
    case foreignWorkspace(String)
    case invalidTimeZone(String)
    case invalidRooms(String)
    case invalidCoordinates(String)
    case invalidContactRole(String)
    case invalidTravel(String)
    case unknownSite(String)
    case duplicateCaseTitle
    case duplicateCaseReference
    case invalidDuration
    case invalidSchedule
    case unsupportedTemplate
    case immutableCaseIdentity
}

/// One configured fictional workspace. A blank installation has no configuration yet.
/// This is the configuration contract, not a repository or authenticated account.
struct WorkspaceConfiguration: Identifiable, Hashable, Codable {
    static let supportedVersion = 1
    let id: String
    var name: String
    var sites: [Hospital]
    var contacts: [DeviceRep]
    var localParticipant: LocalParticipant
    let configurationVersion: Int

    init(id: String, name: String, sites: [Hospital], contacts: [DeviceRep],
         localParticipant: LocalParticipant, configurationVersion: Int = supportedVersion) {
        self.id = id
        self.name = name
        self.sites = sites
        self.contacts = contacts
        self.localParticipant = localParticipant
        self.configurationVersion = configurationVersion
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, sites, contacts, localParticipant, configurationVersion
    }

    /// No implicit migration: absent/unknown versions fail before consumers use the data.
    /// Decoding preserves values; callers must validate before accepting configuration.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .configurationVersion)
        guard version == Self.supportedVersion else {
            throw WorkspaceContractError.unsupportedConfigurationVersion(version)
        }
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        sites = try values.decode([Hospital].self, forKey: .sites)
        contacts = try values.decode([DeviceRep].self, forKey: .contacts)
        localParticipant = try values.decode(LocalParticipant.self, forKey: .localParticipant)
        configurationVersion = version
    }

    func validate() throws {
        guard configurationVersion == Self.supportedVersion else {
            throw WorkspaceContractError.unsupportedConfigurationVersion(configurationVersion)
        }
        try require(id, "workspace.id")
        try require(name, "workspace.name")
        try require(localParticipant.id, "participant.id")
        try require(localParticipant.displayName, "participant.displayName")
        guard localParticipant.workspaceID == id else { throw WorkspaceContractError.foreignWorkspace(localParticipant.id) }
        guard !sites.isEmpty else { throw WorkspaceContractError.required("workspace.sites") }
        try uniqueIDs(sites.map(\.id))
        try uniqueIDs(contacts.map(\.id))
        for site in sites {
            try require(site.id, "site.id")
            try require(site.name, "site.name")
            try require(site.town, "site.location")
            guard site.workspaceID == id else { throw WorkspaceContractError.foreignWorkspace(site.id) }
            guard let zone = site.timeZoneIdentifier, TimeZone(identifier: zone) != nil else {
                throw WorkspaceContractError.invalidTimeZone(site.id)
            }
            let rooms = site.roomLabels ?? []
            guard rooms.allSatisfy({ !$0.trimmed.isEmpty }), Set(rooms.map(\.normalized)).count == rooms.count else {
                throw WorkspaceContractError.invalidRooms(site.id)
            }
            if let latitude = site.latitude, !latitude.isFinite || !(-90...90).contains(latitude) {
                throw WorkspaceContractError.invalidCoordinates(site.id)
            }
            if let longitude = site.longitude, !longitude.isFinite || !(-180...180).contains(longitude) {
                throw WorkspaceContractError.invalidCoordinates(site.id)
            }
        }
        let siteIDs = Set(sites.map(\.id))
        for contact in contacts {
            try require(contact.id, "contact.id")
            try require(contact.name, "contact.name")
            guard contact.workspaceID == id else { throw WorkspaceContractError.foreignWorkspace(contact.id) }
            guard contact.statedRole == .technicalRep || contact.statedRole == .clinicalSpecialist else {
                throw WorkspaceContractError.invalidContactRole(contact.id)
            }
            guard contact.skills.allSatisfy({ !$0.trimmed.isEmpty }) else { throw WorkspaceContractError.required("contact.capabilities") }
            guard contact.driveMinutes.allSatisfy({ siteIDs.contains($0.key) && $0.value >= 0 }),
                  contact.driveMinutes.isEmpty || contact.travelAsOf?.timeIntervalSince1970.isFinite == true else {
                throw WorkspaceContractError.invalidTravel(contact.id)
            }
        }
    }
}

/// Mutable form input; successful creation returns the existing Procedure domain type.
struct CaseInput: Hashable, Codable {
    var id: String
    var workspaceID: String
    var reference: String
    var title: String
    var siteID: String
    var scheduledAt: Date
    var durationMinutes: Int
    var deviceFamily: String
    var templateReference: CoordinationTemplateReference?

    /// Logistical duration policy: 1 minute through 24 hours, inclusive.
    static let supportedDurationMinutes = 1...1440

    func makeProcedure(in workspace: WorkspaceConfiguration, existingCases: [Procedure],
                       templates: [CoordinationTemplate]) throws -> Procedure {
        try workspace.validate()
        try require(id, "case.id")
        try require(reference, "case.reference")
        try require(title, "case.title")
        try require(siteID, "case.siteID")
        try require(deviceFamily, "case.deviceFamily")
        guard workspaceID == workspace.id else { throw WorkspaceContractError.foreignWorkspace(id) }
        guard workspace.sites.contains(where: { $0.id == siteID && $0.workspaceID == workspace.id }) else {
            throw WorkspaceContractError.unknownSite(siteID)
        }
        guard Self.supportedDurationMinutes.contains(durationMinutes) else { throw WorkspaceContractError.invalidDuration }
        guard scheduledAt.timeIntervalSince1970.isFinite else { throw WorkspaceContractError.invalidSchedule }
        let existing = existingCases.filter { $0.workspaceID == workspace.id }
        guard !existing.contains(where: { $0.id == id }) else { throw WorkspaceContractError.duplicateID(id) }
        guard !existing.contains(where: { $0.name.normalized == title.normalized }) else { throw WorkspaceContractError.duplicateCaseTitle }
        guard !existing.contains(where: { $0.reference?.normalized == reference.normalized }) else {
            throw WorkspaceContractError.duplicateCaseReference
        }
        let matches = templates.filter { $0.reference == templateReference }
        guard matches.count == 1, let template = matches.first, template.isUsable,
              template.deviceFamily == deviceFamily.trimmed else { throw WorkspaceContractError.unsupportedTemplate }
        return Procedure(id: id, name: title.trimmed, deviceFamily: deviceFamily.trimmed,
                         hospitalID: siteID, scheduledAt: scheduledAt, durationMinutes: durationMinutes,
                         steps: template.steps, workspaceID: workspace.id, reference: reference.trimmed,
                         templateReference: template.reference)
    }

    /// A planning edit returns a new value with stable identity and pinned content.
    /// A session's historical case snapshot is never modified by this function.
    func updating(_ previous: Procedure, in workspace: WorkspaceConfiguration,
                  existingCases: [Procedure], templates: [CoordinationTemplate]) throws -> Procedure {
        guard id == previous.id, workspaceID == previous.workspaceID else { throw WorkspaceContractError.immutableCaseIdentity }
        guard templateReference == previous.templateReference, deviceFamily.trimmed == previous.deviceFamily,
              templates.contains(where: { $0.supports(previous) }) else { throw WorkspaceContractError.unsupportedTemplate }
        return try makeProcedure(in: workspace,
                                 existingCases: existingCases.filter { !($0.id == previous.id && $0.workspaceID == previous.workspaceID) },
                                 templates: templates)
    }
}

private func require(_ value: String, _ field: String) throws {
    guard !value.trimmed.isEmpty else { throw WorkspaceContractError.required(field) }
}

private func uniqueIDs(_ values: [String]) throws {
    var seen = Set<String>()
    for id in values where !seen.insert(id).inserted { throw WorkspaceContractError.duplicateID(id) }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var normalized: String { trimmed.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX")) }
}
