import Foundation

/// Form state and validation for the case form, kept free of SwiftUI so it can be tested.
/// Validation is delegated to `CaseInput.makeProcedure` / `updating`; this type only maps
/// the resulting errors to short, plain copy and to the field they belong to.
struct CaseFormDraft: Equatable {
    enum Field: Hashable { case reference, title, site, schedule, duration, template }

    /// A validation failure: the field it belongs to (nil for the whole form) and plain copy.
    struct Issue: Equatable {
        let field: Field?
        let message: String
    }

    var input: CaseInput

    static let templates = [FictionalCoordinationTemplate.template]

    /// New case draft: a fresh UUID-based id and the supported fictional template pre-selected.
    static func new(in workspace: WorkspaceConfiguration, now: Date = .now,
                    id: String = "case-\(UUID().uuidString.lowercased())") -> CaseFormDraft {
        let template = FictionalCoordinationTemplate.template
        return CaseFormDraft(input: CaseInput(
            id: id, workspaceID: workspace.id, reference: "", title: "",
            siteID: workspace.sites.first?.id ?? "",
            scheduledAt: Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60), durationMinutes: 60,
            deviceFamily: template.deviceFamily, templateReference: template.reference))
    }

    /// Edit draft: keeps the existing id, template and device family.
    static func editing(_ procedure: Procedure, in workspace: WorkspaceConfiguration) -> CaseFormDraft {
        // A legacy case without a pinned template is treated as the supported template
        // when its device family matches; otherwise it stays nil and shows a template message.
        let supported = FictionalCoordinationTemplate.template
        let reference = procedure.templateReference
            ?? (procedure.deviceFamily == supported.deviceFamily ? supported.reference : nil)
        return CaseFormDraft(input: CaseInput(
            id: procedure.id, workspaceID: procedure.workspaceID ?? workspace.id,
            reference: procedure.reference ?? "", title: procedure.name, siteID: procedure.hospitalID,
            scheduledAt: procedure.scheduledAt, durationMinutes: procedure.durationMinutes,
            deviceFamily: procedure.deviceFamily, templateReference: reference))
    }

    /// Returns nil when the input is acceptable to the model, otherwise the first issue.
    func validate(in workspace: WorkspaceConfiguration, existingCases: [Procedure],
                  editing previous: Procedure?) -> Issue? {
        do {
            if let previous, previous.templateReference == nil {
                // Legacy case with no pinned template: validate as a fresh case excluding itself.
                let others = existingCases.filter { !($0.id == previous.id && $0.workspaceID == previous.workspaceID) }
                _ = try input.makeProcedure(in: workspace, existingCases: others, templates: Self.templates)
            } else if let previous {
                _ = try input.updating(previous, in: workspace, existingCases: existingCases,
                                       templates: Self.templates)
            } else {
                _ = try input.makeProcedure(in: workspace, existingCases: existingCases,
                                            templates: Self.templates)
            }
            return nil
        } catch {
            return Self.issue(for: error)
        }
    }

    static func issue(for error: Error) -> Issue {
        guard let error = error as? WorkspaceContractError else {
            if let text = (error as? LocalizedError)?.errorDescription, !text.isEmpty {
                return Issue(field: nil, message: text)
            }
            return Issue(field: nil, message: "The case could not be saved. Your entries are still here.")
        }
        switch error {
        case .required(let name):
            switch name {
            case "case.reference": return Issue(field: .reference, message: "Enter a case reference.")
            case "case.title": return Issue(field: .title, message: "Enter a case title.")
            case "case.siteID": return Issue(field: .site, message: "Choose a site.")
            case "case.deviceFamily": return Issue(field: .template, message: "Choose a device family.")
            default: return Issue(field: nil, message: "Workspace setup is incomplete. Check Workspace settings.")
            }
        case .duplicateCaseReference:
            return Issue(field: .reference, message: "Another case already uses this reference.")
        case .duplicateCaseTitle:
            return Issue(field: .title, message: "Another case already uses this title.")
        case .unknownSite:
            return Issue(field: .site, message: "This site is not in the workspace. Choose another site.")
        case .invalidDuration:
            return Issue(field: .duration, message: "Duration must be between 1 minute and 24 hours.")
        case .invalidSchedule:
            return Issue(field: .schedule, message: "Choose a valid date and time.")
        case .unsupportedTemplate:
            return Issue(field: .template, message: "This device family has no supported template.")
        case .duplicateID, .immutableCaseIdentity, .foreignWorkspace:
            return Issue(field: nil, message: "This case does not match the workspace. Close the form and try again.")
        default:
            return Issue(field: nil, message: "Workspace setup needs attention. Check Workspace settings.")
        }
    }

    /// Changes the site, keeping the entered wall-clock date and time (not the instant).
    /// A time that does not exist in the new zone (DST gap) moves to the next valid time.
    mutating func changeSite(from oldID: String, to newID: String, in workspace: WorkspaceConfiguration) {
        func zone(_ id: String) -> TimeZone? {
            workspace.sites.first { $0.id == id }?.timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
        }
        guard let old = zone(oldID), let new = zone(newID), old != new else { return }
        var oldCal = Calendar(identifier: .gregorian); oldCal.timeZone = old
        var newCal = Calendar(identifier: .gregorian); newCal.timeZone = new
        let c = oldCal.dateComponents([.year, .month, .day, .hour, .minute], from: input.scheduledAt)
        guard let dayStart = newCal.date(from: DateComponents(year: c.year, month: c.month, day: c.day)),
              let resolved = newCal.nextDate(after: dayStart.addingTimeInterval(-1),
                                             matching: DateComponents(hour: c.hour, minute: c.minute),
                                             matchingPolicy: .nextTime) else { return }
        input.scheduledAt = resolved
    }

    /// Short label for durations, e.g. "1 h 30 min".
    static func durationLabel(_ minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(rest) min"
        }
    }
}
